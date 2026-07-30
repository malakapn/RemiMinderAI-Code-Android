"""Hydra S2S live session proxy for RemiVox (API key stays server-side)."""

from __future__ import annotations

import asyncio
import base64
import json
import logging
import os
from typing import Any, Optional

import websockets
from fastapi import WebSocket, WebSocketDisconnect

from services.db_service import get_user_summaries, get_user_uuid
from services.reminder_service import list_patient_reminders
from services.remivox_intents import (
    build_hydra_instructions,
    execute_hydra_tool,
    hydra_tool_schemas,
)
from services.remivox_languages import normalize_language_code
from services.subscription_service import PLAN_PREMIUM, enforce_remivox_access, increment_remivox_interaction

logger = logging.getLogger(__name__)

HYDRA_WS_URL = os.getenv(
    "SMALLESTAI_HYDRA_WS_URL",
    "wss://api.smallest.ai/waves/v1/s2s?model=hydra",
)
HYDRA_VOICE = os.getenv("SMALLESTAI_HYDRA_VOICE", "wren")


def _hydra_url() -> Optional[str]:
    api_key = os.getenv("SMALLESTAI_API_KEY", "").strip()
    if not api_key:
        return None
    base = HYDRA_WS_URL
    sep = "&" if "?" in base else "?"
    if "api_key=" in base:
        return base
    return f"{base}{sep}api_key={api_key}"


async def run_hydra_live_proxy(
    client_ws: WebSocket,
    *,
    firebase_uid: str,
    mode: str = "translate",
    source_language: str = "en",
    target_language: str = "bn",
    timezone_name: str = "UTC",
) -> None:
    """
    Authenticated client <-> Hydra proxy.

    Client messages (JSON):
      - {"type":"input_audio_buffer.append","audio":"<base64 pcm16 16kHz mono>"}
      - {"type":"client.end"}
    Server forwards Hydra events and executes tools server-side.
    """
    hydra_url = _hydra_url()
    if not hydra_url:
        await client_ws.send_json(
            {
                "type": "error",
                "error": {"message": "Hydra is not configured (missing SMALLESTAI_API_KEY)."},
            }
        )
        await client_ws.close(code=1013)
        return

    status = await enforce_remivox_access(firebase_uid)
    user_uuid = await get_user_uuid(firebase_uid)
    src = normalize_language_code(source_language)
    tgt = normalize_language_code(target_language, default="bn" if mode == "translate" else "en")
    instructions = build_hydra_instructions(
        source_language=src,
        target_language=tgt,
        mode=mode if mode in {"translate", "assistant"} else "translate",
    )

    await client_ws.send_json(
        {
            "type": "remivox.ready",
            "mode": mode,
            "source_language": src,
            "target_language": tgt,
            "disclaimer": (
                "Live translation and voice actions are assistive only. "
                "Not a medical interpreter or medical advice."
            ),
        }
    )

    args_buf: dict[str, str] = {}
    pending_create: Optional[asyncio.Task] = None

    try:
        async with websockets.connect(hydra_url, max_size=8 * 1024 * 1024) as hydra_ws:
            configured = asyncio.Event()

            async def refresh_context() -> tuple[dict, list]:
                reminders = await list_patient_reminders(user_uuid)
                summaries = await get_user_summaries(user_uuid, firebase_uid=firebase_uid)
                return reminders, summaries

            async def schedule_response_create() -> None:
                nonlocal pending_create

                async def _send() -> None:
                    await asyncio.sleep(0.2)
                    await hydra_ws.send(json.dumps({"type": "response.create"}))

                if pending_create and not pending_create.done():
                    pending_create.cancel()
                pending_create = asyncio.create_task(_send())

            async def handle_tool(name: str, call_id: str, raw_args: str) -> None:
                try:
                    arguments = json.loads(raw_args or "{}")
                except json.JSONDecodeError:
                    arguments = {}
                reminders, summaries = await refresh_context()
                result = await execute_hydra_tool(
                    name=name,
                    arguments=arguments if isinstance(arguments, dict) else {},
                    user_uuid=user_uuid,
                    reminders=reminders,
                    summaries=summaries,
                    timezone_name=timezone_name,
                )
                await hydra_ws.send(
                    json.dumps(
                        {
                            "type": "conversation.item.create",
                            "item": {
                                "type": "function_call_output",
                                "call_id": call_id,
                                "output": result,
                            },
                        }
                    )
                )
                await schedule_response_create()
                await client_ws.send_json(
                    {
                        "type": "remivox.tool_result",
                        "name": name,
                        "output": result,
                    }
                )

            async def hydra_reader() -> None:
                async for raw in hydra_ws:
                    if isinstance(raw, bytes):
                        continue
                    try:
                        evt = json.loads(raw)
                    except json.JSONDecodeError:
                        continue
                    etype = evt.get("type")
                    if etype == "session.created":
                        await hydra_ws.send(
                            json.dumps(
                                {
                                    "type": "session.configure",
                                    "session": {
                                        "instructions": instructions,
                                        "voice": HYDRA_VOICE,
                                        "tools": hydra_tool_schemas(),
                                        "generate_initial_response": True,
                                    },
                                }
                            )
                        )
                    elif etype == "session.configured":
                        configured.set()
                        await client_ws.send_json({"type": "session.configured", "session": evt.get("session")})
                    elif etype == "response.function_call_arguments.delta":
                        call_id = str(evt.get("call_id") or "")
                        args_buf[call_id] = args_buf.get(call_id, "") + str(evt.get("delta") or "")
                    elif etype == "response.function_call_arguments.done":
                        call_id = str(evt.get("call_id") or "")
                        name = str(evt.get("name") or "")
                        raw_args = str(evt.get("arguments") or args_buf.pop(call_id, "{}"))
                        await handle_tool(name, call_id, raw_args)
                    elif etype == "error":
                        await client_ws.send_json(evt)
                    else:
                        # Forward audio + transcripts to the app.
                        await client_ws.send_json(evt)

            reader_task = asyncio.create_task(hydra_reader())
            await configured.wait()

            if status.get("plan") != PLAN_PREMIUM:
                await increment_remivox_interaction(firebase_uid)

            try:
                while True:
                    message = await client_ws.receive()
                    if message.get("type") == "websocket.disconnect":
                        break
                    raw_text = message.get("text")
                    if raw_text is None and message.get("bytes") is not None:
                        # Raw PCM bytes from client — wrap as Hydra append frames.
                        pcm = message["bytes"]
                        await hydra_ws.send(
                            json.dumps(
                                {
                                    "type": "input_audio_buffer.append",
                                    "audio": base64.b64encode(pcm).decode("ascii"),
                                }
                            )
                        )
                        continue
                    if not raw_text:
                        continue
                    try:
                        payload: dict[str, Any] = json.loads(raw_text)
                    except json.JSONDecodeError:
                        continue
                    ptype = payload.get("type")
                    if ptype == "client.end":
                        break
                    if ptype == "input_audio_buffer.append":
                        await hydra_ws.send(json.dumps(payload))
                    elif ptype == "response.cancel":
                        await hydra_ws.send(json.dumps({"type": "response.cancel"}))
            except WebSocketDisconnect:
                logger.info("RemiVox live client disconnected uid=%s", firebase_uid)
            finally:
                reader_task.cancel()
                if pending_create and not pending_create.done():
                    pending_create.cancel()
    except Exception as exc:
        logger.warning("Hydra live proxy failed: %s", exc)
        try:
            await client_ws.send_json(
                {"type": "error", "error": {"message": "Live Vox session failed. Please try again."}}
            )
        except Exception:
            pass

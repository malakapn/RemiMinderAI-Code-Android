"""
RemiVox v2 care-turn pipeline (Stage C).

Voice Layer (Pulse/Lightning) stays in route/remivox.py + remivox.voice.
This pipeline owns: Intent Router → Action Executor → Response Builder (+ state).

Hydra is NOT used here for care actions.
"""

from __future__ import annotations

from typing import Any, Optional

from services.remivox.actions.executor import execute_intent
from services.remivox.intents.router import route_intent
from services.remivox.observability import log_interaction
from services.remivox.response.builder import build_response
from services.remivox.state.conversation import (
    clear_state,
    get_state,
    upsert_pending,
)


async def run_care_turn(
    *,
    user_uuid: str,
    text: str,
    language: str = "en",
    detected_language: Optional[str] = None,
    reminders: dict,
    summaries: list[dict],
    timezone_name: str = "UTC",
    session_id: Optional[str] = None,
    transcript: Optional[str] = None,
) -> dict[str, Any]:
    """
    Deterministic care workflow for one user turn (text already normalized).

    Returns dict compatible with RemiVoxBriefingResponse fields plus intent metadata.
    """
    sid = (session_id or "default").strip() or "default"
    lang = language or "en"
    detected = detected_language or lang

    prior = get_state(user_uuid, sid)
    pending_intent = prior.pending_intent if prior else None
    pending_entities = prior.pending_entities if prior else None

    intent_result = route_intent(
        text=text,
        language=lang,
        pending_intent=pending_intent,
        pending_entities=pending_entities,
    )

    action_result = await execute_intent(
        intent_result=intent_result,
        user_uuid=user_uuid,
        reminders=reminders,
        summaries=summaries,
        timezone_name=timezone_name or "UTC",
    )

    if action_result.clear_pending:
        clear_state(user_uuid, sid)
    elif action_result.pending_intent:
        upsert_pending(
            user_id=user_uuid,
            session_id=sid,
            language=lang,
            detected_language=detected,
            pending_intent=action_result.pending_intent,
            pending_entities=action_result.pending_entities,
            missing_slots=action_result.missing_slots,
        )
    elif intent_result.intent.value == "CLARIFY":
        upsert_pending(
            user_id=user_uuid,
            session_id=sid,
            language=lang,
            detected_language=detected,
            pending_intent=str(
                (intent_result.entities or {}).get("pending_intent") or ""
            )
            or None,
            pending_entities=dict(
                (intent_result.entities or {}).get("pending_entities") or {}
            ),
            missing_slots=list(intent_result.missing_slots or []),
        )

    built = build_response(
        intent_result=intent_result,
        action_result=action_result,
        reply_language=lang,
    )

    log_interaction(
        user_id=user_uuid,
        detected_language=detected,
        transcript=transcript or text,
        intent=intent_result.intent.value,
        entities=intent_result.entities,
        action=action_result.action,
        success=action_result.success,
        response_language=lang,
        session_id=sid,
        error=action_result.error,
        extra={"message_key": action_result.message_key},
    )

    pending_out = None
    state_now = get_state(user_uuid, sid)
    if state_now and state_now.pending_intent:
        pending_out = {
            "intent": state_now.pending_intent,
            "entities": state_now.pending_entities,
            "missing_slots": state_now.missing_slots,
        }

    return {
        "text": built["text"],
        "action": action_result.action,
        "action_payload": {
            **(action_result.payload or {}),
            "intent": intent_result.intent.value,
            "entities": intent_result.entities,
            "pending": pending_out,
        },
        "reply_language": lang,
        "intent": intent_result.intent.value,
        "entities": intent_result.entities,
        "success": action_result.success,
    }


async def run_pipeline(
    *,
    user_uuid: str,
    prompt: Optional[str] = None,
    audio_base64: Optional[str] = None,
    content_type: str = "audio/wav",
    reply_language: str = "en",
    timezone_name: str = "UTC",
    auto_detect_language: bool = True,
    session_id: Optional[str] = None,
) -> dict[str, Any]:
    """
    Full end-to-end entry (optional). Stage C route still owns Voice Layer calls;
    prefer run_care_turn after STT/translate.
    """
    _ = (
        audio_base64,
        content_type,
        auto_detect_language,
    )
    if not (prompt or "").strip():
        raise ValueError("run_pipeline requires prompt text in Stage C route wiring")
    return await run_care_turn(
        user_uuid=user_uuid,
        text=prompt or "",
        language=reply_language,
        reminders={"today": [], "upcoming": [], "past": []},
        summaries=[],
        timezone_name=timezone_name,
        session_id=session_id,
    )

import logging
import os
from typing import Any, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect
from pipecat.audio.vad.silero import SileroVADAnalyzer
from pipecat.pipeline.pipeline import Pipeline
from pipecat.pipeline.runner import PipelineRunner
from pipecat.pipeline.task import PipelineParams, PipelineTask
from pipecat.processors.audio.vad_processor import VADProcessor
from pipecat.services.smallest.stt import SmallestSTTService
from pipecat.services.smallest.tts import SmallestTTSService
from pipecat.transports.websocket.fastapi import FastAPIWebsocketParams, FastAPIWebsocketTransport
from pydantic import BaseModel, Field

from services.auth_gateway import get_current_user_jwt, verify_auth_token
from services.db_service import get_user_summaries, get_user_uuid
from services.hydra_live_service import run_hydra_live_proxy
from services.reminder_service import list_patient_reminders
from services.remivox.pipeline import run_care_turn
from services.remivox.languages import resolve_session_language
from services.remivox.voice import (
    VoiceConfigError,
    VoiceSynthesisError,
    VoiceTranscriptionError,
    resolve_stt_language,
    synthesize_lightning,
    transcribe_pulse,
)
from services.remivox_intents import build_briefing
from services.remivox_languages import (
    LANGUAGE_DISPLAY_NAMES,
    SUPPORTED_LANGUAGE_CODES,
    language_display_name,
    normalize_language_code,
)
from services.subscription_service import (
    enforce_remivox_access,
)
from services.remivox.pipecat_processor import RemiVoxProcessor

logger = logging.getLogger(__name__)
REMIVOX_PIPELINE = (os.getenv("REMIVOX_PIPELINE", "legacy") or "legacy").strip().lower()
logger.info("RemiVox pipeline: %s", REMIVOX_PIPELINE)

router = APIRouter(prefix="/api/remivox", tags=["RemiVox"])


class RemiVoxBriefingResponse(BaseModel):
    text: str
    audio_base64: Optional[str] = None
    content_type: Optional[str] = None
    audio_unavailable: bool = False
    action: Optional[str] = None
    action_payload: Optional[dict[str, Any]] = None
    reply_language: Optional[str] = None
    detected_language: Optional[str] = None
    transcript: Optional[str] = None
    session_id: Optional[str] = None
    pending: Optional[dict[str, Any]] = None


class RemiVoxAskRequest(BaseModel):
    prompt: Optional[str] = None
    reply_language: Optional[str] = Field(default="en")
    timezone: Optional[str] = Field(default="UTC")
    audio_base64: Optional[str] = None
    content_type: Optional[str] = "audio/wav"
    auto_detect_language: bool = True
    session_id: Optional[str] = Field(
        default=None,
        description="Optional Vox conversation session id for pending-slot state.",
    )


class RemiVoxTranslateTurnRequest(BaseModel):
    """Turn-based fallback when a full Hydra duplex session is not used."""

    audio_base64: Optional[str] = None
    text: Optional[str] = None
    source_language: str = "en"
    target_language: str = "bn"
    content_type: Optional[str] = "audio/wav"


class RemiVoxLanguagesResponse(BaseModel):
    languages: list[dict[str, str]]


def _synthesize_smallestai(text: str, language: str = "en") -> tuple[Optional[str], Optional[str]]:
    """
    Compatibility wrapper → Voice Layer Lightning TTS.

    Returns (audio_base64, content_type). Raises HTTPException on hard failure.
    Missing API key returns (None, None) so callers can degrade to text-only.
    """
    try:
        result = synthesize_lightning(text, language=language)
    except VoiceSynthesisError as exc:
        raise HTTPException(
            status_code=502,
            detail="Vox voice generation failed. Please try again.",
        ) from exc
    if result.status == "unavailable":
        return None, None
    return result.audio_base64, result.content_type


def _pulse_transcribe(
    audio_b64: str,
    language: str = "multi",
    content_type: str = "audio/wav",
    preferred_language_fallback: str = "en",
) -> tuple[str, str]:
    """
    Compatibility wrapper → Voice Layer Pulse STT.

    Use language='multi' to auto-detect spoken language.
    Returns (transcript, detected_or_requested_language_code).
    """
    try:
        result = transcribe_pulse(
            audio_b64,
            language=language,
            content_type=content_type,
            preferred_language_fallback=preferred_language_fallback,
        )
        return result.transcript, result.detected_language
    except VoiceConfigError as exc:
        raise HTTPException(
            status_code=503,
            detail="Speech transcription is not configured.",
        ) from exc
    except VoiceTranscriptionError as exc:
        message = str(exc) or "Could not transcribe audio."
        status = 400 if "No speech" in message else 502
        raise HTTPException(status_code=status, detail=message) from exc


def _simple_translate(text: str, source_language: str, target_language: str) -> str:
    """
    Translate via Gemini when configured so non-English speech can drive English
    intent matching, then spoken replies can return in the user's language.
    """
    src = normalize_language_code(source_language)
    tgt = normalize_language_code(target_language)
    if src == tgt or not (text or "").strip():
        return text
    api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY") or ""
    if not api_key.strip():
        # Without Gemini, keep original text (intent matching may be weaker).
        return text
    try:
        from services.gemini_client import generate_text, response_text

        prompt = (
            f"Translate the following from {language_display_name(src)} to "
            f"{language_display_name(tgt)}. Return only the translation, no quotes "
            f"or commentary.\n\n{text}"
        )
        result = generate_text(
            prompt,
            model_name="gemini-2.0-flash",
            api_key=api_key.strip(),
            temperature=0.2,
        )
        out = response_text(result)
        return out or text
    except Exception as exc:
        logger.warning("Translate failed: %s", exc)
        return text


@router.get("/languages", response_model=RemiVoxLanguagesResponse)
async def remivox_languages():
    return RemiVoxLanguagesResponse(
        languages=[
            {"code": code, "name": LANGUAGE_DISPLAY_NAMES[code]}
            for code in sorted(SUPPORTED_LANGUAGE_CODES, key=lambda c: LANGUAGE_DISPLAY_NAMES[c])
        ]
    )


@router.post("/today", response_model=RemiVoxBriefingResponse)
async def remivox_today(
    reply_language: str = Query(default="en"),
    current_user: dict = Depends(get_current_user_jwt),
):
    return await _remivox_response(
        current_user=current_user,
        prompt=None,
        reply_language=reply_language,
        timezone_name="UTC",
    )


@router.post("/ask", response_model=RemiVoxBriefingResponse)
async def remivox_ask(
    request: RemiVoxAskRequest,
    current_user: dict = Depends(get_current_user_jwt),
):
    return await _remivox_response(
        current_user=current_user,
        prompt=request.prompt,
        reply_language=request.reply_language or "en",
        timezone_name=request.timezone or "UTC",
        audio_base64=request.audio_base64,
        content_type=request.content_type or "audio/wav",
        auto_detect_language=bool(request.auto_detect_language),
        session_id=request.session_id,
    )


@router.post("/translate-turn", response_model=RemiVoxBriefingResponse)
async def remivox_translate_turn(
    request: RemiVoxTranslateTurnRequest,
    current_user: dict = Depends(get_current_user_jwt),
):
    firebase_uid = current_user.get("sub")
    if not firebase_uid:
        raise HTTPException(status_code=401, detail="Invalid token")
    await enforce_remivox_access(firebase_uid)

    src = normalize_language_code(request.source_language)
    tgt = normalize_language_code(request.target_language, default="bn")
    source_text = (request.text or "").strip()
    if not source_text:
        if not request.audio_base64:
            raise HTTPException(status_code=400, detail="Provide text or audio_base64.")
        source_text, detected = _pulse_transcribe(
            request.audio_base64,
            language="multi" if src == "en" else src,
            content_type=request.content_type or "audio/wav",
        )
        if detected:
            src = detected
    if not source_text:
        raise HTTPException(status_code=400, detail="No speech detected.")

    translated = _simple_translate(source_text, src, tgt)
    text = (
        f"{translated} "
        f"(Translated from {language_display_name(src)} to {language_display_name(tgt)}. "
        "Not a medical interpreter.)"
    )
    audio_base64, content_type = _synthesize_smallestai(translated, language=tgt)
    return RemiVoxBriefingResponse(
        text=text,
        audio_base64=audio_base64,
        content_type=content_type,
        audio_unavailable=audio_base64 is None,
        action="translate_turn",
        action_payload={"source_text": source_text, "translated_text": translated},
        reply_language=tgt,
        detected_language=src,
        transcript=source_text,
    )


@router.websocket("/live")
async def remivox_live(
    websocket: WebSocket,
    token: str = Query(default=""),
    mode: str = Query(default="translate"),
    source_language: str = Query(default="en"),
    target_language: str = Query(default="bn"),
    timezone: str = Query(default="UTC"),
):
    """
    Hydra S2S live proxy.

    Connect: wss://<api>/api/remivox/live?token=<firebase_jwt>&mode=translate&source_language=en&target_language=bn
    """
    await websocket.accept()
    if not token.strip():
        await websocket.send_json({"type": "error", "error": {"message": "Missing token"}})
        await websocket.close(code=4401)
        return
    try:
        claims = verify_auth_token(token.strip())
        firebase_uid = claims.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid token")
    except Exception:
        await websocket.send_json({"type": "error", "error": {"message": "Unauthorized"}})
        await websocket.close(code=4401)
        return

    try:
        await run_hydra_live_proxy(
            websocket,
            firebase_uid=firebase_uid,
            mode=mode,
            source_language=source_language,
            target_language=target_language,
            timezone_name=timezone or "UTC",
        )
    except WebSocketDisconnect:
        return
    except Exception as exc:
        logger.warning("remivox live ended: %s", exc)
    finally:
        try:
            await websocket.close()
        except Exception:
            pass


async def _authenticate_remivox_stream(
    websocket: WebSocket,
    *,
    token: str,
    firebase_uid: str,
    timezone_name: str,
    session_id: Optional[str],
) -> tuple[str, str, Optional[str]]:
    token = (token or "").strip()
    firebase_uid = (firebase_uid or "").strip()
    tz = (timezone_name or "UTC").strip() or "UTC"
    sid = (session_id or "").strip() or None

    if not token and not firebase_uid:
        first_message = await websocket.receive_json()
        token = str(first_message.get("token") or first_message.get("idToken") or "").strip()
        firebase_uid = str(
            first_message.get("firebase_uid") or first_message.get("firebaseUid") or ""
        ).strip()
        tz = str(first_message.get("timezone") or tz).strip() or "UTC"
        sid = str(first_message.get("session_id") or first_message.get("sessionId") or sid or "").strip()
        sid = sid or None

    if token:
        claims = verify_auth_token(token)
        firebase_uid = claims.get("sub") or ""

    if not firebase_uid:
        raise HTTPException(status_code=401, detail="Invalid token")

    await enforce_remivox_access(firebase_uid)
    return firebase_uid, tz, sid


def _extract_remivox_keyword_boosts(reminders: dict[str, Any]) -> list[tuple[str, float]]:
    keywords: list[tuple[str, float]] = []
    seen: set[str] = set()
    for bucket in ("today", "upcoming"):
        for item in reminders.get(bucket) or []:
            if not isinstance(item, dict):
                continue
            for field in ("medication_name", "title", "message"):
                name = str(item.get(field) or "").strip()
                key = name.lower()
                if not name or key in seen:
                    continue
                seen.add(key)
                keywords.append((name, 3.0))
                break
    return keywords


def _format_smallest_keywords(keywords: list[tuple[str, float]]) -> str:
    formatted: list[str] = []
    for name, boost in keywords:
        clean_name = str(name).replace(",", " ").replace(":", " ").strip()
        if clean_name:
            formatted.append(f"{clean_name}:{boost:g}")
    return ",".join(formatted)


async def _load_remivox_stream_keywords(firebase_uid: str) -> list[tuple[str, float]]:
    try:
        user_uuid = await get_user_uuid(firebase_uid)
        reminders = await list_patient_reminders(user_uuid)
    except Exception as exc:
        logger.warning("remivox stream keyword load failed: %s", exc)
        return []
    return _extract_remivox_keyword_boosts(reminders)


def _build_remivox_pipecat_task(
    websocket: WebSocket,
    *,
    api_key: str,
    firebase_uid: str,
    timezone_name: str,
    session_id: Optional[str],
    language: str = "en",
    keywords: Optional[list[tuple[str, float]]] = None,
) -> tuple[PipelineRunner, PipelineTask]:
    keyword_boosts = list(keywords or [])
    transport = FastAPIWebsocketTransport(
        websocket=websocket,
        params=FastAPIWebsocketParams(
            audio_in_enabled=True,
            audio_in_sample_rate=16000,
            audio_out_enabled=True,
            audio_out_sample_rate=24000,
            audio_out_channels=1,
        ),
    )
    vad = VADProcessor(vad_analyzer=SileroVADAnalyzer(sample_rate=16000))
    stt = SmallestSTTService(
        api_key=api_key,
        eou_timeout_ms=2000,
        settings=SmallestSTTService.Settings(
            model="pulse",
            language=language,
            endpointing=True,
            redact_pii=True,
            keywords=_format_smallest_keywords(keyword_boosts),
            extra={"eou_timeout_ms": 2000},
        ),
    )
    processor = RemiVoxProcessor(
        firebase_uid=firebase_uid,
        timezone=timezone_name,
        session_id=session_id,
        keywords=keyword_boosts,
    )
    tts = SmallestTTSService(
        api_key=api_key,
        settings=SmallestTTSService.Settings(
            model="lightning_v3.1",
            voice="meher",
            language=language,
            speed=0.85,
        ),
    )

    pipeline = Pipeline([transport.input(), vad, stt, processor, tts, transport.output()])
    task = PipelineTask(
        pipeline,
        params=PipelineParams(
            audio_in_sample_rate=16000,
            audio_out_sample_rate=24000,
        ),
    )
    runner = PipelineRunner(handle_sigint=False)
    return runner, task


@router.websocket("/stream")
async def remivox_stream(
    websocket: WebSocket,
    token: str = Query(default=""),
    firebase_uid: str = Query(default=""),
    timezone: str = Query(default="UTC"),
    session_id: Optional[str] = Query(default=None),
    language: str = Query(default="en"),
):
    await websocket.accept()

    if REMIVOX_PIPELINE != "pipecat":
        await websocket.send_json(
            {
                "type": "error",
                "error": {"message": "RemiVox Pipecat streaming is not enabled."},
            }
        )
        await websocket.close(code=1013)
        return

    stream_language = (language or "en").strip().lower()
    if stream_language not in {"en", "hi"}:
        await websocket.send_json(
            {
                "type": "error",
                "error": {"message": "Unsupported RemiVox stream language."},
            }
        )
        await websocket.close(code=1008)
        return

    api_key = (os.getenv("SMALLESTAI_API_KEY") or "").strip()
    if not api_key:
        await websocket.send_json(
            {"type": "error", "error": {"message": "Smallest AI is not configured."}}
        )
        await websocket.close(code=1011)
        return

    task: Optional[PipelineTask] = None
    try:
        stream_uid, stream_timezone, stream_session_id = await _authenticate_remivox_stream(
            websocket,
            token=token,
            firebase_uid=firebase_uid,
            timezone_name=timezone,
            session_id=session_id,
        )
        keyword_boosts = await _load_remivox_stream_keywords(stream_uid)
        runner, task = _build_remivox_pipecat_task(
            websocket,
            api_key=api_key,
            firebase_uid=stream_uid,
            timezone_name=stream_timezone,
            session_id=stream_session_id,
            language=stream_language,
            keywords=keyword_boosts,
        )
        await runner.run(task)
    except WebSocketDisconnect:
        return
    except HTTPException:
        await websocket.send_json({"type": "error", "error": {"message": "Unauthorized"}})
        await websocket.close(code=4401)
    except Exception as exc:
        logger.warning("remivox stream ended: %s", exc)
        try:
            await websocket.send_json(
                {"type": "error", "error": {"message": "RemiVox stream ended."}}
            )
        except Exception:
            pass
    finally:
        if task is not None:
            try:
                await task.cancel(reason="remivox stream closed")
            except Exception:
                pass
        try:
            await websocket.close()
        except Exception:
            pass


async def _remivox_response(
    current_user: dict,
    prompt: Optional[str],
    reply_language: str,
    timezone_name: str,
    audio_base64: Optional[str] = None,
    content_type: str = "audio/wav",
    auto_detect_language: bool = True,
    session_id: Optional[str] = None,
):
    firebase_uid = current_user.get("sub")
    if not firebase_uid:
        raise HTTPException(status_code=401, detail="Invalid token")

    await enforce_remivox_access(firebase_uid)
    user_uuid = await get_user_uuid(firebase_uid)
    reminders = await list_patient_reminders(user_uuid)
    summaries = await get_user_summaries(user_uuid, firebase_uid=firebase_uid)

    preferred = normalize_language_code(reply_language)
    spoken_lang = preferred
    transcript: Optional[str] = None
    intent_prompt = (prompt or "").strip()

    # Audio path: Pulse auto-detects Hindi/Gujarati/Spanish/etc., then we act + reply
    # in that same language. Stage B fix: auto_detect → language='multi' (not 'en').
    if audio_base64:
        stt_lang = resolve_stt_language(
            auto_detect_language=auto_detect_language,
            preferred_language=preferred,
        )
        transcript, spoken_lang = _pulse_transcribe(
            audio_base64,
            language=stt_lang,
            content_type=content_type or "audio/wav",
            preferred_language_fallback=preferred,
        )
        intent_prompt = transcript
        # Restrict to Remi's supported set; fall back to preferred app language.
        if spoken_lang not in SUPPORTED_LANGUAGE_CODES:
            spoken_lang = preferred

    # Stage D: preserve detected language; never force English unless requested/detected.
    lang = resolve_session_language(
        detected_language=spoken_lang if audio_base64 else None,
        preferred_language=preferred,
        has_audio=bool(audio_base64),
    )
    sid = (session_id or firebase_uid or "default").strip() or "default"

    if intent_prompt:
        # Intent Router is English-keyed; translate non-English speech → English for routing.
        english_prompt = intent_prompt
        if lang != "en":
            english_prompt = _simple_translate(intent_prompt, lang, "en")

        # Stage C: Intent Router → Action Executor → Response Builder
        result = await run_care_turn(
            user_uuid=user_uuid,
            text=english_prompt,
            language=lang,
            detected_language=spoken_lang if audio_base64 else lang,
            reminders=reminders,
            summaries=summaries,
            timezone_name=timezone_name or "UTC",
            session_id=sid,
            transcript=transcript or intent_prompt,
        )
        text = result["text"]
        action = result.get("action")
        action_payload = result.get("action_payload") or {}
        # Speak back in the language the user used.
        if lang != "en":
            text = _simple_translate(text, "en", lang)
    else:
        text = build_briefing(reminders, summaries)
        # Stage C personality: strip legacy always-on disclaimer from briefing.
        text = text.replace(
            "This is not medical advice. Take medicines only as prescribed and ask a clinician "
            "if anything feels unclear.",
            "",
        ).strip()
        if lang != "en":
            text = _simple_translate(text, "en", lang)
        action = "briefing"
        action_payload = {}

    # Voice Layer TTS — language follows reply language (not hardcoded English).
    try:
        tts = synthesize_lightning(text, language=lang)
        audio_out, out_type = tts.audio_base64, tts.content_type
        if tts.fallback_status == "english" and action_payload is not None:
            action_payload = {**action_payload, "tts_fallback": tts.fallback_status}
    except VoiceSynthesisError as exc:
        raise HTTPException(
            status_code=502,
            detail="Vox voice generation failed. Please try again.",
        ) from exc

    pending_out: Optional[dict[str, Any]] = None
    if isinstance(action_payload, dict):
        maybe_pending = action_payload.get("pending")
        if isinstance(maybe_pending, dict) and maybe_pending.get("intent"):
            pending_out = maybe_pending

    return RemiVoxBriefingResponse(
        text=text,
        audio_base64=audio_out,
        content_type=out_type,
        audio_unavailable=audio_out is None,
        action=action,
        action_payload=action_payload,
        reply_language=lang,
        detected_language=spoken_lang if audio_base64 else None,
        transcript=transcript,
        session_id=sid,
        pending=pending_out,
    )

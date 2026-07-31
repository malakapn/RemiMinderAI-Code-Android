import base64
import logging
import os
from typing import Any, Optional

import requests
from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect
from pydantic import BaseModel, Field

from services.auth_gateway import get_current_user_jwt, verify_auth_token
from services.db_service import get_user_summaries, get_user_uuid
from services.hydra_live_service import run_hydra_live_proxy
from services.reminder_service import list_patient_reminders
from services.remivox_intents import build_briefing, handle_prompt
from services.remivox_languages import (
    LANGUAGE_DISPLAY_NAMES,
    SUPPORTED_LANGUAGE_CODES,
    language_display_name,
    normalize_language_code,
)
from services.subscription_service import (
    enforce_remivox_access,
)

logger = logging.getLogger(__name__)

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


class RemiVoxAskRequest(BaseModel):
    prompt: Optional[str] = None
    reply_language: Optional[str] = Field(default="en")
    timezone: Optional[str] = Field(default="UTC")
    audio_base64: Optional[str] = None
    content_type: Optional[str] = "audio/wav"
    auto_detect_language: bool = True


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
    api_key = os.getenv("SMALLESTAI_API_KEY", "").strip()
    if not api_key:
        return None, None

    lang = normalize_language_code(language)
    # Prefer Lightning v2 when speaking non-English Remi locales (broader language coverage).
    default_url = (
        "https://api.smallest.ai/waves/v1/lightning-v2/get_speech"
        if lang != "en"
        else "https://api.smallest.ai/waves/v1/lightning-v3.1/get_speech"
    )
    url = os.getenv("SMALLESTAI_TTS_URL", default_url).strip()
    voice_id = os.getenv("SMALLESTAI_VOICE_ID", "olivia").strip()
    output_format = os.getenv("SMALLESTAI_OUTPUT_FORMAT", "mp3").strip()
    sample_rate = int(os.getenv("SMALLESTAI_SAMPLE_RATE", "24000"))

    payload: dict[str, Any] = {
        "text": text,
        "voice_id": voice_id,
        "sample_rate": sample_rate,
        "speed": 0.95,
        "language": lang,
        "output_format": output_format,
    }

    response = requests.post(
        url,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        json=payload,
        timeout=25,
    )
    if response.status_code >= 400 and lang != "en":
        # Fallback to English voice path if locale-specific TTS rejects the request.
        logger.warning(
            "SmallestAI TTS locale failed (%s): %s %s",
            lang,
            response.status_code,
            response.text[:200],
        )
        payload["language"] = "en"
        response = requests.post(
            os.getenv(
                "SMALLESTAI_TTS_URL_FALLBACK",
                "https://api.smallest.ai/waves/v1/lightning-v3.1/get_speech",
            ).strip(),
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            json=payload,
            timeout=25,
        )

    if response.status_code >= 400:
        logger.warning("SmallestAI TTS failed: %s %s", response.status_code, response.text[:300])
        raise HTTPException(status_code=502, detail="Vox voice generation failed. Please try again.")

    content_type = response.headers.get("content-type") or f"audio/{output_format}"
    return base64.b64encode(response.content).decode("ascii"), content_type


def _pulse_transcribe(
    audio_b64: str,
    language: str = "multi",
    content_type: str = "audio/wav",
) -> tuple[str, str]:
    """
    Transcribe with Pulse. Use language='multi' to auto-detect spoken language.
    Returns (transcript, detected_or_requested_language_code).
    """
    api_key = os.getenv("SMALLESTAI_API_KEY", "").strip()
    if not api_key:
        raise HTTPException(status_code=503, detail="Speech transcription is not configured.")

    lang_param = (language or "en").strip().lower() or "en"
    if lang_param != "multi":
        lang_param = normalize_language_code(lang_param)

    base = os.getenv(
        "SMALLESTAI_STT_URL",
        "https://api.smallest.ai/waves/v1/stt/?model=pulse",
    ).strip().rstrip("?")
    # Force query language for auto-detect / locale.
    if "language=" in base:
        url = base
    else:
        sep = "&" if "?" in base else "?"
        url = f"{base}{sep}language={lang_param}"

    headers = {"Authorization": f"Bearer {api_key}"}
    audio_bytes = base64.b64decode(audio_b64)
    try:
        # Preferred: raw audio body (Pulse pre-recorded API).
        response = requests.post(
            url,
            headers={**headers, "Content-Type": "application/octet-stream"},
            data=audio_bytes,
            timeout=45,
        )
        if response.status_code >= 400:
            files = {"file": ("vox.wav", audio_bytes, content_type or "audio/wav")}
            response = requests.post(url, headers=headers, files=files, timeout=45)
        if response.status_code >= 400:
            response = requests.post(
                url,
                headers={**headers, "Content-Type": "application/json"},
                json={"audio": audio_b64, "language": lang_param},
                timeout=45,
            )
        if response.status_code >= 400:
            logger.warning("Pulse STT failed: %s %s", response.status_code, response.text[:300])
            raise HTTPException(status_code=502, detail="Could not transcribe audio.")

        data: Any = {}
        try:
            data = response.json()
        except Exception:
            text = response.text.strip()
            return text, normalize_language_code(lang_param if lang_param != "multi" else "en")

        text = ""
        detected = lang_param if lang_param != "multi" else "en"
        if isinstance(data, dict):
            for key in ("text", "transcript", "transcription"):
                if data.get(key):
                    text = str(data[key]).strip()
                    break
            if not text and isinstance(data.get("data"), dict):
                nested = data["data"]
                for key in ("text", "transcript", "transcription"):
                    if nested.get(key):
                        text = str(nested[key]).strip()
                        break
            raw_lang = data.get("language") or data.get("detected_language")
            if not raw_lang and isinstance(data.get("data"), dict):
                raw_lang = data["data"].get("language")
            if isinstance(data.get("languages"), list) and data["languages"]:
                raw_lang = raw_lang or data["languages"][0]
            if raw_lang:
                detected = normalize_language_code(str(raw_lang))
        if not text:
            raise HTTPException(status_code=400, detail="No speech detected.")
        return text, detected
    except HTTPException:
        raise
    except Exception as exc:
        logger.warning("Pulse STT error: %s", exc)
        raise HTTPException(status_code=502, detail="Could not transcribe audio.") from exc


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
        import google.generativeai as genai  # type: ignore

        genai.configure(api_key=api_key.strip())
        model = genai.GenerativeModel("gemini-2.0-flash")
        prompt = (
            f"Translate the following from {language_display_name(src)} to "
            f"{language_display_name(tgt)}. Return only the translation, no quotes "
            f"or commentary.\n\n{text}"
        )
        result = model.generate_content(prompt)
        out = (getattr(result, "text", None) or "").strip()
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


async def _remivox_response(
    current_user: dict,
    prompt: Optional[str],
    reply_language: str,
    timezone_name: str,
    audio_base64: Optional[str] = None,
    content_type: str = "audio/wav",
    auto_detect_language: bool = True,
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
    # in that same language.
    if audio_base64:
        stt_lang = "en" if auto_detect_language else preferred
        transcript, spoken_lang = _pulse_transcribe(
            audio_base64,
            language=stt_lang,
            content_type=content_type or "audio/wav",
        )
        intent_prompt = transcript
        # Restrict to Remi's supported set; fall back to preferred app language.
        if spoken_lang not in SUPPORTED_LANGUAGE_CODES:
            spoken_lang = preferred

    lang = spoken_lang if audio_base64 else preferred

    if intent_prompt:
        # Intent engine is English-keyed; translate non-English speech → English for actions.
        english_prompt = intent_prompt
        if lang != "en":
            english_prompt = _simple_translate(intent_prompt, lang, "en")

        result = await handle_prompt(
            prompt=english_prompt,
            user_uuid=user_uuid,
            reminders=reminders,
            summaries=summaries,
            timezone_name=timezone_name or "UTC",
            reply_language=lang,
        )
        text = result["text"]
        action = result.get("action")
        action_payload = result.get("action_payload") or {}
        # Speak back in the language the user used.
        if lang != "en":
            text = _simple_translate(text, "en", lang)
    else:
        text = build_briefing(reminders, summaries)
        if lang != "en":
            text = _simple_translate(text, "en", lang)
        action = "briefing"
        action_payload = {}

    audio_out, out_type = _synthesize_smallestai(text, language=lang)

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
    )

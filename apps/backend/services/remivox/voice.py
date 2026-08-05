"""
RemiVox Voice Layer (Stage B).

SmallestAI Pulse STT + SmallestAI Lightning TTS.

Production routes call this module. Thin wrappers in route/remivox.py preserve
HTTP contracts and map Voice errors to HTTPException.
"""

from __future__ import annotations

import base64
import logging
import os
import time
from dataclasses import dataclass, field
from typing import Any, Optional

import requests

from services.remivox.languages import normalize_language_code
from services.remivox.observability import log_voice_operation

logger = logging.getLogger(__name__)

PULSE_PROVIDER = "pulse"
LIGHTNING_PROVIDER = "lightning"

DEFAULT_STT_URL = "https://api.smallest.ai/waves/v1/stt/?model=pulse"
DEFAULT_TTS_URL_EN = "https://api.smallest.ai/waves/v1/lightning-v3.1/get_speech"
DEFAULT_TTS_URL_MULTI = "https://api.smallest.ai/waves/v1/lightning-v2/get_speech"


class VoiceConfigError(Exception):
    """Missing API key / provider not configured."""


class VoiceTranscriptionError(Exception):
    """Pulse STT failed or returned empty speech."""


class VoiceSynthesisError(Exception):
    """Lightning TTS failed after fallbacks."""


@dataclass(frozen=True)
class SttResult:
    transcript: str
    detected_language: str
    provider: str = PULSE_PROVIDER
    requested_language: str = "multi"
    latency_ms: float = 0.0
    success: bool = True
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class TtsResult:
    audio_base64: Optional[str]
    content_type: Optional[str]
    language: str
    language_used: str
    fallback_status: str  # none | english | unavailable
    status: str  # ok | unavailable | failed
    provider: str = LIGHTNING_PROVIDER
    latency_ms: float = 0.0
    success: bool = True

    def as_dict(self) -> dict[str, Any]:
        return {
            "audio_base64": self.audio_base64,
            "content_type": self.content_type,
            "language": self.language,
            "language_used": self.language_used,
            "fallback_status": self.fallback_status,
            "status": self.status,
            "provider": self.provider,
            "latency_ms": self.latency_ms,
            "success": self.success,
        }


def resolve_stt_language(
    *,
    auto_detect_language: bool,
    preferred_language: str = "en",
) -> str:
    """
    Map ask-request flags to Pulse language parameter.

    Bugfix: auto_detect_language=True must use language='multi', not 'en'.
    """
    if auto_detect_language:
        return "multi"
    return normalize_language_code(preferred_language)


def _api_key() -> str:
    return os.getenv("SMALLESTAI_API_KEY", "").strip()


def _stt_url(lang_param: str) -> str:
    base = (os.getenv("SMALLESTAI_STT_URL") or DEFAULT_STT_URL).strip().rstrip("?")
    if "language=" in base:
        return base
    sep = "&" if "?" in base else "?"
    return f"{base}{sep}language={lang_param}"


def _parse_pulse_payload(
    data: Any,
    *,
    lang_param: str,
    raw_text_fallback: str = "",
) -> tuple[str, str, dict[str, Any]]:
    """Extract transcript + detected language from Pulse JSON/text."""
    metadata: dict[str, Any] = {}
    if not isinstance(data, dict):
        text = (raw_text_fallback or str(data or "")).strip()
        detected = normalize_language_code(lang_param if lang_param != "multi" else "en")
        return text, detected, metadata

    text = ""
    detected = lang_param if lang_param != "multi" else "en"
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
        metadata["nested_keys"] = list(nested.keys())

    raw_lang = data.get("language") or data.get("detected_language")
    if not raw_lang and isinstance(data.get("data"), dict):
        raw_lang = data["data"].get("language")
    if isinstance(data.get("languages"), list) and data["languages"]:
        raw_lang = raw_lang or data["languages"][0]
    if raw_lang:
        detected = normalize_language_code(str(raw_lang))
        metadata["raw_language"] = str(raw_lang)
    else:
        detected = normalize_language_code(detected if detected != "multi" else "en")

    return text, detected, metadata


def _post_pulse(
    *,
    url: str,
    api_key: str,
    audio_b64: str,
    audio_bytes: bytes,
    content_type: str,
    lang_param: str,
) -> requests.Response:
    headers = {"Authorization": f"Bearer {api_key}"}
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
    return response


def transcribe_pulse(
    audio_b64: str,
    *,
    language: str = "multi",
    content_type: str = "audio/wav",
    preferred_language_fallback: str = "en",
) -> SttResult:
    """
    Transcribe with SmallestAI Pulse.

    language='multi' enables auto-detect across Remi locales.
    On multi failure, retries once with preferred_language_fallback (keeps
    existing language fallback until broader tests pass).
    """
    started = time.perf_counter()
    api_key = _api_key()
    if not api_key:
        log_voice_operation(
            provider=PULSE_PROVIDER,
            operation="stt",
            input_language=language,
            success=False,
            error="missing_api_key",
            latency_ms=0.0,
        )
        raise VoiceConfigError("Speech transcription is not configured.")

    lang_param = (language or "multi").strip().lower() or "multi"
    if lang_param != "multi":
        lang_param = normalize_language_code(lang_param)

    try:
        audio_bytes = base64.b64decode(audio_b64)
    except Exception as exc:
        raise VoiceTranscriptionError("Invalid audio_base64.") from exc

    attempts = [lang_param]
    preferred = normalize_language_code(preferred_language_fallback)
    if lang_param == "multi" and preferred not in attempts:
        attempts.append(preferred)
    if "en" not in attempts:
        attempts.append("en")

    last_error: Optional[str] = None
    for attempt_lang in attempts:
        url = _stt_url(attempt_lang)
        try:
            response = _post_pulse(
                url=url,
                api_key=api_key,
                audio_b64=audio_b64,
                audio_bytes=audio_bytes,
                content_type=content_type,
                lang_param=attempt_lang,
            )
        except Exception as exc:
            last_error = str(exc)
            logger.warning("Pulse STT request error (%s): %s", attempt_lang, exc)
            continue

        if response.status_code >= 400:
            last_error = f"HTTP {response.status_code}: {response.text[:200]}"
            logger.warning("Pulse STT failed (%s): %s", attempt_lang, last_error)
            continue

        try:
            data = response.json()
            text, detected, metadata = _parse_pulse_payload(data, lang_param=attempt_lang)
        except Exception:
            text, detected, metadata = _parse_pulse_payload(
                {},
                lang_param=attempt_lang,
                raw_text_fallback=response.text.strip(),
            )

        if not text:
            last_error = "No speech detected."
            continue

        latency_ms = (time.perf_counter() - started) * 1000.0
        result = SttResult(
            transcript=text,
            detected_language=detected,
            provider=PULSE_PROVIDER,
            requested_language=lang_param,
            latency_ms=latency_ms,
            success=True,
            metadata={
                **metadata,
                "attempt_language": attempt_lang,
                "fallback_used": attempt_lang != lang_param,
            },
        )
        log_voice_operation(
            provider=PULSE_PROVIDER,
            operation="stt",
            input_language=lang_param,
            detected_language=detected,
            output_language=detected,
            latency_ms=latency_ms,
            success=True,
            extra={"attempt_language": attempt_lang, "transcript_len": len(text)},
        )
        return result

    latency_ms = (time.perf_counter() - started) * 1000.0
    log_voice_operation(
        provider=PULSE_PROVIDER,
        operation="stt",
        input_language=lang_param,
        latency_ms=latency_ms,
        success=False,
        error=last_error or "stt_failed",
    )
    raise VoiceTranscriptionError(last_error or "Could not transcribe audio.")


def synthesize_lightning(
    text: str,
    *,
    language: str = "en",
) -> TtsResult:
    """
    Synthesize with SmallestAI Lightning.

    Does not hardcode English for the primary attempt. Non-English failures
    fall back to English Lightning (legacy compatibility).
    """
    started = time.perf_counter()
    api_key = _api_key()
    if not api_key:
        log_voice_operation(
            provider=LIGHTNING_PROVIDER,
            operation="tts",
            input_language=language,
            output_language=None,
            success=False,
            error="missing_api_key",
            latency_ms=0.0,
        )
        return TtsResult(
            audio_base64=None,
            content_type=None,
            language=normalize_language_code(language),
            language_used=normalize_language_code(language),
            fallback_status="unavailable",
            status="unavailable",
            success=False,
            latency_ms=0.0,
        )

    requested = normalize_language_code(language)
    # Prefer Lightning v2 for non-English Remi locales (broader coverage).
    default_url = DEFAULT_TTS_URL_MULTI if requested != "en" else DEFAULT_TTS_URL_EN
    url = (os.getenv("SMALLESTAI_TTS_URL") or default_url).strip()
    voice_id = (os.getenv("SMALLESTAI_VOICE_ID") or "olivia").strip()
    output_format = (os.getenv("SMALLESTAI_OUTPUT_FORMAT") or "mp3").strip()
    sample_rate = int(os.getenv("SMALLESTAI_SAMPLE_RATE") or "24000")

    payload: dict[str, Any] = {
        "text": text,
        "voice_id": voice_id,
        "sample_rate": sample_rate,
        "speed": 0.95,
        "language": requested,
        "output_format": output_format,
    }

    language_used = requested
    fallback_status = "none"

    try:
        response = requests.post(
            url,
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            json=payload,
            timeout=25,
        )
    except Exception as exc:
        latency_ms = (time.perf_counter() - started) * 1000.0
        log_voice_operation(
            provider=LIGHTNING_PROVIDER,
            operation="tts",
            input_language=requested,
            output_language=None,
            latency_ms=latency_ms,
            success=False,
            error=str(exc),
        )
        raise VoiceSynthesisError("Vox voice generation failed.") from exc

    if response.status_code >= 400 and requested != "en":
        logger.warning(
            "SmallestAI TTS locale failed (%s): %s %s",
            requested,
            response.status_code,
            response.text[:200],
        )
        payload["language"] = "en"
        language_used = "en"
        fallback_status = "english"
        try:
            response = requests.post(
                os.getenv("SMALLESTAI_TTS_URL_FALLBACK") or DEFAULT_TTS_URL_EN,
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                },
                json=payload,
                timeout=25,
            )
        except Exception as exc:
            latency_ms = (time.perf_counter() - started) * 1000.0
            log_voice_operation(
                provider=LIGHTNING_PROVIDER,
                operation="tts",
                input_language=requested,
                output_language="en",
                latency_ms=latency_ms,
                success=False,
                error=str(exc),
                extra={"fallback_status": fallback_status},
            )
            raise VoiceSynthesisError("Vox voice generation failed.") from exc

    latency_ms = (time.perf_counter() - started) * 1000.0

    if response.status_code >= 400:
        log_voice_operation(
            provider=LIGHTNING_PROVIDER,
            operation="tts",
            input_language=requested,
            output_language=language_used,
            latency_ms=latency_ms,
            success=False,
            error=f"HTTP {response.status_code}",
            extra={"fallback_status": fallback_status, "body": response.text[:200]},
        )
        raise VoiceSynthesisError("Vox voice generation failed.")

    content_type = response.headers.get("content-type") or f"audio/{output_format}"
    audio_b64 = base64.b64encode(response.content).decode("ascii")
    result = TtsResult(
        audio_base64=audio_b64,
        content_type=content_type,
        language=requested,
        language_used=language_used,
        fallback_status=fallback_status,
        status="ok",
        success=True,
        latency_ms=latency_ms,
    )
    log_voice_operation(
        provider=LIGHTNING_PROVIDER,
        operation="tts",
        input_language=requested,
        output_language=language_used,
        latency_ms=latency_ms,
        success=True,
        extra={"fallback_status": fallback_status},
    )
    return result

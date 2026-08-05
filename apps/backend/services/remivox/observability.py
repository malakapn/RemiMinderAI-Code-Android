"""
RemiVox observability.

Voice operations (Stage B+) log provider, languages, latency, success/failure.
Full interaction logging (intent/action) lands in later stages.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Optional

logger = logging.getLogger("remivox.observability")


def log_voice_operation(
    *,
    provider: str,
    operation: str,
    input_language: Optional[str] = None,
    detected_language: Optional[str] = None,
    output_language: Optional[str] = None,
    latency_ms: Optional[float] = None,
    success: bool = True,
    error: Optional[str] = None,
    extra: Optional[dict[str, Any]] = None,
) -> dict[str, Any]:
    """Log a Pulse STT or Lightning TTS operation."""
    record: dict[str, Any] = {
        "event": "remivox_voice",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "provider": provider,
        "operation": operation,
        "input_language": input_language,
        "detected_language": detected_language,
        "output_language": output_language,
        "latency_ms": round(latency_ms, 2) if latency_ms is not None else None,
        "success": success,
        "error": error,
    }
    if extra:
        record["extra"] = extra
    logger.info("remivox_voice %s", record)
    return record


def log_interaction(
    *,
    user_id: str,
    detected_language: Optional[str] = None,
    transcript: Optional[str] = None,
    intent: Optional[str] = None,
    entities: Optional[dict[str, Any]] = None,
    action: Optional[str] = None,
    success: Optional[bool] = None,
    response_language: Optional[str] = None,
    tts_status: Optional[str] = None,
    session_id: Optional[str] = None,
    error: Optional[str] = None,
    extra: Optional[dict[str, Any]] = None,
) -> dict[str, Any]:
    """Emit a structured Vox interaction record."""
    record: dict[str, Any] = {
        "event": "remivox_interaction",
        "user_id": user_id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "detected_language": detected_language,
        "transcript": transcript,
        "intent": intent,
        "entities": entities or {},
        "action": action,
        "success": success,
        "response_language": response_language,
        "tts_status": tts_status,
        "session_id": session_id,
        "error": error,
    }
    if extra:
        record["extra"] = extra
    logger.info("remivox_interaction %s", record)
    return record

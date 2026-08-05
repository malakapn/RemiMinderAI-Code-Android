"""
RemiVox observability (Stage D — PHI-safe).

Logs operational metadata only.
Never log transcripts, medication names, entity payloads, or other PHI.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Optional

logger = logging.getLogger("remivox.observability")

_PHI_EXTRA_KEYS = frozenset(
    {
        "transcript",
        "text",
        "entities",
        "medication",
        "title",
        "title_hint",
        "summary",
        "names",
        "pending_entities",
        "audio_base64",
        "prompt",
    }
)


def _sanitize_extra(extra: Optional[dict[str, Any]]) -> dict[str, Any]:
    if not extra:
        return {}
    clean: dict[str, Any] = {}
    for key, value in extra.items():
        if key.lower() in _PHI_EXTRA_KEYS:
            continue
        if isinstance(value, str) and len(value) > 120:
            continue
        clean[key] = value
    return clean


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
    """Log Pulse STT / Lightning TTS metadata (no audio/transcript content)."""
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
        "failure_status": None if success else (error or "failed"),
    }
    clean_extra = _sanitize_extra(extra)
    if clean_extra:
        record["extra"] = clean_extra
    logger.info("remivox_voice %s", record)
    return record


def log_intent_decision(
    *,
    user_id: str,
    intent: Optional[str] = None,
    confidence: Optional[float] = None,
    missing_slots: Optional[list[str]] = None,
    detected_language: Optional[str] = None,
    session_id: Optional[str] = None,
    extra: Optional[dict[str, Any]] = None,
) -> dict[str, Any]:
    """Log intent routing metadata (no transcript / entity values)."""
    record: dict[str, Any] = {
        "event": "remivox_intent",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "user_id": user_id,
        "session_id": session_id,
        "detected_language": detected_language,
        "intent": intent,
        "confidence": confidence,
        "missing_slots": list(missing_slots or []),
    }
    clean_extra = _sanitize_extra(extra)
    if clean_extra:
        record["extra"] = clean_extra
    logger.info("remivox_intent %s", record)
    return record


def log_action_execution(
    *,
    user_id: str,
    action: Optional[str] = None,
    validation_result: Optional[str] = None,
    execution_result: Optional[str] = None,
    success: Optional[bool] = None,
    session_id: Optional[str] = None,
    error: Optional[str] = None,
    extra: Optional[dict[str, Any]] = None,
) -> dict[str, Any]:
    """Log action execution metadata (no medication / reminder titles)."""
    record: dict[str, Any] = {
        "event": "remivox_action",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "user_id": user_id,
        "session_id": session_id,
        "action_requested": action,
        "validation_result": validation_result,
        "execution_result": execution_result,
        "success": success,
        "error": error,
    }
    clean_extra = _sanitize_extra(extra)
    if clean_extra:
        record["extra"] = clean_extra
    logger.info("remivox_action %s", record)
    return record


def log_interaction(
    *,
    user_id: str,
    detected_language: Optional[str] = None,
    transcript: Optional[str] = None,  # accepted for API compat; never logged
    intent: Optional[str] = None,
    entities: Optional[dict[str, Any]] = None,  # accepted for API compat; never logged
    action: Optional[str] = None,
    success: Optional[bool] = None,
    response_language: Optional[str] = None,
    tts_status: Optional[str] = None,
    session_id: Optional[str] = None,
    error: Optional[str] = None,
    confidence: Optional[float] = None,
    missing_slots: Optional[list[str]] = None,
    validation_result: Optional[str] = None,
    execution_result: Optional[str] = None,
    extra: Optional[dict[str, Any]] = None,
) -> dict[str, Any]:
    """
    Emit a PHI-safe interaction summary.

    Explicitly drops transcript and entities even if callers pass them.
    """
    _ = (transcript, entities)  # intentionally unused — PHI
    record: dict[str, Any] = {
        "event": "remivox_interaction",
        "user_id": user_id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "detected_language": detected_language,
        "response_language": response_language,
        "intent": intent,
        "confidence": confidence,
        "missing_slots": list(missing_slots or []),
        "action_requested": action,
        "validation_result": validation_result,
        "execution_result": execution_result,
        "success": success,
        "tts_status": tts_status,
        "session_id": session_id,
        "error": error,
    }
    clean_extra = _sanitize_extra(extra)
    if clean_extra:
        record["extra"] = clean_extra
    logger.info("remivox_interaction %s", record)
    return record

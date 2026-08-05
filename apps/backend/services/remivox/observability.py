"""
RemiVox observability (Stage A stub).

Every interaction should eventually log:
- user_id, timestamp
- detected language, STT transcript
- detected intent, extracted entities
- action executed, success/failure
- response language, TTS status
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Optional

logger = logging.getLogger("remivox.observability")


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
    """Emit a structured Vox interaction record (Stage A: log only)."""
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

"""
RemiVox conversation state (Stage D).

Storage: existing services.cache_service (TTL cache).
Key: remivox:state:{user_uuid}:{session_id}
TTL: 5 minutes

No Redis and no Cloud SQL schema changes.
cache_service is process-local today; missing/expired state is handled
gracefully so multi-instance deploys degrade to re-clarification rather
than errors.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Optional

from services.cache_service import get as cache_get
from services.cache_service import invalidate as cache_invalidate
from services.cache_service import set as cache_set

logger = logging.getLogger(__name__)

DEFAULT_STATE_TTL_SECONDS = 5 * 60  # 5 minutes


@dataclass
class ConversationState:
    user_id: str
    session_id: str
    language: str = "en"
    detected_language: Optional[str] = None
    pending_intent: Optional[str] = None
    pending_entities: dict[str, Any] = field(default_factory=dict)
    missing_slots: list[str] = field(default_factory=list)
    updated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def is_expired(self, ttl_seconds: int = DEFAULT_STATE_TTL_SECONDS) -> bool:
        age = (datetime.now(timezone.utc) - self.updated_at).total_seconds()
        return age > ttl_seconds

    def to_cache_dict(self) -> dict[str, Any]:
        return {
            "user_id": self.user_id,
            "session_id": self.session_id,
            "language": self.language,
            "detected_language": self.detected_language,
            "pending_intent": self.pending_intent,
            "pending_entities": dict(self.pending_entities or {}),
            "missing_slots": list(self.missing_slots or []),
            "updated_at": self.updated_at.isoformat(),
        }

    @classmethod
    def from_cache_dict(cls, data: Any) -> Optional["ConversationState"]:
        if not isinstance(data, dict):
            return None
        try:
            raw_ts = data.get("updated_at")
            if isinstance(raw_ts, datetime):
                updated_at = raw_ts if raw_ts.tzinfo else raw_ts.replace(tzinfo=timezone.utc)
            elif isinstance(raw_ts, str) and raw_ts:
                updated_at = datetime.fromisoformat(raw_ts.replace("Z", "+00:00"))
            else:
                updated_at = datetime.now(timezone.utc)
            return cls(
                user_id=str(data.get("user_id") or ""),
                session_id=str(data.get("session_id") or ""),
                language=str(data.get("language") or "en"),
                detected_language=data.get("detected_language"),
                pending_intent=data.get("pending_intent"),
                pending_entities=dict(data.get("pending_entities") or {}),
                missing_slots=list(data.get("missing_slots") or []),
                updated_at=updated_at,
            )
        except Exception as exc:
            logger.warning("Failed to deserialize RemiVox state: %s", exc)
            return None


def state_key(user_id: str, session_id: str) -> str:
    return f"remivox:state:{user_id}:{session_id}"


def get_state(user_id: str, session_id: str) -> Optional[ConversationState]:
    """Load pending state; treat missing/corrupt/expired as empty (graceful)."""
    try:
        raw = cache_get(state_key(user_id, session_id))
    except Exception as exc:
        logger.warning("RemiVox state cache get failed: %s", exc)
        return None
    if raw is None:
        return None
    state = ConversationState.from_cache_dict(raw)
    if state is None:
        clear_state(user_id, session_id)
        return None
    if state.is_expired():
        clear_state(user_id, session_id)
        return None
    return state


def save_state(state: ConversationState) -> None:
    state.updated_at = datetime.now(timezone.utc)
    try:
        cache_set(
            state_key(state.user_id, state.session_id),
            state.to_cache_dict(),
            DEFAULT_STATE_TTL_SECONDS,
        )
    except Exception as exc:
        logger.warning("RemiVox state cache set failed: %s", exc)


def clear_state(user_id: str, session_id: str) -> None:
    try:
        cache_invalidate(state_key(user_id, session_id))
    except Exception as exc:
        logger.warning("RemiVox state cache invalidate failed: %s", exc)


def upsert_pending(
    *,
    user_id: str,
    session_id: str,
    language: str,
    detected_language: Optional[str],
    pending_intent: Optional[str],
    pending_entities: Optional[dict[str, Any]],
    missing_slots: Optional[list[str]] = None,
) -> ConversationState:
    state = ConversationState(
        user_id=user_id,
        session_id=session_id,
        language=language,
        detected_language=detected_language or language,
        pending_intent=pending_intent,
        pending_entities=dict(pending_entities or {}),
        missing_slots=list(missing_slots or []),
    )
    save_state(state)
    return state

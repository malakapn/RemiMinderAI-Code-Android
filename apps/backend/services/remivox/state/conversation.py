"""
Temporary conversation state for multi-turn Vox slots.

Key: remivox:state:{user_uuid}:{session_id}
TTL: 5 minutes (in-process stub — no Redis / Cloud SQL in Stage C).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Optional

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


_STATE: dict[str, ConversationState] = {}


def _key(user_id: str, session_id: str) -> str:
    return f"remivox:state:{user_id}:{session_id}"


def get_state(user_id: str, session_id: str) -> Optional[ConversationState]:
    state = _STATE.get(_key(user_id, session_id))
    if state is None:
        return None
    if state.is_expired():
        clear_state(user_id, session_id)
        return None
    return state


def save_state(state: ConversationState) -> None:
    state.updated_at = datetime.now(timezone.utc)
    _STATE[_key(state.user_id, state.session_id)] = state


def clear_state(user_id: str, session_id: str) -> None:
    _STATE.pop(_key(user_id, session_id), None)


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

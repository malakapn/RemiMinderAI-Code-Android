"""
Temporary conversation state for multi-turn Vox slots (Stage A stub).

Example pending create:
{
  user_id,
  pending_intent: "CREATE_REMINDER",
  pending_entities: { medication: "Vitamin D" },
  language: "en"
}

Stage D will persist via cache_service with TTL and merge follow-ups ("8 PM").
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
    pending_intent: Optional[str] = None
    pending_entities: dict[str, Any] = field(default_factory=dict)
    updated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def is_expired(self, ttl_seconds: int = DEFAULT_STATE_TTL_SECONDS) -> bool:
        age = (datetime.now(timezone.utc) - self.updated_at).total_seconds()
        return age > ttl_seconds


# Process-local placeholder store (not used in production Stage A).
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

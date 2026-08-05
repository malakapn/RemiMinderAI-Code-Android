"""
Action Executor (Stage A stub).

Protected care actions MUST go through:
  Intent Router → Action Executor → reminder_service / DB

Hydra must never call these side effects directly.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Optional

from services.remivox.intents.models import IntentResult, PROTECTED_ACTIONS, VoxIntent


@dataclass
class ActionResult:
    success: bool
    action: str
    message_key: str
    payload: dict[str, Any] = field(default_factory=dict)
    error: Optional[str] = None


async def execute_intent(
    *,
    intent_result: IntentResult,
    user_uuid: str,
    reminders: dict,
    summaries: list[dict],
    timezone_name: str = "UTC",
) -> ActionResult:
    """
    Execute a structured intent against backend services.

    Stage A: no-op stub. Stage C wires create/update/complete/snooze/skip/read.
    """
    _ = (user_uuid, reminders, summaries, timezone_name)
    intent = intent_result.intent
    if intent in PROTECTED_ACTIONS:
        return ActionResult(
            success=False,
            action=intent.value,
            message_key="not_implemented_stage_a",
            payload={"entities": intent_result.entities},
            error="Action Executor not wired in Stage A",
        )
    if intent == VoxIntent.UNKNOWN:
        return ActionResult(
            success=False,
            action=intent.value,
            message_key="unknown_intent",
            error="Unknown intent",
        )
    return ActionResult(
        success=False,
        action=intent.value,
        message_key="not_implemented_stage_a",
        error="Action Executor not wired in Stage A",
    )

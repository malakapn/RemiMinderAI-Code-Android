"""Shared ActionResult type (no heavy service imports)."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Optional


@dataclass
class ActionResult:
    success: bool
    action: str
    message_key: str
    payload: dict[str, Any] = field(default_factory=dict)
    error: Optional[str] = None
    pending_intent: Optional[str] = None
    pending_entities: Optional[dict[str, Any]] = None
    missing_slots: list[str] = field(default_factory=list)
    clear_pending: bool = False

"""
RemiVox v2 — backend-controlled, deterministic care assistant package.

Stage A (scaffold only): models, package layout, stubs, and docs.
Production traffic still flows through route/remivox.py and
services/remivox_intents.py until Stage B+ wiring is approved.

Layers:
  Voice      → voice.py
  Intent     → intents/
  Action     → actions/
  Response   → response/
  State      → state/
  Pipeline   → pipeline.py
"""

from services.remivox.intents.models import (
    PROTECTED_ACTIONS,
    SUPPORTED_VOX_LANGUAGES,
    CancelActionEntities,
    ClarifyingEntities,
    CompleteReminderEntities,
    ConfirmActionEntities,
    CreateReminderEntities,
    IntentResult,
    SkipReminderEntities,
    SnoozeReminderEntities,
    UpdateReminderEntities,
    VoxIntent,
    VoxRecurrence,
)

__all__ = [
    "PROTECTED_ACTIONS",
    "SUPPORTED_VOX_LANGUAGES",
    "CancelActionEntities",
    "ClarifyingEntities",
    "CompleteReminderEntities",
    "ConfirmActionEntities",
    "CreateReminderEntities",
    "IntentResult",
    "SkipReminderEntities",
    "SnoozeReminderEntities",
    "UpdateReminderEntities",
    "VoxIntent",
    "VoxRecurrence",
]

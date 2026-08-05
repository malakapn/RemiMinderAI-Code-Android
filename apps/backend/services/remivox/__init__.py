"""
RemiVox v2 — backend-controlled, deterministic care assistant package.

Production care path (Stage E):
  route/remivox.py → remivox.pipeline.run_care_turn
  → Intent Router → Action Executor → Reminder Service → Response Builder

Hydra remains conversational only (never merged into the care pipeline).
Legacy handle_prompt lives under remivox.legacy for rollback only.

Layers:
  Voice      → voice.py
  Intent     → intents/
  Action     → actions/
  Response   → response/
  State      → state/
  Pipeline   → pipeline.py
  Legacy     → legacy/ (retired from production routes)
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

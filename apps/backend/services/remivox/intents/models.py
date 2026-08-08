"""
RemiVox v2 structured intent models (Pydantic).

These models are the contract between Intent Router → Action Executor.
Stage A: definitions only — no production wiring.
"""

from __future__ import annotations

from enum import Enum
from typing import Any, Optional, Union

from pydantic import BaseModel, Field

from services.remivox.languages import (
    DEFAULT_REMIVOX_LANGUAGE,
    SUPPORTED_LANGUAGE_CODES,
)

class VoxIntent(str, Enum):
    """Deterministic care / conversation intents for RemiVox v2."""

    CREATE_REMINDER = "CREATE_REMINDER"
    UPDATE_REMINDER = "UPDATE_REMINDER"
    COMPLETE_REMINDER = "COMPLETE_REMINDER"
    SNOOZE_REMINDER = "SNOOZE_REMINDER"
    SKIP_REMINDER = "SKIP_REMINDER"
    DELETE_REMINDER = "DELETE_REMINDER"
    CANCEL_ACTION = "CANCEL_ACTION"
    CONFIRM_ACTION = "CONFIRM_ACTION"
    READ_TODAY_MEDICATIONS = "READ_TODAY_MEDICATIONS"
    READ_APPOINTMENTS = "READ_APPOINTMENTS"
    READ_DOCTOR_SUMMARY = "READ_DOCTOR_SUMMARY"
    CAREGIVER_BRIEF = "CAREGIVER_BRIEF"
    HELP = "HELP"
    CLARIFY = "CLARIFY"
    MEDICAL_ADVICE_REFUSAL = "MEDICAL_ADVICE_REFUSAL"
    UNKNOWN = "UNKNOWN"


class VoxRecurrence(str, Enum):
    """Recurrence values aligned with ReminderCreate.recurrence."""

    DAILY = "daily"
    WEEKLY = "weekly"
    ONCE = "once"
    TWICE = "twice"


# Care mutations must never be executed by Hydra directly.
PROTECTED_ACTIONS: frozenset[VoxIntent] = frozenset(
    {
        VoxIntent.CREATE_REMINDER,
        VoxIntent.UPDATE_REMINDER,
        VoxIntent.COMPLETE_REMINDER,
        VoxIntent.SNOOZE_REMINDER,
        VoxIntent.SKIP_REMINDER,
        VoxIntent.DELETE_REMINDER,
    }
)

SUPPORTED_VOX_LANGUAGES: frozenset[str] = frozenset(
    SUPPORTED_LANGUAGE_CODES
)


class CreateReminderEntities(BaseModel):
    """
    Entities for CREATE_REMINDER.

    Example utterance: "Set a reminder for Metoprolol at 8 PM every day"
    → medication=Metoprolol, time=20:00, frequency=daily
    """

    medication: Optional[str] = Field(
        default=None,
        description="Medication or reminder title (e.g. Metoprolol).",
    )
    title: Optional[str] = Field(
        default=None,
        description="Optional explicit title override; defaults to medication.",
    )
    time: Optional[str] = Field(
        default=None,
        description="Local time as HH:MM 24-hour (e.g. 20:00).",
        pattern=r"^([01]\d|2[0-3]):[0-5]\d$",
    )
    frequency: Optional[VoxRecurrence] = Field(
        default=None,
        description="Recurrence: daily | weekly | once | twice.",
    )
    reminder_type: Optional[str] = Field(
        default="medication",
        description="medication | task | appointment",
    )


class UpdateReminderEntities(BaseModel):
    title_hint: Optional[str] = None
    medication: Optional[str] = None
    time: Optional[str] = Field(
        default=None,
        pattern=r"^([01]\d|2[0-3]):[0-5]\d$",
    )
    frequency: Optional[VoxRecurrence] = None
    reminder_id: Optional[str] = None


class CompleteReminderEntities(BaseModel):
    title_hint: Optional[str] = None
    medication: Optional[str] = None
    reminder_id: Optional[str] = None


class SnoozeReminderEntities(BaseModel):
    title_hint: Optional[str] = None
    medication: Optional[str] = None
    minutes: Optional[int] = Field(default=20, ge=5, le=180)
    reminder_id: Optional[str] = None


class SkipReminderEntities(BaseModel):
    title_hint: Optional[str] = None
    medication: Optional[str] = None
    reminder_id: Optional[str] = None


class DeleteReminderEntities(BaseModel):
    title_hint: Optional[str] = None
    medication: Optional[str] = None
    reminder_id: Optional[str] = None


class CancelActionEntities(BaseModel):
    """Cancel a pending Vox clarification / confirmation (not Hydra-guessed)."""

    reason: Optional[str] = None


class ConfirmActionEntities(BaseModel):
    """Confirm a pending sensitive action (e.g. delete)."""

    confirmed: bool = True


class ClarifyingEntities(BaseModel):
    """CLARIFY: ask only for missing slots while preserving pending entities."""

    pending_intent: VoxIntent
    pending_entities: dict[str, Any] = Field(default_factory=dict)
    missing_slots: list[str] = Field(default_factory=list)


class ReadEntities(BaseModel):
    """Placeholder for read-only intents (meds / appointments / summary / brief)."""

    query_hint: Optional[str] = None


EntityPayload = Union[
    CreateReminderEntities,
    UpdateReminderEntities,
    CompleteReminderEntities,
    SnoozeReminderEntities,
    SkipReminderEntities,
    DeleteReminderEntities,
    CancelActionEntities,
    ConfirmActionEntities,
    ClarifyingEntities,
    ReadEntities,
    dict[str, Any],
]


class IntentResult(BaseModel):
    """
    Structured output of the Intent Layer.

    Example:
    {
      "intent": "CREATE_REMINDER",
      "language": "en",
      "entities": {
        "medication": "Metoprolol",
        "time": "20:00",
        "frequency": "daily"
      }
    }
    """

    intent: VoxIntent
    language: str = Field(
        default=DEFAULT_REMIVOX_LANGUAGE,
        description="BCP-47-ish primary language code from session / STT.",
    )
    entities: dict[str, Any] = Field(default_factory=dict)
    confidence: float = Field(default=1.0, ge=0.0, le=1.0)
    missing_slots: list[str] = Field(default_factory=list)
    raw_transcript: Optional[str] = None
    normalized_text: Optional[str] = Field(
        default=None,
        description="English (or normalized) text used for intent matching.",
    )

    def is_protected(self) -> bool:
        return self.intent in PROTECTED_ACTIONS

    def requires_clarification(self) -> bool:
        return self.intent == VoxIntent.CLARIFY or bool(self.missing_slots)

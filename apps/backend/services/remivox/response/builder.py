"""
Response Builder (Stage A stub).

Personality: friendly neighbor helping organize care.
Disclaimer only for MEDICAL_ADVICE_REFUSAL — not routine care actions.
Preserve the user's session language in every reply (Stage E/F wiring).
"""

from __future__ import annotations

from typing import Any, Optional

from services.remivox.actions.executor import ActionResult
from services.remivox.intents.models import IntentResult, VoxIntent

# Routine intents must NOT append medical disclaimers.
NO_DISCLAIMER_INTENTS: frozenset[VoxIntent] = frozenset(
    {
        VoxIntent.CREATE_REMINDER,
        VoxIntent.UPDATE_REMINDER,
        VoxIntent.COMPLETE_REMINDER,
        VoxIntent.SNOOZE_REMINDER,
        VoxIntent.SKIP_REMINDER,
        VoxIntent.DELETE_REMINDER,
        VoxIntent.CANCEL_ACTION,
        VoxIntent.CONFIRM_ACTION,
        VoxIntent.READ_TODAY_MEDICATIONS,
        VoxIntent.READ_APPOINTMENTS,
        VoxIntent.READ_DOCTOR_SUMMARY,
        VoxIntent.CAREGIVER_BRIEF,
        VoxIntent.HELP,
        VoxIntent.CLARIFY,
        VoxIntent.UNKNOWN,
    }
)


def build_response(
    *,
    intent_result: IntentResult,
    action_result: Optional[ActionResult] = None,
    reply_language: str = "en",
) -> dict[str, Any]:
    """
    Build a spoken/text reply dict: {text, include_disclaimer, language}.

    Stage A: placeholder English string only.
    """
    include_disclaimer = intent_result.intent == VoxIntent.MEDICAL_ADVICE_REFUSAL
    text = (
        "RemiVox v2 Response Builder is not wired yet. "
        "Production replies still come from remivox_intents.handle_prompt."
    )
    if include_disclaimer:
        text += (
            " This is not medical advice. Please ask your clinician about "
            "diagnosis, dosing, or treatment changes."
        )
    _ = action_result
    return {
        "text": text,
        "language": reply_language,
        "include_disclaimer": include_disclaimer,
        "intent": intent_result.intent.value,
    }

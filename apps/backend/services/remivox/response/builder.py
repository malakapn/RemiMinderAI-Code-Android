"""
Response Builder (Stage C).

Personality: friendly neighbor helping organize care.
Disclaimer only for MEDICAL_ADVICE_REFUSAL.
"""

from __future__ import annotations

from typing import Any, Optional

from services.remivox.actions.types import ActionResult
from services.remivox.intents.models import IntentResult, VoxIntent
from services.remivox.languages import DEFAULT_REMIVOX_LANGUAGE

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

_SLOT_PROMPTS = {
    "medication": "What should I call this reminder — for example, Metoprolol or Vitamin D?",
    "time": "What time should I set it for?",
    "frequency": "How often — every day, weekly, or just once?",
    "reminder": "Which reminder did you mean?",
    "confirmation": "Just to be sure — should I go ahead?",
}


def _join_names(names: list[str]) -> str:
    clean = [n for n in names if n]
    if not clean:
        return ""
    if len(clean) == 1:
        return clean[0]
    if len(clean) == 2:
        return f"{clean[0]} and {clean[1]}"
    return ", ".join(clean[:-1]) + f", and {clean[-1]}"


def build_response(
    *,
    intent_result: IntentResult,
    action_result: Optional[ActionResult] = None,
    reply_language: str = DEFAULT_REMIVOX_LANGUAGE,
) -> dict[str, Any]:
    """Build spoken/text reply: {text, include_disclaimer, language, intent}."""
    intent = intent_result.intent
    include_disclaimer = intent == VoxIntent.MEDICAL_ADVICE_REFUSAL
    action = action_result or ActionResult(
        success=False,
        action="none",
        message_key="empty",
    )
    key = action.message_key
    payload = action.payload or {}

    text = _text_for(key, intent, payload, action)

    if include_disclaimer and "not medical advice" not in text.lower():
        text = (
            f"{text} I'm not a doctor and can't advise on diagnosis, dosing, "
            "stopping medicines, or treatment — please check with your clinician."
        )

    return {
        "text": text.strip(),
        "language": reply_language,
        "include_disclaimer": include_disclaimer,
        "intent": intent.value,
        "action": action.action,
        "success": action.success,
    }


def _text_for(
    key: str,
    intent: VoxIntent,
    payload: dict[str, Any],
    action: ActionResult,
) -> str:
    if key == "clarify_missing_slots":
        missing = payload.get("missing_slots") or action.missing_slots or []
        pending = payload.get("pending_entities") or action.pending_entities or {}
        med = pending.get("medication") or pending.get("title")
        if missing == ["time"] and med:
            return f"I can set a reminder for {med} — what time works for you?"
        if missing == ["frequency"] and med:
            return (
                f"Got it for {med}. Should that be every day, weekly, or just once?"
            )
        if missing == ["medication"]:
            return _SLOT_PROMPTS["medication"]
        parts = [_SLOT_PROMPTS.get(m, m) for m in missing]
        if med:
            return f"Almost there for {med}. " + " ".join(parts)
        return " ".join(parts) or "Could you share a bit more detail?"

    if key == "cancelled":
        return "Okay — I cancelled that. What else can I help with?"

    if key == "confirm_nothing_pending":
        return "I don't have anything waiting for confirmation right now."

    if key == "created":
        title = payload.get("title", "your reminder")
        time = payload.get("time", "")
        freq = payload.get("frequency", "once")
        freq_phrase = {
            "daily": "every day",
            "weekly": "every week",
            "twice": "twice a day",
            "once": "once",
        }.get(str(freq), str(freq))
        when = f" at {time}" if time else ""
        return f"All set — I'll remind you about {title}{when}, {freq_phrase}."

    if key == "create_failed":
        return "I couldn't save that reminder just now. Want to try again in a moment?"

    if key == "updated":
        title = payload.get("title", "your reminder")
        return f"Updated — your {title} reminder is all set."

    if key == "update_failed":
        return "I found it, but couldn't update it right now. Want to try again?"

    if key == "ambiguous_reminder":
        names = _join_names(list(payload.get("candidates") or []))
        if names:
            return f"I found a few that might match: {names}. Which one did you mean?"
        return "I found more than one reminder that could match. Which one should I use?"

    if key == "no_match":
        return "I couldn't find a matching reminder. Want to tell me the name again?"

    if key == "ask_which_reminder":
        names = _join_names(list(payload.get("candidates") or []))
        if names:
            return f"Which reminder should I remove — {names}?"
        return "Which reminder should I remove?"

    if key == "confirm_delete":
        title = payload.get("title", "that reminder")
        return f"Should I delete your {title} reminder?"

    if key == "deleted":
        title = payload.get("title", "that reminder")
        return f"Done — I removed your {title} reminder."

    if key == "delete_failed":
        return "I couldn't remove that reminder just now."

    if key == "completed":
        title = payload.get("title", "that reminder")
        return f"Got it — I logged {title} as taken."

    if key == "snoozed":
        title = payload.get("title", "that reminder")
        minutes = payload.get("minutes", 20)
        return f"Okay — I snoozed {title} for {minutes} minutes."

    if key == "skipped":
        title = payload.get("title", "that reminder")
        return f"Okay — I marked {title} as skipped."

    if key == "checkin_failed":
        title = payload.get("title", "that reminder")
        return f"I found {title}, but couldn't update it right now."

    if key == "read_meds":
        names = _join_names(list(payload.get("names") or []))
        if names:
            return f"Here are your medication reminders: {names}."
        return "I don't see medication reminders due right now."

    if key == "read_appointments":
        names = _join_names(list(payload.get("names") or []))
        if payload.get("found_labeled") and names:
            return f"Here are your appointments or visits: {names}."
        if names:
            return f"I don't see a labeled appointment, but coming up next: {names}."
        return "I don't see an upcoming appointment in your reminders."

    if key == "read_summary":
        summary = payload.get("summary") or ""
        title = payload.get("title") or "your latest visit"
        if summary:
            return f"From {title}: {summary}"
        return "I don't see a completed doctor visit summary yet."

    if key == "caregiver_brief":
        return payload.get("text") or "I don't see linked patients for a care brief yet."

    if key == "help":
        return (
            "I can set and update reminders, mark medicines taken, snooze or skip, "
            "read today's meds, appointments, or your latest visit summary, "
            "and share a quick caregiver brief. Just talk to me like a neighbor."
        )

    if key == "medical_advice_refusal":
        return (
            "I can't help with diagnosis, changing doses, stopping medicines, "
            "or treatment advice. Please check with your clinician for that."
        )

    if key == "briefing":
        return payload.get("text") or "Hi — I'm Vox. How can I help organize your care today?"

    if intent == VoxIntent.UNKNOWN:
        return payload.get("text") or (
            "I'm not sure I caught that. You can ask me to set a reminder, "
            "mark a medicine taken, or read today's meds."
        )

    return "Okay — I'm here if you need help with your reminders."

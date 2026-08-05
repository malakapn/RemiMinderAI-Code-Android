"""
Legacy RemiVox handle_prompt (Stage E — retired from production routes).

Production care flow:
  Pulse STT → Intent Router → Action Executor → Reminder Service
  → Response Builder → Lightning TTS

Kept for rollback / regression tests only. Do not call from route/remivox.py.
"""

from __future__ import annotations

import logging
import re
from datetime import datetime, timedelta, timezone
from typing import Any, Optional
from zoneinfo import ZoneInfo

from schemas.reminder_schemas import ReminderAction, ReminderCreate
from services.reminder_service import (
    complete_reminder,
    create_new_reminder,
    skip_reminder,
    snooze_reminder,
)
from services.remivox_intents import (
    DISCLAIMER,
    _all_active,
    _items,
    _latest_summary_text,
    _missed,
    _reminder_title,
    build_briefing,
    build_caregiver_brief,
)
from services.remivox_languages import language_display_name, normalize_language_code

logger = logging.getLogger(__name__)

_WORD_TO_NUM = {
    "one": "1", "two": "2", "three": "3", "four": "4", "five": "5",
    "six": "6", "seven": "7", "eight": "8", "nine": "9", "ten": "10",
    "eleven": "11", "twelve": "12", "noon": "12", "midnight": "0",
}


def _normalize_number_words(text: str) -> str:
    result = text
    for word, digit in _WORD_TO_NUM.items():
        result = re.sub(r"\b" + word + r"\b", digit, result, flags=re.IGNORECASE)
    return result


_TIME_RE = re.compile(
    r"\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(a\.?m\.?|p\.?m\.?|am|pm)?\b",
    re.IGNORECASE,
)
_CREATE_RE = re.compile(
    r"(?:set(?:\s*up)?|create|add|schedule|make)\s+(?:a\s+)?(?:reminder\s+)?(?:for\s+)?"
    r"(?:me\s+to\s+(?:take\s+)?)?(?P<title>.+?)(?:\s+(?:every\s+day|everyday|daily|weekly|once)"
    r"|\s+at\s+\d|\s*$)",
    re.IGNORECASE,
)
_RECURRENCE_MAP = (
    (("every day", "everyday", "daily"), "daily"),
    (("weekly", "every week"), "weekly"),
    (("twice", "two times"), "twice"),
)


def _parse_recurrence(prompt: str) -> str:
    lower = prompt.lower()
    for needles, value in _RECURRENCE_MAP:
        if any(n in lower for n in needles):
            return value
    return "once"


def _parse_time_today(prompt: str, tz_name: str = "UTC") -> Optional[datetime]:
    normalized = _normalize_number_words(prompt)
    match = _TIME_RE.search(normalized)
    if not match:
        return None
    hour = int(match.group(1))
    minute = int(match.group(2) or 0)
    meridiem = (match.group(3) or "").lower().replace(".", "")
    if meridiem.startswith("p") and hour < 12:
        hour += 12
    if meridiem.startswith("a") and hour == 12:
        hour = 0
    if not meridiem and hour <= 7:
        hour += 12
    try:
        tz = ZoneInfo(tz_name)
    except Exception:
        tz = timezone.utc
    now = datetime.now(tz)
    scheduled = now.replace(hour=hour % 24, minute=minute, second=0, microsecond=0)
    if scheduled <= now:
        scheduled = scheduled + timedelta(days=1)
    return scheduled.astimezone(timezone.utc)


def _extract_create_title(prompt: str) -> Optional[str]:
    lower = prompt.lower()
    if not any(
        word in lower
        for word in ("set", "create", "add", "schedule", "remind me", "reminder for")
    ):
        return None
    match = _CREATE_RE.search(prompt)
    title = None
    if match:
        title = match.group("title")
    if not title:
        m2 = re.search(
            r"(?:reminder\s+for|remind\s+me\s+to\s+take|take)\s+(.+?)(?:\s+every|\s+daily|\s+at\s+\d|$)",
            prompt,
            re.IGNORECASE,
        )
        if m2:
            title = m2.group(1)
    if not title:
        return None
    title = re.sub(r"\b(every\s+day|everyday|daily|weekly|once|twice)\b", "", title, flags=re.I)
    title = _TIME_RE.sub("", title)
    title = re.sub(r"\s+", " ", title).strip(" .,")
    if len(title) < 2:
        return None
    return title[:80]


def _find_best_reminder(reminders: dict, prompt: str) -> Optional[dict]:
    active = _all_active(reminders) + _missed(reminders)
    if not active:
        return None
    lower = prompt.lower()
    scored: list[tuple[int, dict]] = []
    for item in active:
        title = _reminder_title(item).lower()
        score = 0
        for token in re.findall(r"[a-z0-9]{3,}", title):
            if token in lower:
                score += 2
        if str(item.get("display_status", "")).lower() == "due now":
            score += 1
        if str(item.get("reminder_type", "")).lower() == "medication":
            score += 1
        scored.append((score, item))
    scored.sort(key=lambda pair: pair[0], reverse=True)
    if scored and scored[0][0] > 0:
        return scored[0][1]
    today = _items(reminders.get("today"))
    meds = [
        i
        for i in today
        if "med" in str(i.get("reminder_type", "")).lower()
        or "med" in _reminder_title(i).lower()
    ]
    if meds:
        return meds[0]
    if today:
        return today[0]
    return active[0]


async def handle_prompt(
    *,
    prompt: str,
    user_uuid: str,
    reminders: dict,
    summaries: list[dict],
    timezone_name: str = "UTC",
    reply_language: str = "en",
) -> dict[str, Any]:
    """
    Legacy monolithic care handler.

    Retired from production routes in Stage E. Prefer remivox.pipeline.run_care_turn.
    """
    query = (prompt or "").strip()
    lower = query.lower()
    lang = normalize_language_code(reply_language)
    action: Optional[str] = None
    action_payload: dict[str, Any] = {}

    if any(
        phrase in lower
        for phrase in (
            "caregiver brief",
            "care brief",
            "who missed",
            "who is due",
            "who's due",
            "my patients",
            "patient status",
        )
    ):
        text = await build_caregiver_brief(user_uuid)
        return {
            "text": text,
            "action": "caregiver_brief",
            "action_payload": {},
            "reply_language": lang,
        }

    create_title = _extract_create_title(query)
    if create_title and any(
        w in lower for w in ("set", "create", "add", "schedule", "remind", "reminder")
    ):
        scheduled = _parse_time_today(query, timezone_name)
        if scheduled is None:
            text = (
                f"I can set a reminder for {create_title}, but I need a time. "
                f"Try saying: set a reminder for {create_title} every day at 8 pm. "
                + DISCLAIMER
            )
            return {
                "text": text,
                "action": "create_reminder_needs_time",
                "action_payload": {"title": create_title},
                "reply_language": lang,
            }
        recurrence = _parse_recurrence(query)
        reminder_type = "medication"
        if any(w in lower for w in ("appointment", "visit", "doctor")):
            reminder_type = "appointment"
        elif any(w in lower for w in ("task", "to do", "todo")):
            reminder_type = "task"
        try:
            created = await create_new_reminder(
                ReminderCreate(
                    user_id=user_uuid,
                    reminder_type=reminder_type,
                    title=create_title,
                    scheduled_time=scheduled,
                    timezone=timezone_name or "UTC",
                    recurrence=recurrence,  # type: ignore[arg-type]
                    context_data={"source": "remivox_legacy"},
                )
            )
            when = scheduled.astimezone(timezone.utc).strftime("%I:%M %p UTC").lstrip("0")
            if created:
                action = "create_reminder"
                action_payload = {
                    "reminder_id": str(created.get("id")),
                    "title": create_title,
                    "recurrence": recurrence,
                }
                text = (
                    f"Done. I set a {recurrence} reminder for {create_title} at {when}. "
                    + DISCLAIMER
                )
            else:
                text = "I could not save that reminder right now. Please try again from Reminders."
        except Exception as exc:
            logger.warning("Legacy Vox create reminder failed: %s", exc)
            text = "I could not save that reminder right now. Please try again from Reminders."
        return {
            "text": text,
            "action": action or "create_reminder_failed",
            "action_payload": action_payload,
            "reply_language": lang,
        }

    if any(
        w in lower
        for w in (
            "i took",
            "i've taken",
            "taken",
            "mark as taken",
            "mark taken",
            "completed",
            "done taking",
            "snooze",
            "remind me later",
            "skip",
            "skip it",
            "did you take",
            "check in",
            "check-in",
        )
    ):
        target = _find_best_reminder(reminders, query)
        if not target:
            text = "I do not see an active reminder to update right now. " + DISCLAIMER
            return {
                "text": text,
                "action": "checkin_none",
                "action_payload": {},
                "reply_language": lang,
            }
        rid = str(target.get("id"))
        title = _reminder_title(target)
        try:
            if any(w in lower for w in ("snooze", "later", "remind me later")):
                minutes = 20
                m = re.search(r"(\d{1,3})\s*(?:min|minute)", lower)
                if m:
                    minutes = max(5, min(180, int(m.group(1))))
                await snooze_reminder(rid, user_uuid, minutes)
                action = "snooze_reminder"
                action_payload = {"reminder_id": rid, "minutes": minutes, "title": title}
                text = f"Okay. I snoozed {title} for {minutes} minutes. " + DISCLAIMER
            elif re.search(r"\bskip\b", lower):
                await skip_reminder(rid, user_uuid, ReminderAction(notes="vox_skip"))
                action = "skip_reminder"
                action_payload = {"reminder_id": rid, "title": title}
                text = (
                    f"Okay. I marked {title} as skipped. "
                    "I am only logging your choice, not advising whether to take it. "
                    + DISCLAIMER
                )
            else:
                await complete_reminder(rid, user_uuid, ReminderAction(notes="vox_taken"))
                action = "complete_reminder"
                action_payload = {"reminder_id": rid, "title": title}
                text = (
                    f"Got it. I logged {title} as taken. "
                    "I am only recording your check-in, not giving medical advice. "
                    + DISCLAIMER
                )
        except Exception as exc:
            logger.warning("Legacy Vox check-in failed: %s", exc)
            text = f"I found {title}, but could not update it right now."
        return {
            "text": text,
            "action": action or "checkin_failed",
            "action_payload": action_payload,
            "reply_language": lang,
        }

    if any(
        word in lower
        for word in ("last doctor", "last visit", "summary", "doctor visit", "notes", "read my last")
    ):
        title, summary = _latest_summary_text(summaries)
        if summary:
            text = (
                f"Your latest visit summary from {title} says: {summary[:500]} {DISCLAIMER}"
            )
        else:
            text = "I do not see a completed doctor visit summary yet."
        return {
            "text": text,
            "action": "read_summary",
            "action_payload": {},
            "reply_language": lang,
        }

    if any(
        word in lower
        for word in ("appointment", "appt", "next visit", "schedule", "followup", "follow-up", "follow up")
    ):
        appts = [
            item
            for item in _all_active(reminders)
            if any(
                n in " ".join(
                    str(item.get(k, "")) for k in ("title", "message", "reminder_type", "type")
                ).lower()
                for n in ("appointment", "appt", "visit", "follow")
            )
        ]
        if appts:
            names = ", ".join(_reminder_title(item) for item in appts[:3])
            text = f"Here is what I found for appointments or visits: {names}. {DISCLAIMER}"
        else:
            upcoming = _items(reminders.get("upcoming"))
            if upcoming:
                names = ", ".join(_reminder_title(item) for item in upcoming[:3])
                text = (
                    "I do not see a specific appointment label, but your next upcoming "
                    f"reminders are: {names}. {DISCLAIMER}"
                )
            else:
                text = "I do not see an upcoming appointment in your reminders right now."
        return {
            "text": text,
            "action": "list_appointments",
            "action_payload": {},
            "reply_language": lang,
        }

    if any(word in lower for word in ("med", "medicine", "medication", "pill", "take")):
        meds = [
            item
            for item in _all_active(reminders)
            if any(
                n in " ".join(
                    str(item.get(k, "")) for k in ("title", "message", "reminder_type", "type")
                ).lower()
                for n in ("med", "medicine", "medication", "pill")
            )
        ]
        if meds:
            names = ", ".join(_reminder_title(item) for item in meds[:3])
            text = (
                f"Here are the medication reminders I found: {names}. "
                "Please take medicines only as prescribed."
            )
        else:
            text = "I do not see medication reminders due right now."
        return {
            "text": text,
            "action": "list_meds",
            "action_payload": {},
            "reply_language": lang,
        }

    if any(word in lower for word in ("missed", "late", "forgot")):
        missed = _missed(reminders)
        if missed:
            names = ", ".join(_reminder_title(item) for item in missed[:3])
            text = f"You have missed reminders to review: {names}."
        else:
            text = "I do not see any missed reminders right now."
        return {
            "text": text,
            "action": "list_missed",
            "action_payload": {},
            "reply_language": lang,
        }

    if "task" in lower or "to do" in lower or "todo" in lower:
        tasks = [
            item
            for item in _all_active(reminders)
            if any(
                n in " ".join(
                    str(item.get(k, "")) for k in ("title", "message", "reminder_type", "type")
                ).lower()
                for n in ("task", "to do", "todo")
            )
        ]
        if tasks:
            names = ", ".join(_reminder_title(item) for item in tasks[:3])
            text = f"Here are your tasks: {names}."
        else:
            text = "I do not see any tasks due right now."
        return {
            "text": text,
            "action": "list_tasks",
            "action_payload": {},
            "reply_language": lang,
        }

    if "translate" in lower or "translation" in lower:
        target = lang
        for code, name in (
            ("bn", "bangla"),
            ("bn", "bengali"),
            ("hi", "hindi"),
            ("es", "spanish"),
            ("fr", "french"),
            ("pt", "portuguese"),
            ("de", "german"),
            ("ta", "tamil"),
            ("gu", "gujarati"),
            ("pa", "punjabi"),
            ("en", "english"),
        ):
            if name in lower:
                target = code
                break
        text = (
            f"Starting live translation between English and "
            f"{language_display_name(target)}. Speak naturally. "
            + DISCLAIMER
        )
        return {
            "text": text,
            "action": "start_live_translate",
            "action_payload": {"target_language": target},
            "reply_language": lang,
        }

    return {
        "text": build_briefing(reminders, summaries),
        "action": "briefing",
        "action_payload": {},
        "reply_language": lang,
    }

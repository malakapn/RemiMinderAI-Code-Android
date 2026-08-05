"""
Entity extractors for RemiVox v2 Intent Router (Stage C).

Deterministic NLP only — no LLM.
"""

from __future__ import annotations

import re
from typing import Any, Optional

from services.remivox.intents.models import VoxRecurrence

_WORD_TO_NUM = {
    "one": "1",
    "two": "2",
    "three": "3",
    "four": "4",
    "five": "5",
    "six": "6",
    "seven": "7",
    "eight": "8",
    "nine": "9",
    "ten": "10",
    "eleven": "11",
    "twelve": "12",
    "noon": "12",
    "midnight": "0",
}

_TIME_RE = re.compile(
    r"\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(a\.?m\.?|p\.?m\.?|am|pm)?\b",
    re.IGNORECASE,
)

_CREATE_RE = re.compile(
    r"(?:set(?:\s*up)?|create|add|schedule|make)\s+(?:another\s+|a\s+)?"
    r"(?:reminder\s+)?(?:for\s+)?"
    r"(?:me\s+to\s+(?:take\s+)?)?(?P<title>.+?)(?:\s+(?:every\s+day|everyday|daily|weekly|once)"
    r"|\s+monday|\s+all\s+days|\s+7\s+days|\s+at\s+\d|\s*$)",
    re.IGNORECASE,
)

_DAILY_PHRASES = (
    "every day",
    "everyday",
    "daily",
    "all days",
    "all day",
    "monday through sunday",
    "monday to sunday",
    "mon through sun",
    "7 days a week",
    "seven days a week",
    "every morning",
    "every evening",
    "every night",
)

_WEEKLY_PHRASES = ("weekly", "every week", "once a week")
_TWICE_PHRASES = ("twice", "two times", "twice a day", "two times a day")


def normalize_number_words(text: str) -> str:
    result = text
    for word, digit in _WORD_TO_NUM.items():
        result = re.sub(r"\b" + word + r"\b", digit, result, flags=re.IGNORECASE)
    return result


def extract_frequency(text: str) -> Optional[VoxRecurrence]:
    lower = (text or "").lower()
    if any(p in lower for p in _DAILY_PHRASES):
        return VoxRecurrence.DAILY
    if any(p in lower for p in _WEEKLY_PHRASES):
        return VoxRecurrence.WEEKLY
    if any(p in lower for p in _TWICE_PHRASES):
        return VoxRecurrence.TWICE
    if re.search(r"\bonce\b", lower):
        return VoxRecurrence.ONCE
    return None


def extract_time_hhmm(text: str) -> Optional[str]:
    """Extract local time as HH:MM 24-hour."""
    normalized = normalize_number_words(text or "")
    match = _TIME_RE.search(normalized)
    if not match:
        # Bare "8" / "8pm" already covered; try morning/evening cues without digit
        lower = normalized.lower()
        if "noon" in lower:
            return "12:00"
        if "midnight" in lower:
            return "00:00"
        return None

    hour = int(match.group(1))
    minute = int(match.group(2) or 0)
    meridiem = (match.group(3) or "").lower().replace(".", "")

    if meridiem.startswith("p") and hour < 12:
        hour += 12
    if meridiem.startswith("a") and hour == 12:
        hour = 0
    if not meridiem:
        lower = normalized.lower()
        if "morning" in lower and hour <= 11:
            pass
        elif "evening" in lower or "night" in lower:
            if hour < 12:
                hour += 12
        elif hour <= 7:
            # Med context bare early hours usually mean PM (e.g. "8" → 20:00).
            hour += 12

    hour = hour % 24
    minute = max(0, min(59, minute))
    return f"{hour:02d}:{minute:02d}"


def extract_medication_or_title(text: str) -> Optional[str]:
    prompt = (text or "").strip()
    if not prompt:
        return None

    match = _CREATE_RE.search(prompt)
    title = match.group("title") if match else None

    if not title:
        m2 = re.search(
            r"(?:reminder\s+for|remind\s+me\s+(?:about|to\s+take)|"
            r"mark\s+(?:my\s+)?|take|about|for)\s+(.+?)"
            r"(?:\s+every|\s+daily|\s+at\s+\d|\s+as\s+taken|\s+monday|$)",
            prompt,
            re.IGNORECASE,
        )
        if m2:
            title = m2.group(1)

    if not title:
        m3 = re.search(
            r"(?:set|create|add|schedule)\s+([A-Za-z][A-Za-z0-9 \-]{1,40}?)\s+reminder",
            prompt,
            re.IGNORECASE,
        )
        if m3:
            title = m3.group(1)

    if not title:
        m4 = re.search(
            r"(?:update|change|move|reschedule|edit|delete|remove|mark)\s+"
            r"(?:my\s+)?([A-Za-z][A-Za-z0-9 \-]{1,40}?)\s+reminder",
            prompt,
            re.IGNORECASE,
        )
        if m4:
            title = m4.group(1)

    if not title:
        return None

    title = re.sub(
        r"\b(every\s+day|everyday|daily|weekly|once|twice|another|a|the|"
        r"monday through sunday|all days|7 days a week)\b",
        "",
        title,
        flags=re.I,
    )
    title = _TIME_RE.sub("", title)
    title = re.sub(r"\breminders?\b", "", title, flags=re.I)
    title = re.sub(r"\s+", " ", title).strip(" .,")
    # Drop leading filler
    title = re.sub(
        r"^(?:reminder\s+for|me\s+to\s+take|to\s+take|about)\s+",
        "",
        title,
        flags=re.I,
    ).strip(" .,")
    if len(title) < 2:
        return None
    return title[:80]


def reminder_title(item: dict) -> str:
    return (
        item.get("title")
        or item.get("message")
        or item.get("medication_name")
        or item.get("reminder_type")
        or "reminder"
    ).strip()


def _items(bucket: Any) -> list[dict]:
    if not isinstance(bucket, list):
        return []
    return [item for item in bucket if isinstance(item, dict)]


def all_active_reminders(reminders: dict) -> list[dict]:
    return _items(reminders.get("today")) + _items(reminders.get("upcoming"))


def score_reminders(reminders: dict, hint: str) -> list[tuple[int, dict]]:
    """Return (score, item) pairs sorted high→low for active + missed."""
    past = _items(reminders.get("past"))
    missed = [
        item
        for item in past
        if str(item.get("status", "")).strip().lower() == "missed"
        or str(item.get("display_status", "")).strip().lower() == "missed"
    ]
    active = all_active_reminders(reminders) + missed
    lower = (hint or "").lower()
    scored: list[tuple[int, dict]] = []
    for item in active:
        title = reminder_title(item).lower()
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
    return scored


def find_high_confidence_reminder(
    reminders: dict,
    hint: str,
    *,
    min_score: int = 2,
) -> tuple[Optional[dict], list[dict]]:
    """
    Return (best_match, ambiguous_candidates).

    High confidence: top score >= min_score and uniquely leading.
    Multiple equal high scores → ambiguous list.
    """
    scored = score_reminders(reminders, hint)
    if not scored:
        return None, []
    top = scored[0][0]
    if top < min_score:
        return None, []
    leaders = [item for score, item in scored if score == top]
    if len(leaders) == 1:
        return leaders[0], []
    return None, leaders

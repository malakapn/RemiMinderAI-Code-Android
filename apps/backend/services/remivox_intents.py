"""
RemiVox shared helpers: briefings + Hydra conversational tools (Stage E).

Care mutations for /api/remivox/ask go through remivox.pipeline.run_care_turn
(Intent Router → Action Executor → Reminder Service).

Legacy monolithic handle_prompt lives in services.remivox.legacy (rollback only).
"""

from __future__ import annotations

import logging
import warnings
from typing import Any, Optional

from services.reminder_service import list_patient_reminders
from services.remivox_languages import language_display_name

logger = logging.getLogger(__name__)

DISCLAIMER = (
    "This is not medical advice. Take medicines only as prescribed and ask a clinician "
    "if anything feels unclear."
)


def _items(bucket: Any) -> list[dict]:
    if not isinstance(bucket, list):
        return []
    return [item for item in bucket if isinstance(item, dict)]


def _reminder_title(item: dict) -> str:
    return (
        item.get("title")
        or item.get("message")
        or item.get("medication_name")
        or item.get("reminder_type")
        or "reminder"
    ).strip()


def _all_active(reminders: dict) -> list[dict]:
    return _items(reminders.get("today")) + _items(reminders.get("upcoming"))


def _missed(reminders: dict) -> list[dict]:
    past = _items(reminders.get("past"))
    return [
        item
        for item in past
        if str(item.get("status", "")).strip().lower() == "missed"
        or str(item.get("display_status", "")).strip().lower() == "missed"
    ]


def _latest_summary_text(summaries: list[dict]) -> tuple[str, str]:
    if not summaries:
        return "your latest doctor visit", ""
    latest = summaries[0]
    title = str(latest.get("title") or "your latest doctor visit").strip()
    summary = str(latest.get("summary") or latest.get("summary_text") or "").strip()
    return title, summary


def build_briefing(reminders: dict, summaries: list[dict]) -> str:
    today = _items(reminders.get("today"))
    upcoming = _items(reminders.get("upcoming"))
    missed = _missed(reminders)

    parts: list[str] = ["Hi, I'm Vox."]
    if today:
        names = ", ".join(_reminder_title(item) for item in today[:2])
        parts.append(
            f"Today you have {len(today)} reminder{'s' if len(today) != 1 else ''}: {names}."
        )
    elif upcoming:
        names = ", ".join(_reminder_title(item) for item in upcoming[:2])
        parts.append(f"You have no reminders due today. Next up: {names}.")
    else:
        parts.append("You do not have any reminders scheduled for today.")

    if missed:
        parts.append(
            f"You have {len(missed)} missed reminder{'s' if len(missed) != 1 else ''} to review."
        )

    if summaries:
        title, summary = _latest_summary_text(summaries)
        if summary:
            short = summary[:220].rstrip()
            parts.append(f"From {title}: {short}")

    parts.append(DISCLAIMER)
    return " ".join(parts)


async def build_caregiver_brief(user_uuid: str) -> str:
    try:
        from services.db_service import get_my_patients_for_caregiver

        patients = await get_my_patients_for_caregiver(user_uuid)
    except Exception as exc:
        logger.warning("caregiver brief patients failed: %s", exc)
        patients = []
    if not patients:
        return (
            "I do not see any linked patients for a caregiver brief yet. "
            + DISCLAIMER
        )

    lines = [f"Care brief for {len(patients)} patient{'s' if len(patients) != 1 else ''}."]
    for patient in patients[:4]:
        name = str(patient.get("full_name") or "Patient").strip()
        patient_id = str(patient.get("patient_id") or "").strip()
        due_soon = int(patient.get("reminders_due_soon") or 0)
        missed_count = int(patient.get("missed_reminders") or patient.get("missed_today") or 0)
        try:
            reminders = await list_patient_reminders(patient_id) if patient_id else {}
            missed = _missed(reminders)
            missed_count = max(missed_count, len(missed))
            due_names = ", ".join(_reminder_title(i) for i in _items(reminders.get("today"))[:2])
        except Exception:
            due_names = ""
        bit = f"{name}: {due_soon} due soon"
        if missed_count:
            bit += f", {missed_count} missed"
        if due_names:
            bit += f". Today: {due_names}"
        lines.append(bit + ".")
    lines.append(DISCLAIMER)
    return " ".join(lines)


async def handle_prompt(*args: Any, **kwargs: Any) -> dict[str, Any]:
    """
    Deprecated Stage E shim — production must use remivox.pipeline.run_care_turn.

    Delegates to services.remivox.legacy.handle_prompt for rollback only.
    """
    warnings.warn(
        "remivox_intents.handle_prompt is deprecated; use remivox.pipeline.run_care_turn",
        DeprecationWarning,
        stacklevel=2,
    )
    from services.remivox.legacy.handle_prompt import handle_prompt as _legacy_handle_prompt

    return await _legacy_handle_prompt(*args, **kwargs)


def hydra_tool_schemas() -> list[dict]:
    """
    Conversational-only tools for Hydra.

    Protected care mutations (create/update/complete/snooze/skip/delete) are
    intentionally omitted — those must go through Intent Router → Action Executor.
    """
    return [
        {
            "type": "function",
            "name": "get_today_briefing",
            "description": "Return today's reminders and a short visit summary snippet.",
            "parameters": {"type": "object", "properties": {}},
        },
        {
            "type": "function",
            "name": "get_caregiver_brief",
            "description": "Return due/missed reminder status for linked patients (caregiver only).",
            "parameters": {"type": "object", "properties": {}},
        },
        {
            "type": "function",
            "name": "get_last_summary",
            "description": "Read the user's latest stored visit summary text.",
            "parameters": {"type": "object", "properties": {}},
        },
    ]


def build_hydra_instructions(
    *,
    source_language: str,
    target_language: str,
    mode: str = "assistant",
) -> str:
    src = language_display_name(source_language)
    tgt = language_display_name(target_language)
    if mode == "translate":
        return (
            f"You are Vox Live Translate for RemiMinder. You provide live spoken translation "
            f"between {src} and {tgt}. When the user speaks {src}, reply with a clear {tgt} "
            f"translation of what they said. When they speak {tgt}, reply in {src}. "
            "Keep replies to one or two short sentences. "
            "You are not a doctor. Do not diagnose, dose, or advise treatment. "
            "If asked for medical advice, say they should ask their clinician. "
            "Do not create, update, complete, snooze, skip, or delete reminders. "
            "For reminder actions, tell the user to use the main Vox button care flow."
        )
    return (
        "You are Vox, RemiMinder's conversational companion. Speak warmly in one or two short sentences. "
        "You may explain visit summaries, help prepare doctor questions, and support caregiver conversations "
        "using read-only tools. "
        "Never create, update, complete, snooze, skip, or delete reminders — those are handled by the "
        "backend Intent Router, not by you. "
        "Never give medical advice, doses, or drug interaction guidance. "
        f"Prefer speaking in {tgt}."
    )


_HYDRA_PROTECTED_TOOLS = frozenset(
    {
        "create_reminder",
        "update_reminder",
        "complete_reminder",
        "snooze_reminder",
        "skip_reminder",
        "delete_reminder",
    }
)


async def execute_hydra_tool(
    *,
    name: str,
    arguments: dict[str, Any],
    user_uuid: str,
    reminders: dict,
    summaries: list[dict],
    timezone_name: str = "UTC",
) -> str:
    # Hard gate: Hydra must never execute protected care mutations.
    if name in _HYDRA_PROTECTED_TOOLS:
        logger.warning("Blocked Hydra protected tool call: %s uid=%s", name, user_uuid)
        return (
            "This care action is handled by RemiVox Intent Router, not Hydra. "
            "Ask the user to use the main Vox care flow for reminders."
        )
    if name == "get_today_briefing":
        return build_briefing(reminders, summaries)
    if name == "get_caregiver_brief":
        return await build_caregiver_brief(user_uuid)
    if name == "get_last_summary":
        title, summary = _latest_summary_text(summaries)
        if not summary:
            return "No completed doctor visit summary found."
        return f"{title}: {summary[:500]}"
    if name in {"create_reminder", "complete_reminder", "snooze_reminder", "skip_reminder"}:
        return (
            "Blocked: protected reminder actions cannot be executed by Hydra."
        )
    return f"Unknown tool: {name}"

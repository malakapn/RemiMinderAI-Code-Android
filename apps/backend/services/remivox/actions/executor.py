"""
Action Executor (Stage C).

Protected care actions: Intent → validate → reminder_service → DB.
Hydra must never call these side effects directly.
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Any, Optional
from zoneinfo import ZoneInfo

from schemas.reminder_schemas import ReminderAction, ReminderCreate, ReminderUpdate
from services.reminder_service import (
    cancel_reminder,
    complete_reminder,
    create_new_reminder,
    skip_reminder,
    snooze_reminder,
    update_reminder_details,
)
from services.remivox.actions.types import ActionResult
from services.remivox.intents.extractors import (
    all_active_reminders,
    find_high_confidence_reminder,
    reminder_title,
)
from services.remivox.intents.models import IntentResult, PROTECTED_ACTIONS, VoxIntent
from services.remivox_intents import build_briefing, build_caregiver_brief

logger = logging.getLogger(__name__)


def _scheduled_from_hhmm(time_hhmm: str, timezone_name: str) -> datetime:
    hour, minute = [int(x) for x in time_hhmm.split(":", 1)]
    try:
        tz = ZoneInfo(timezone_name)
    except Exception:
        tz = timezone.utc
    now = datetime.now(tz)
    scheduled = now.replace(hour=hour % 24, minute=minute % 60, second=0, microsecond=0)
    if scheduled <= now:
        scheduled += timedelta(days=1)
    return scheduled.astimezone(timezone.utc)


def _latest_summary(summaries: list[dict]) -> tuple[str, str]:
    if not summaries:
        return "your latest doctor visit", ""
    latest = summaries[0]
    title = str(latest.get("title") or "your latest doctor visit").strip()
    summary = str(latest.get("summary") or latest.get("summary_text") or "").strip()
    return title, summary


async def execute_intent(
    *,
    intent_result: IntentResult,
    user_uuid: str,
    reminders: dict,
    summaries: list[dict],
    timezone_name: str = "UTC",
) -> ActionResult:
    intent = intent_result.intent
    entities = dict(intent_result.entities or {})

    if intent == VoxIntent.CLARIFY:
        pending_intent = str(entities.get("pending_intent") or "")
        pending_entities = dict(entities.get("pending_entities") or {})
        missing = list(entities.get("missing_slots") or intent_result.missing_slots or [])
        return ActionResult(
            success=True,
            action="clarify",
            message_key="clarify_missing_slots",
            payload={"missing_slots": missing, "pending_entities": pending_entities},
            pending_intent=pending_intent or None,
            pending_entities=pending_entities,
            missing_slots=missing,
        )

    if intent == VoxIntent.CANCEL_ACTION:
        return ActionResult(
            success=True,
            action="cancel_action",
            message_key="cancelled",
            payload={},
            clear_pending=True,
        )

    if intent == VoxIntent.CONFIRM_ACTION:
        # Confirm only completes a pending DELETE (sensitive).
        rid = entities.get("reminder_id")
        title = entities.get("medication") or entities.get("title_hint") or "that reminder"
        if not rid:
            return ActionResult(
                success=False,
                action="confirm_action",
                message_key="confirm_nothing_pending",
                error="No pending delete to confirm",
                clear_pending=True,
            )
        ok = await cancel_reminder(str(rid), user_uuid)
        if not ok:
            return ActionResult(
                success=False,
                action="delete_reminder",
                message_key="delete_failed",
                error="cancel_reminder returned false",
                clear_pending=True,
            )
        return ActionResult(
            success=True,
            action="delete_reminder",
            message_key="deleted",
            payload={"reminder_id": str(rid), "title": title},
            clear_pending=True,
        )

    if intent == VoxIntent.CREATE_REMINDER:
        return await _create_reminder(entities, user_uuid, timezone_name)

    if intent == VoxIntent.UPDATE_REMINDER:
        return await _update_reminder(entities, user_uuid, reminders, timezone_name)

    if intent == VoxIntent.COMPLETE_REMINDER:
        return await _checkin(entities, user_uuid, reminders, mode="complete")

    if intent == VoxIntent.SNOOZE_REMINDER:
        return await _checkin(entities, user_uuid, reminders, mode="snooze")

    if intent == VoxIntent.SKIP_REMINDER:
        return await _checkin(entities, user_uuid, reminders, mode="skip")

    if intent == VoxIntent.DELETE_REMINDER:
        return await _delete_reminder_flow(entities, reminders)

    if intent == VoxIntent.READ_TODAY_MEDICATIONS:
        typed = [
            i
            for i in all_active_reminders(reminders)
            if "med" in str(i.get("reminder_type", "")).lower()
            or "med" in reminder_title(i).lower()
        ]
        use = typed or list(reminders.get("today") or [])
        names = [reminder_title(i) for i in use[:5]]
        return ActionResult(
            success=True,
            action="read_today_medications",
            message_key="read_meds",
            payload={"names": names},
        )

    if intent == VoxIntent.READ_APPOINTMENTS:
        appts = [
            item
            for item in all_active_reminders(reminders)
            if any(
                n in " ".join(
                    str(item.get(k, "")) for k in ("title", "message", "reminder_type", "type")
                ).lower()
                for n in ("appointment", "appt", "visit", "follow")
            )
        ]
        names = [reminder_title(i) for i in (appts or all_active_reminders(reminders))[:3]]
        return ActionResult(
            success=True,
            action="read_appointments",
            message_key="read_appointments",
            payload={"names": names, "found_labeled": bool(appts)},
        )

    if intent == VoxIntent.READ_DOCTOR_SUMMARY:
        title, summary = _latest_summary(summaries)
        return ActionResult(
            success=True,
            action="read_summary",
            message_key="read_summary",
            payload={"title": title, "summary": summary[:500] if summary else ""},
        )

    if intent == VoxIntent.CAREGIVER_BRIEF:
        text = await build_caregiver_brief(user_uuid)
        # Strip legacy disclaimer suffix if present for Stage C personality.
        text = text.replace(
            "This is not medical advice. Take medicines only as prescribed and ask a clinician "
            "if anything feels unclear.",
            "",
        ).strip()
        return ActionResult(
            success=True,
            action="caregiver_brief",
            message_key="caregiver_brief",
            payload={"text": text},
        )

    if intent == VoxIntent.HELP:
        return ActionResult(
            success=True,
            action="help",
            message_key="help",
            payload={},
        )

    if intent == VoxIntent.MEDICAL_ADVICE_REFUSAL:
        return ActionResult(
            success=True,
            action="medical_advice_refusal",
            message_key="medical_advice_refusal",
            payload={},
        )

    if intent == VoxIntent.UNKNOWN:
        briefing = build_briefing(reminders, summaries)
        briefing = briefing.replace(
            "This is not medical advice. Take medicines only as prescribed and ask a clinician "
            "if anything feels unclear.",
            "",
        ).strip()
        return ActionResult(
            success=True,
            action="briefing",
            message_key="briefing",
            payload={"text": briefing},
        )

    if intent in PROTECTED_ACTIONS:
        return ActionResult(
            success=False,
            action=intent.value,
            message_key="unsupported_protected",
            error=f"Protected action not implemented: {intent.value}",
        )

    return ActionResult(
        success=False,
        action=intent.value,
        message_key="unknown_intent",
        error="Unhandled intent",
    )


async def _create_reminder(
    entities: dict[str, Any],
    user_uuid: str,
    timezone_name: str,
) -> ActionResult:
    title = (entities.get("title") or entities.get("medication") or "").strip()
    time_hhmm = entities.get("time")
    frequency = entities.get("frequency") or "once"
    reminder_type = entities.get("reminder_type") or "medication"
    if not title or not time_hhmm:
        missing = []
        if not title:
            missing.append("medication")
        if not time_hhmm:
            missing.append("time")
        if not entities.get("frequency"):
            missing.append("frequency")
        return ActionResult(
            success=False,
            action="create_reminder",
            message_key="clarify_missing_slots",
            pending_intent=VoxIntent.CREATE_REMINDER.value,
            pending_entities=entities,
            missing_slots=missing,
            error="missing_slots",
        )
    try:
        scheduled = _scheduled_from_hhmm(str(time_hhmm), timezone_name)
        created = await create_new_reminder(
            ReminderCreate(
                user_id=user_uuid,
                reminder_type=reminder_type,  # type: ignore[arg-type]
                title=title[:80],
                scheduled_time=scheduled,
                timezone=timezone_name or "UTC",
                recurrence=frequency,  # type: ignore[arg-type]
                context_data={"source": "remivox_v2"},
            )
        )
        if not created:
            return ActionResult(
                success=False,
                action="create_reminder",
                message_key="create_failed",
                error="create_new_reminder returned None",
                clear_pending=True,
            )
        return ActionResult(
            success=True,
            action="create_reminder",
            message_key="created",
            payload={
                "reminder_id": str(created.get("id")),
                "title": title,
                "time": time_hhmm,
                "frequency": frequency,
            },
            clear_pending=True,
        )
    except Exception as exc:
        logger.warning("Vox v2 create reminder failed: %s", exc)
        return ActionResult(
            success=False,
            action="create_reminder",
            message_key="create_failed",
            error=str(exc),
            clear_pending=True,
        )


async def _update_reminder(
    entities: dict[str, Any],
    user_uuid: str,
    reminders: dict,
    timezone_name: str,
) -> ActionResult:
    hint = str(entities.get("title_hint") or entities.get("medication") or "")
    match, ambiguous = find_high_confidence_reminder(reminders, hint)
    if ambiguous:
        names = [reminder_title(i) for i in ambiguous[:4]]
        return ActionResult(
            success=False,
            action="update_reminder",
            message_key="ambiguous_reminder",
            payload={"candidates": names},
            pending_intent=VoxIntent.UPDATE_REMINDER.value,
            pending_entities=entities,
            missing_slots=["reminder"],
        )
    if not match:
        return ActionResult(
            success=False,
            action="update_reminder",
            message_key="no_match",
            error="No high-confidence reminder match",
            clear_pending=True,
        )

    rid = str(match.get("id"))
    updates: dict[str, Any] = {}
    if entities.get("time"):
        updates["scheduled_time"] = _scheduled_from_hhmm(str(entities["time"]), timezone_name)
    if entities.get("frequency"):
        updates["recurrence"] = entities["frequency"]
    if entities.get("title") and entities.get("title") != hint:
        updates["title"] = entities["title"]

    if not updates:
        return ActionResult(
            success=False,
            action="update_reminder",
            message_key="clarify_missing_slots",
            payload={"title": reminder_title(match)},
            pending_intent=VoxIntent.UPDATE_REMINDER.value,
            pending_entities={**entities, "reminder_id": rid, "title_hint": reminder_title(match)},
            missing_slots=["time"],
        )

    try:
        updated = await update_reminder_details(
            rid,
            user_uuid,
            ReminderUpdate(
                title=updates.get("title"),
                scheduled_time=updates.get("scheduled_time"),
                recurrence=updates.get("recurrence"),
            ),
        )
        return ActionResult(
            success=bool(updated),
            action="update_reminder",
            message_key="updated" if updated else "update_failed",
            payload={
                "reminder_id": rid,
                "title": reminder_title(match),
                "updates": {
                    k: (v.isoformat() if hasattr(v, "isoformat") else v)
                    for k, v in updates.items()
                },
            },
            clear_pending=True,
            error=None if updated else "update returned empty",
        )
    except Exception as exc:
        logger.warning("Vox v2 update reminder failed: %s", exc)
        return ActionResult(
            success=False,
            action="update_reminder",
            message_key="update_failed",
            error=str(exc),
            clear_pending=True,
        )


async def _checkin(
    entities: dict[str, Any],
    user_uuid: str,
    reminders: dict,
    *,
    mode: str,
) -> ActionResult:
    hint = str(entities.get("title_hint") or entities.get("medication") or "medication")
    match, ambiguous = find_high_confidence_reminder(reminders, hint, min_score=2)
    if ambiguous:
        return ActionResult(
            success=False,
            action=f"{mode}_reminder",
            message_key="ambiguous_reminder",
            payload={"candidates": [reminder_title(i) for i in ambiguous[:4]]},
        )
    if not match:
        # Soft fallback: first today item for taken/snooze/skip when no hint match
        today = list(reminders.get("today") or [])
        match = today[0] if today else None
    if not match:
        return ActionResult(
            success=False,
            action=f"{mode}_reminder",
            message_key="no_match",
            error="No active reminder found",
        )
    rid = str(match.get("id"))
    title = reminder_title(match)
    try:
        if mode == "snooze":
            minutes = int(entities.get("minutes") or 20)
            minutes = max(5, min(180, minutes))
            await snooze_reminder(rid, user_uuid, minutes)
            return ActionResult(
                success=True,
                action="snooze_reminder",
                message_key="snoozed",
                payload={"reminder_id": rid, "title": title, "minutes": minutes},
            )
        if mode == "skip":
            await skip_reminder(rid, user_uuid, ReminderAction(notes="vox_v2_skip"))
            return ActionResult(
                success=True,
                action="skip_reminder",
                message_key="skipped",
                payload={"reminder_id": rid, "title": title},
            )
        await complete_reminder(rid, user_uuid, ReminderAction(notes="vox_v2_taken"))
        return ActionResult(
            success=True,
            action="complete_reminder",
            message_key="completed",
            payload={"reminder_id": rid, "title": title},
        )
    except Exception as exc:
        logger.warning("Vox v2 check-in failed: %s", exc)
        return ActionResult(
            success=False,
            action=f"{mode}_reminder",
            message_key="checkin_failed",
            error=str(exc),
            payload={"title": title},
        )


async def _delete_reminder_flow(entities: dict[str, Any], reminders: dict) -> ActionResult:
    hint = str(entities.get("title_hint") or entities.get("medication") or "")
    if not hint.strip():
        names = [reminder_title(i) for i in all_active_reminders(reminders)[:4]]
        return ActionResult(
            success=False,
            action="delete_reminder",
            message_key="ask_which_reminder",
            payload={"candidates": names},
            pending_intent=VoxIntent.DELETE_REMINDER.value,
            pending_entities=entities,
            missing_slots=["reminder"],
        )

    match, ambiguous = find_high_confidence_reminder(reminders, hint)
    if ambiguous:
        return ActionResult(
            success=False,
            action="delete_reminder",
            message_key="ambiguous_reminder",
            payload={"candidates": [reminder_title(i) for i in ambiguous[:4]]},
            pending_intent=VoxIntent.DELETE_REMINDER.value,
            pending_entities=entities,
            missing_slots=["reminder"],
        )
    if not match:
        return ActionResult(
            success=False,
            action="delete_reminder",
            message_key="no_match",
            error="No matching reminder",
            clear_pending=True,
        )

    title = reminder_title(match)
    rid = str(match.get("id"))
    # Require CONFIRM_ACTION before cancel_reminder.
    return ActionResult(
        success=True,
        action="delete_reminder_confirm",
        message_key="confirm_delete",
        payload={"reminder_id": rid, "title": title},
        pending_intent=VoxIntent.DELETE_REMINDER.value,
        pending_entities={
            "reminder_id": rid,
            "medication": title,
            "title_hint": title,
        },
        missing_slots=["confirmation"],
    )

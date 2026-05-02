import logging
from datetime import date
from typing import Optional, Dict, Any, List

from .db_reminders import (
    caregiver_alert_exists_for_context,
    create_caregiver_alert,
    get_pending_reminders_past_grace,
    get_patient_fcm_token,
    get_reminder,
    get_patient_info,
)
from .notification_service import send_caregiver_alert_email

logger = logging.getLogger(__name__)


async def _push_fcm_to_caregiver(caregiver_id: str, title: str, body: str, alert_type: str) -> None:
    """Send FCM push notification to a caregiver device if they have a registered token."""
    try:
        from .reminder_service import send_fcm_notification
        fcm_token = await get_patient_fcm_token(caregiver_id)
        if fcm_token:
            await send_fcm_notification(
                fcm_token=fcm_token,
                title=title,
                body=body,
                data={"type": alert_type, "deep_link": "/caregiver/alerts"},
            )
    except Exception as e:
        logger.warning("FCM push to caregiver %s failed (non-fatal): %s", caregiver_id, e)


# ============================================================================
# CAREGIVER ALERT LOGIC
# ============================================================================


async def list_patient_caregivers_for_alerts(user_id: str) -> List[dict]:
    """
    All active care-team caregivers for this patient (Firebase UID + email).
    """
    from services.db_service import get_caregivers_for_patient_alerts

    rows = await get_caregivers_for_patient_alerts(user_id)
    out: List[dict] = []
    for row in rows:
        fid = row.get("caregiver_firebase_uid")
        if not fid:
            continue
        out.append(
            {
                "caregiver_id": str(fid),
                "email": (row.get("caregiver_email") or "").strip(),
                "full_name": row.get("caregiver_full_name") or "Caregiver",
            }
        )
    return out


async def check_and_send_caregiver_alerts(
    reminder_id: str,
    user_id: str,
    action: str
) -> None:
    """
    Check if caregiver should be alerted based on reminder action.
    Alerts when a patient skips a reminder (first skip and repeats).
    """
    try:
        reminder = await get_reminder(reminder_id, user_id)
        if not reminder:
            return

        consecutive_skips = int(reminder.get("consecutive_skips", 0) or 0)

        if action == "skipped" and consecutive_skips >= 1:
            await send_skip_alert_to_caregivers(reminder_id, user_id, consecutive_skips)

    except Exception as e:
        logger.error(f"Error checking caregiver alerts for reminder {reminder_id}: {str(e)}")


async def send_skip_alert_to_caregivers(
    reminder_id: str,
    user_id: str,
    skip_count: int
) -> None:
    """
    Send skip alert to every active care-team caregiver for this patient.
    """
    try:
        patient = await get_patient_info(user_id)
        if not patient:
            logger.error(f"Patient {user_id} not found for caregiver alert")
            return

        patient_name = patient.get('full_name', 'Your patient')

        reminder = await get_reminder(reminder_id, user_id)
        if not reminder:
            return

        reminder_title = reminder.get('title', 'A reminder')

        caregivers = await list_patient_caregivers_for_alerts(user_id)
        if not caregivers:
            logger.info(f"No caregivers assigned to patient {user_id}, skipping alert")
            return

        if skip_count > 1:
            alert_type = "multiple_skips"
            alert_message = (
                f"{patient_name} has skipped '{reminder_title}' {skip_count} times in a row. "
                f"Please check in with them to ensure they're staying on track with their health routine."
            )
        else:
            alert_type = "reminder_skipped"
            alert_message = (
                f"{patient_name} skipped the reminder '{reminder_title}'. "
                f"You may want to check in with them."
            )

        for cg in caregivers:
            caregiver_id = cg["caregiver_id"]
            caregiver_email = cg["email"]
            await create_caregiver_alert(
                caregiver_id=caregiver_id,
                user_id=user_id,
                reminder_id=reminder_id,
                alert_type=alert_type,
                message=alert_message,
            )
            await _push_fcm_to_caregiver(caregiver_id, f"Patient Alert", alert_message, alert_type)
            await send_caregiver_alert_email(
                to_email=caregiver_email,
                patient_name=patient_name,
                alert_message=alert_message,
                alert_id=reminder_id,
                caregiver_firebase_uid=caregiver_id,
            )

    except Exception as e:
        logger.error(f"Error sending caregiver alert: {str(e)}")


def _symptom_entries(structured_result: Optional[Dict[str, Any]]) -> List[Any]:
    if not structured_result or not isinstance(structured_result, dict):
        return []
    raw = structured_result.get("symptoms")
    if not isinstance(raw, list):
        return []
    return [x for x in raw if x]


async def notify_caregiver_new_visit_symptoms(
    user_id: str,
    visit_id: str,
    summary_id: str,
    structured_result: Optional[Dict[str, Any]],
) -> None:
    """
    After a visit AI summary is saved: alert each care-team caregiver when symptoms were extracted.
    Idempotent per summary_id per caregiver.
    """
    try:
        symptoms = _symptom_entries(structured_result)
        if not symptoms or not summary_id:
            return

        patient = await get_patient_info(user_id)
        if not patient:
            return
        patient_name = patient.get("full_name") or "Your patient"

        caregivers = await list_patient_caregivers_for_alerts(user_id)
        if not caregivers:
            return

        n = len(symptoms)
        alert_message = (
            f"{patient_name} has a new visit summary with {n} symptom entr"
            f"{'y' if n == 1 else 'ies'}."
        )

        for cg in caregivers:
            caregiver_id = cg["caregiver_id"]
            caregiver_email = cg["email"]
            if await caregiver_alert_exists_for_context(
                user_id, "symptom_journal_updated", summary_id, caregiver_id
            ):
                continue

            row = await create_caregiver_alert(
                caregiver_id=caregiver_id,
                user_id=user_id,
                reminder_id=None,
                alert_type="symptom_journal_updated",
                message=alert_message,
                context_id=summary_id,
            )
            if not row:
                continue

            await _push_fcm_to_caregiver(caregiver_id, "New Visit Summary", alert_message, "symptom_journal_updated")
            await send_caregiver_alert_email(
                to_email=caregiver_email,
                patient_name=patient_name,
                alert_message=alert_message,
                alert_id=summary_id,
                caregiver_firebase_uid=caregiver_id,
            )
    except Exception as e:
        logger.error(
            "notify_caregiver_new_visit_symptoms failed visit_id=%s summary_id=%s: %s",
            visit_id,
            summary_id,
            e,
        )


async def notify_caregivers_new_visit_recorded(
    user_id: str,
    visit_id: str,
) -> None:
    """
    Notify all active caregivers that a patient recorded a new visit.
    Idempotent per visit_id per caregiver.
    """
    try:
        if not visit_id:
            return

        patient = await get_patient_info(user_id)
        if not patient:
            return
        patient_name = patient.get("full_name") or "Your patient"

        caregivers = await list_patient_caregivers_for_alerts(user_id)
        if not caregivers:
            return

        alert_message = (
            f"{patient_name} recorded a new visit. "
            "Open the app to review updates."
        )

        for cg in caregivers:
            caregiver_id = cg["caregiver_id"]
            caregiver_email = cg["email"]
            ctx = f"visit_recorded:{visit_id}"
            if await caregiver_alert_exists_for_context(
                user_id, "visit_recorded", ctx, caregiver_id
            ):
                continue

            row = await create_caregiver_alert(
                caregiver_id=caregiver_id,
                user_id=user_id,
                reminder_id=None,
                alert_type="visit_recorded",
                message=alert_message,
                context_id=ctx,
            )
            if not row:
                continue

            await _push_fcm_to_caregiver(
                caregiver_id,
                "New Patient Visit",
                alert_message,
                "visit_recorded",
            )
            await send_caregiver_alert_email(
                to_email=caregiver_email,
                patient_name=patient_name,
                alert_message=alert_message,
                alert_id=visit_id,
                caregiver_firebase_uid=caregiver_id,
            )
    except Exception as e:
        logger.error(
            "notify_caregivers_new_visit_recorded failed user=%s visit=%s: %s",
            user_id,
            visit_id,
            e,
        )


async def notify_caregivers_reminder_created(
    user_id: str,
    reminder_id: str,
    reminder_title: str,
) -> None:
    """
    Notify caregivers when a patient creates a new reminder.
    """
    try:
        patient = await get_patient_info(user_id)
        if not patient:
            return
        patient_name = patient.get("full_name") or "Your patient"
        title = (reminder_title or "A reminder").strip() or "A reminder"
        caregivers = await list_patient_caregivers_for_alerts(user_id)
        if not caregivers:
            return
        alert_message = (
            f"{patient_name} added a new reminder: '{title}'. "
            "Open the app to see their schedule."
        )
        for cg in caregivers:
            caregiver_id = cg["caregiver_id"]
            caregiver_email = cg["email"]
            row = await create_caregiver_alert(
                caregiver_id=caregiver_id,
                user_id=user_id,
                reminder_id=reminder_id,
                alert_type="reminder_created",
                message=alert_message,
            )
            if not row:
                continue
            await _push_fcm_to_caregiver(caregiver_id, "New Patient Reminder", alert_message, "reminder_created")
            await send_caregiver_alert_email(
                to_email=caregiver_email,
                patient_name=patient_name,
                alert_message=alert_message,
                alert_id=reminder_id,
                caregiver_firebase_uid=caregiver_id,
            )
    except Exception as e:
        logger.error(
            "notify_caregivers_reminder_created failed user=%s reminder=%s: %s",
            user_id,
            reminder_id,
            e,
        )


async def notify_caregivers_patient_reminder_updated(
    user_id: str,
    reminder_id: str,
    reminder_title: str,
) -> None:
    """
    When a patient edits reminder fields, notify caregivers (at most once per caregiver per reminder per UTC day).
    """
    try:
        patient = await get_patient_info(user_id)
        if not patient:
            return
        patient_name = patient.get("full_name") or "Your patient"
        title = (reminder_title or "A reminder").strip() or "A reminder"
        day_key = date.today().isoformat()
        caregivers = await list_patient_caregivers_for_alerts(user_id)
        if not caregivers:
            return
        alert_message = (
            f"{patient_name} updated the reminder '{title}'. "
            "Open the app to see the latest schedule."
        )
        for cg in caregivers:
            caregiver_id = cg["caregiver_id"]
            caregiver_email = cg["email"]
            ctx = f"reminder_updated:{reminder_id}:{caregiver_id}:{day_key}"
            if await caregiver_alert_exists_for_context(
                user_id, "reminder_updated", ctx, caregiver_id
            ):
                continue
            row = await create_caregiver_alert(
                caregiver_id=caregiver_id,
                user_id=user_id,
                reminder_id=reminder_id,
                alert_type="reminder_updated",
                message=alert_message,
                context_id=ctx,
            )
            if not row:
                continue
            await _push_fcm_to_caregiver(caregiver_id, "Patient Reminder Updated", alert_message, "reminder_updated")
            await send_caregiver_alert_email(
                to_email=caregiver_email,
                patient_name=patient_name,
                alert_message=alert_message,
                alert_id=reminder_id,
                caregiver_firebase_uid=caregiver_id,
            )
    except Exception as e:
        logger.error(
            "notify_caregivers_patient_reminder_updated failed user=%s reminder=%s: %s",
            user_id,
            reminder_id,
            e,
        )


async def process_missed_reminder_caregiver_alerts() -> int:
    """
    Create caregiver alerts for pending reminders that are past due (one alert per reminder per caregiver).
    Intended to be run from a scheduled job (INTERNAL_CRON_SECRET).
    """
    created = 0
    try:
        rows = await get_pending_reminders_past_grace(
            grace_minutes=60, max_age_days=30, limit=500
        )
        for r in rows:
            rid = str(r.get("id") or "")
            pid = str(r.get("user_id") or "")
            if not rid or not pid:
                continue
            ctx = f"missed:{rid}"

            patient = await get_patient_info(pid)
            patient_name = (patient or {}).get("full_name") or "Your patient"
            title = (r.get("title") or "A reminder").strip() or "A reminder"
            alert_message = (
                f"{patient_name} missed the scheduled reminder '{title}'. "
                "They may need a check-in."
            )

            caregivers = await list_patient_caregivers_for_alerts(pid)
            if not caregivers:
                continue

            for cg in caregivers:
                caregiver_id = cg["caregiver_id"]
                if await caregiver_alert_exists_for_context(
                    pid, "reminder_missed", ctx, caregiver_id
                ):
                    continue

                row = await create_caregiver_alert(
                    caregiver_id=caregiver_id,
                    user_id=pid,
                    reminder_id=rid,
                    alert_type="reminder_missed",
                    message=alert_message,
                    context_id=ctx,
                )
                if not row:
                    continue
                await _push_fcm_to_caregiver(caregiver_id, "Patient Missed Reminder", alert_message, "reminder_missed")
                await send_caregiver_alert_email(
                    to_email=cg["email"],
                    patient_name=patient_name,
                    alert_message=alert_message,
                    alert_id=rid,
                    caregiver_firebase_uid=caregiver_id,
                )
                created += 1
    except Exception as e:
        logger.error("process_missed_reminder_caregiver_alerts: %s", e)
    return created

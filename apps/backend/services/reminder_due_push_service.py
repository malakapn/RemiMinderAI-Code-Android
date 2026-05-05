"""
Server-side due-time FCM for patients and caregivers (driven by internal cron).
"""
import logging
from typing import Dict

from services.alert_service import list_patient_caregivers_for_alerts
from services.db_reminders import (
    caregiver_alert_exists_for_context,
    create_caregiver_alert,
    get_patient_info,
    get_reminders_due_in_window,
    get_patient_fcm_token,
    try_claim_reminder_due_push,
)
from services.reminder_service import send_fcm_notification
from services.notification_service import send_caregiver_alert_email

logger = logging.getLogger(__name__)


async def process_reminder_due_push_notifications(
    past_minutes: float = 2.0,
    future_minutes: float = 2.0,
) -> Dict[str, int]:
    """
    Find reminders due in the time window, claim idempotently, send FCM to patient + caregivers.
    """
    stats = {"reminders_examined": 0, "patient_pushes": 0, "caregiver_pushes": 0}
    try:
        rows = await get_reminders_due_in_window(
            past_minutes=past_minutes,
            future_minutes=future_minutes,
            limit=300,
        )
    except Exception as e:
        logger.error("get_reminders_due_in_window failed: %s", e)
        return stats

    for r in rows:
        stats["reminders_examined"] += 1
        rid = str(r.get("id") or "")
        patient_uid = str(r.get("user_id") or "")
        if not rid or not patient_uid:
            continue

        st = r.get("scheduled_time")
        try:
            claimed = await try_claim_reminder_due_push(rid, st)
        except Exception as e:
            logger.warning("try_claim_reminder_due_push %s: %s", rid, e)
            continue
        if not claimed:
            continue

        title = (r.get("title") or "Reminder").strip() or "Reminder"
        body = (r.get("message") or "").strip() or f"Time for: {title}"

        ptok = await get_patient_fcm_token(patient_uid)
        if ptok:
            ok = await send_fcm_notification(
                fcm_token=ptok,
                title=title,
                body=body,
                data={
                    "type": "reminder_due",
                    "reminder_id": rid,
                    "patient_id": patient_uid,
                    "deep_link": f"/patient/reminder/{rid}",
                },
            )
            if ok:
                stats["patient_pushes"] += 1

        try:
            caregivers = await list_patient_caregivers_for_alerts(patient_uid)
        except Exception as e:
            logger.warning("list_patient_caregivers_for_alerts %s: %s", patient_uid, e)
            caregivers = []

        cg_body = f"Patient reminder due now: {title}"
        patient = await get_patient_info(patient_uid)
        patient_name = (patient or {}).get("full_name") or "Your patient"
        ctx = f"reminder_due:{rid}:{st.isoformat() if hasattr(st, 'isoformat') else str(st)}"
        for cg in caregivers:
            cg_id = cg.get("caregiver_id")
            if not cg_id:
                continue
            cg_id = str(cg_id)
            if await caregiver_alert_exists_for_context(
                patient_uid, "reminder_due", ctx, cg_id
            ):
                continue
            row = await create_caregiver_alert(
                caregiver_id=cg_id,
                user_id=patient_uid,
                reminder_id=rid,
                alert_type="reminder_due",
                message=cg_body,
                context_id=ctx,
            )
            if not row:
                continue

            cgtok = await get_patient_fcm_token(str(cg_id))
            if not cgtok:
                await send_caregiver_alert_email(
                    to_email=(cg.get("email") or "").strip(),
                    patient_name=patient_name,
                    alert_message=cg_body,
                    alert_id=rid,
                    caregiver_firebase_uid=cg_id,
                )
                continue

            ok = await send_fcm_notification(
                fcm_token=cgtok,
                title="Patient reminder due",
                body=cg_body,
                data={
                    "type": "reminder_due",
                    "reminder_id": rid,
                    "patient_id": patient_uid,
                    "deep_link": "/caregiver/reminders-timeline",
                },
            )
            if ok:
                stats["caregiver_pushes"] += 1
            await send_caregiver_alert_email(
                to_email=(cg.get("email") or "").strip(),
                patient_name=patient_name,
                alert_message=cg_body,
                alert_id=rid,
                caregiver_firebase_uid=cg_id,
            )

    logger.info("reminder_due_push stats=%s", stats)
    return stats

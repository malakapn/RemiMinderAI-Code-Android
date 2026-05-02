import logging
import os
from typing import Optional

from fastapi import APIRouter, Header, HTTPException, status

from services.alert_service import process_missed_reminder_caregiver_alerts
from services.reminder_due_push_service import process_reminder_due_push_notifications

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/internal", tags=["internal-cron"])


@router.post("/caregiver-missed-reminder-alerts", status_code=status.HTTP_200_OK)
async def caregiver_missed_reminder_alerts(
    x_internal_secret: Optional[str] = Header(None, alias="X-Internal-Secret"),
):
    """
    Cloud Scheduler (or cron) should POST here with header X-Internal-Secret
    matching env INTERNAL_CRON_SECRET. Creates caregiver alerts for overdue pending reminders.
    """
    expected = (os.getenv("INTERNAL_CRON_SECRET") or "").strip()
    if not expected or (x_internal_secret or "").strip() != expected:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
    n = await process_missed_reminder_caregiver_alerts()
    logger.info("caregiver_missed_reminder_alerts processed=%s", n)
    return {"alerts_created": n}


@router.post("/reminder-due-fcm", status_code=status.HTTP_200_OK)
async def reminder_due_fcm_push(
    x_internal_secret: Optional[str] = Header(None, alias="X-Internal-Secret"),
):
    """
    Cloud Scheduler should POST every minute with X-Internal-Secret matching INTERNAL_CRON_SECRET.
    Sends due-window FCM to the patient and each care-team caregiver (idempotent per occurrence).
    """
    expected = (os.getenv("INTERNAL_CRON_SECRET") or "").strip()
    if not expected or (x_internal_secret or "").strip() != expected:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
    stats = await process_reminder_due_push_notifications()
    return stats

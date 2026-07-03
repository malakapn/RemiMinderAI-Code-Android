from fastapi import APIRouter, HTTPException, status, Body, Depends, UploadFile, File, Form
from typing import List, Optional
import logging
import os
import shutil

from schemas.reminder_schemas import (
    ReminderCreate,
    ReminderUpdate,
    ReminderAction,
    ReminderResponse,
    ReminderListResponse,
    CaregiverAlertResponse,
    CaregiverDashboardResponse,
    FCMTokenUpdate
)
from services.reminder_service import (
    create_new_reminder,
    get_reminder_by_id,
    list_patient_reminders,
    update_reminder_details,
    cancel_reminder,
    complete_reminder,
    snooze_reminder,
    skip_reminder,
    get_caregiver_dashboard_data
)
from services.reminder_service import send_fcm_notification
# from services.speech_to_text_service import SpeechToTextService  # TODO: Implement this service
from services.db_reminders import (
    get_caregiver_alerts,
    mark_alert_as_read,
    delete_caregiver_alert,
    save_fcm_token,
    get_patient_fcm_token,
    delete_fcm_token,
)
from services.auth_gateway import get_current_user, get_current_user_jwt
from services.cache_service import get, set, invalidate, invalidate_prefix

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["reminders"])


def _normalize_priority(value: Optional[str]) -> str:
    p = (value or "").strip().lower()
    if p in {"high", "medium", "low", "critical"}:
        return p
    return "medium"


def _priority_from_alert_type(alert_type: str) -> str:
    t = (alert_type or "").strip().lower()
    if "missed" in t or "emergency" in t:
        return "high"
    if "medication" in t or "reminder" in t:
        return "medium"
    return "low"


def _priority_for_alert_row(alert: dict) -> str:
    context_id = (alert.get("context_id") or "").strip()
    if context_id.startswith("manual_priority:"):
        return _normalize_priority(context_id.split(":", 1)[1])
    return _priority_from_alert_type(alert.get("alert_type", ""))


def _internal_patient_id_from_roster(patients: list, pid: str) -> Optional[str]:
    """Map path param (internal UUID or Firebase UID) to users.id string for reminder rows."""
    for p in patients:
        if str(p.get("patient_id", "")) == pid:
            return str(p.get("patient_id", ""))
        if str(p.get("firebase_uid", "")) == pid:
            return str(p.get("patient_id", ""))
    return None


async def _require_self_caregiver_path(caregiver_id: str, current_user: dict) -> None:
    """Reject requests where path caregiver_id does not match the authenticated user."""
    firebase_uid = current_user.get("sub")
    if not firebase_uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )
    if caregiver_id == firebase_uid:
        return
    from services.db_service import get_user_uuid

    try:
        internal_id = await get_user_uuid(firebase_uid)
    except HTTPException:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )
    if str(caregiver_id) != str(internal_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )

@router.post("/reminders", response_model=ReminderResponse, status_code=status.HTTP_201_CREATED)
async def create_reminder(data: ReminderCreate, user_id: str = Depends(get_current_user)):
    """
    Create a new reminder with AI-generated personalized message.
    """
    try:
        # associate with authenticated user
        data.user_id = user_id
        reminder = await create_new_reminder(data)
        
        if not reminder:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create reminder"
            )
        
        invalidate(f"reminders_list:{user_id}")
        invalidate_prefix("caregiver_dashboard:")
        return reminder
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in create_reminder endpoint: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create reminder: {str(e)}"
        )

# Get user_id from JWT token instead of query param
@router.get("/reminders", response_model=ReminderListResponse)
async def get_patient_reminders(user_id: str = Depends(get_current_user)):
    """
    Get all reminders for a patient, organized by category (today, upcoming, past).
    """
    try:
        cache_key = f"reminders_list:{user_id}"
        cached = get(cache_key)
        if cached is not None:
            return cached
        reminders = await list_patient_reminders(user_id)
        set(cache_key, reminders, 30)
        return reminders
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_patient_reminders: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch reminders: {str(e)}"
        )

@router.get("/reminders/patient/{patient_id}", response_model=ReminderListResponse)
async def get_reminders_for_patient(
    patient_id: str,
    caregiver_internal_id: str = Depends(get_current_user),
):
    """Caregiver fetches reminders for one of their patients."""
    try:
        from services.db_service import get_my_patients_for_caregiver
        # get_current_user resolves to internal users.id (UUID string), not Firebase UID.
        patients = await get_my_patients_for_caregiver(caregiver_internal_id)
        pid = str(patient_id)
        internal_patient_id = _internal_patient_id_from_roster(patients, pid)
        if not internal_patient_id:
            raise HTTPException(status_code=403, detail="Access denied")
        reminders = await list_patient_reminders(internal_patient_id)
        return reminders
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching reminders for patient {patient_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/reminders/patient/{patient_id}", response_model=ReminderResponse, status_code=status.HTTP_201_CREATED)
async def create_reminder_for_patient(
    patient_id: str,
    data: ReminderCreate,
    caregiver_internal_id: str = Depends(get_current_user),
):
    """Caregiver creates a reminder for one of their patients."""
    try:
        from services.db_service import get_my_patients_for_caregiver
        # get_current_user resolves to internal users.id (UUID string), not Firebase UID.
        patients = await get_my_patients_for_caregiver(caregiver_internal_id)
        pid = str(patient_id)
        internal_patient_id = _internal_patient_id_from_roster(patients, pid)
        if not internal_patient_id:
            raise HTTPException(status_code=403, detail="Access denied")
        # Same user_id shape as POST /reminders (patient self-create) so GET /reminders lists match.
        data.user_id = internal_patient_id
        reminder = await create_new_reminder(data)
        if not reminder:
            raise HTTPException(status_code=500, detail="Failed to create reminder")

        # Day 2: Auto-send push notification to patient device (non-blocking for create flow)
        # Reminder creation should succeed even if no token exists or FCM send fails.
        try:
            fcm_token = await get_patient_fcm_token(internal_patient_id)
            if fcm_token:
                notification_sent = await send_fcm_notification(
                    fcm_token=fcm_token,
                    title=reminder.get("title", "Medication Reminder"),
                    body=reminder.get("message", "Time to take your medication"),
                    data={
                        "type": "medication_reminder",
                        "reminder_id": str(reminder.get("id", "")),
                        "patient_id": internal_patient_id,
                        "medication_id": str(reminder.get("medication_id", "")),
                        "deep_link": f"/patient/reminder/{reminder.get('id', '')}",
                    },
                )
                if notification_sent:
                    logger.info(
                        "FCM auto-notify success for reminder_id=%s patient_internal_id=%s",
                        reminder.get("id"),
                        internal_patient_id,
                    )
                else:
                    logger.warning(
                        "FCM auto-notify failed for reminder_id=%s patient_internal_id=%s",
                        reminder.get("id"),
                        internal_patient_id,
                    )
            else:
                logger.info(
                    "No FCM token registered for patient_internal_id=%s reminder_id=%s",
                    internal_patient_id,
                    reminder.get("id"),
                )
        except Exception as notify_error:
            logger.warning(
                "FCM auto-notify exception for reminder_id=%s patient_internal_id=%s error=%s",
                reminder.get("id"),
                internal_patient_id,
                str(notify_error),
            )

        invalidate(f"reminders_list:{internal_patient_id}")
        return reminder
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating reminder for patient {patient_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


async def _caregiver_internal_patient_id(
    caregiver_internal_id: str, patient_id: str
) -> str:
    from services.db_service import get_my_patients_for_caregiver

    patients = await get_my_patients_for_caregiver(caregiver_internal_id)
    internal = _internal_patient_id_from_roster(patients, str(patient_id))
    if not internal:
        raise HTTPException(status_code=403, detail="Access denied")
    return internal


@router.get(
    "/reminders/patient/{patient_id}/{reminder_id}",
    response_model=ReminderResponse,
)
async def get_reminder_for_patient(
    patient_id: str,
    reminder_id: str,
    caregiver_internal_id: str = Depends(get_current_user),
):
    """Caregiver reads one reminder for a roster patient."""
    try:
        internal_patient_id = await _caregiver_internal_patient_id(
            caregiver_internal_id, patient_id
        )
        reminder = await get_reminder_by_id(reminder_id, internal_patient_id)
        if not reminder:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reminder not found",
            )
        return reminder
    except HTTPException:
        raise
    except Exception as e:
        logger.error(
            "get_reminder_for_patient patient=%s reminder=%s: %s",
            patient_id,
            reminder_id,
            e,
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.put(
    "/reminders/patient/{patient_id}/{reminder_id}",
    response_model=ReminderResponse,
)
async def update_reminder_for_patient(
    patient_id: str,
    reminder_id: str,
    updates: ReminderUpdate,
    caregiver_internal_id: str = Depends(get_current_user),
):
    """Caregiver updates a reminder for a roster patient."""
    try:
        internal_patient_id = await _caregiver_internal_patient_id(
            caregiver_internal_id, patient_id
        )
        reminder = await update_reminder_details(
            reminder_id, internal_patient_id, updates
        )
        if not reminder:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reminder not found",
            )
        invalidate(f"reminders_list:{internal_patient_id}")
        invalidate_prefix("caregiver_dashboard:")
        return reminder
    except HTTPException:
        raise
    except Exception as e:
        logger.error(
            "update_reminder_for_patient patient=%s reminder=%s: %s",
            patient_id,
            reminder_id,
            e,
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.delete(
    "/reminders/patient/{patient_id}/{reminder_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_reminder_for_patient(
    patient_id: str,
    reminder_id: str,
    caregiver_internal_id: str = Depends(get_current_user),
):
    """Caregiver deletes a reminder for a roster patient."""
    try:
        internal_patient_id = await _caregiver_internal_patient_id(
            caregiver_internal_id, patient_id
        )
        success = await cancel_reminder(reminder_id, internal_patient_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reminder not found",
            )
        invalidate(f"reminders_list:{internal_patient_id}")
        invalidate_prefix("caregiver_dashboard:")
        return None
    except HTTPException:
        raise
    except Exception as e:
        logger.error(
            "delete_reminder_for_patient patient=%s reminder=%s: %s",
            patient_id,
            reminder_id,
            e,
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/reminders/{reminder_id}", response_model=ReminderResponse)
async def get_reminder(reminder_id: str, user_id: str = Depends(get_current_user)):
    """
    Get a single reminder by ID.
    """
    try:
        reminder = await get_reminder_by_id(reminder_id, user_id)

        if not reminder:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reminder not found"
            )
        
        return reminder

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_reminder: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch reminder: {str(e)}"
        )


@router.put("/reminders/{reminder_id}", response_model=ReminderResponse)
async def update_reminder(reminder_id: str, user_id: str = Depends(get_current_user), updates: ReminderUpdate = Body(...)):
    """
    Update a reminder (time, title, status, etc.).
    """
    try:
        reminder = await update_reminder_details(reminder_id, user_id, updates)

        if not reminder:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reminder not found"
            )
        
        invalidate(f"reminders_list:{user_id}")
        invalidate_prefix("caregiver_dashboard:")
        return reminder
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in update_reminder: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update reminder: {str(e)}"
        )


@router.delete("/reminders/{reminder_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_reminder(reminder_id: str, user_id: str = Depends(get_current_user)):
    """
    Cancel/delete a reminder.
    """
    try:
        success = await cancel_reminder(reminder_id, user_id)

        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reminder not found"
            )
        
        invalidate(f"reminders_list:{user_id}")
        invalidate_prefix("caregiver_dashboard:")
        return None
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in delete_reminder: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete reminder: {str(e)}"
        )


@router.post("/reminders/{reminder_id}/complete", response_model=ReminderResponse)
async def mark_complete(
    reminder_id: str, 
    user_id: str = Depends(get_current_user),
    action: ReminderAction = Body(default=ReminderAction())
):
    """
    Mark a reminder as completed.
    """
    try:
        reminder = await complete_reminder(reminder_id, user_id, action)
        
        if not reminder:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reminder not found"
            )
        
        invalidate(f"reminders_list:{user_id}")
        invalidate_prefix("caregiver_dashboard:")
        return reminder
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in mark_complete: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to complete reminder: {str(e)}"
        )

@router.post("/reminders/{reminder_id}/snooze", response_model=ReminderResponse)
async def snooze_reminder_post(
    reminder_id: str,
    user_id: str = Depends(get_current_user),
    snooze_minutes: int = 30
):
    """
    Snooze a reminder. The snooze count is incremented, and the scheduled time is pushed forward.
    """
    try:
        reminder = await snooze_reminder(reminder_id, user_id, snooze_minutes)
        
        if not reminder:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cannot snooze: Reminder not found or is already completed/cancelled." 
            )
        
        invalidate(f"reminders_list:{user_id}")
        invalidate_prefix("caregiver_dashboard:")
        return reminder
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in snooze_reminder: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to snooze reminder: {str(e)}",
        )

@router.post("/reminders/{reminder_id}/skip", response_model=ReminderResponse)
async def skip_reminder_post(
    reminder_id: str, 
    user_id: str = Depends(get_current_user),
    action: ReminderAction = Body(default=ReminderAction())
):
    
    """
    Skip a reminder with optional reason.
    """
    try:
        reminder = await skip_reminder(reminder_id, user_id, action)

        if not reminder:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reminder not found"
            )
        
        invalidate(f"reminders_list:{user_id}")
        invalidate_prefix("caregiver_dashboard:")
        return reminder

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in skip_reminder: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to skip reminder: {str(e)}"
        )


# ============================================================================
# CAREGIVER
# ============================================================================

@router.get("/caregivers/{caregiver_id}/activity", response_model=CaregiverDashboardResponse)
async def get_caregiver_activity(caregiver_id: str, user_id: str = Depends(get_current_user)):
    """
    Get aggregated activity data for caregiver dashboard.
    Shows next reminders, recent activity, and alert summary.
    """
    try:
        cache_key = f"caregiver_dashboard:{caregiver_id}:{user_id}"
        cached = get(cache_key)
        if cached is not None:
            return cached
        dashboard_data = await get_caregiver_dashboard_data(caregiver_id, user_id)
        set(cache_key, dashboard_data, 30)
        return dashboard_data
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_caregiver_activity: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch caregiver activity: {str(e)}"
        )

@router.post("/caregivers/alerts", response_model=CaregiverAlertResponse, status_code=status.HTTP_201_CREATED)
async def create_alert(
    data: dict = Body(...),
    current_user: dict = Depends(get_current_user_jwt),
):
    """Create a manual caregiver alert."""
    try:
        from services.db_reminders import create_caregiver_alert
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid token")
        priority = _normalize_priority(data.get("priority"))
        alert = await create_caregiver_alert(
            caregiver_id=firebase_uid,
            user_id=data.get("user_id", firebase_uid),
            reminder_id=None,
            alert_type=data.get("alert_type", "manual"),
            message=data.get("message", ""),
            context_id=f"manual_priority:{priority}",
        )
        if not alert:
            raise HTTPException(status_code=500, detail="Failed to create alert")
        alert["priority"] = priority
        invalidate_prefix(f"caregiver_alerts:{firebase_uid}:")
        return alert
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating alert: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/caregivers/{caregiver_id}/alerts", response_model=List[CaregiverAlertResponse])
async def get_alerts(
    caregiver_id: str,
    unread_only: bool = False,
    current_user: dict = Depends(get_current_user_jwt),
):
    """
    Get all alerts for a caregiver.
    """
    try:
        await _require_self_caregiver_path(caregiver_id, current_user)
        cache_key = f"caregiver_alerts:{caregiver_id}:{unread_only}"
        cached = get(cache_key)
        if cached is not None:
            return cached
        alerts = await get_caregiver_alerts(caregiver_id, unread_only)
        for alert in alerts:
            alert["priority"] = _priority_for_alert_row(alert)
        set(cache_key, alerts, 30)
        return alerts
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_alerts: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch alerts: {str(e)}"
        )


@router.patch("/caregivers/alerts/{alert_id}/read", response_model=CaregiverAlertResponse)
async def mark_alert_read(
    alert_id: str,
    caregiver_id: str,
    current_user: dict = Depends(get_current_user_jwt),
):
    """
    Mark a caregiver alert as read.
    """
    try:
        await _require_self_caregiver_path(caregiver_id, current_user)
        alert = await mark_alert_as_read(alert_id, caregiver_id)

        if not alert:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Alert not found"
            )
        alert["priority"] = _priority_for_alert_row(alert)
        
        invalidate_prefix(f"caregiver_alerts:{caregiver_id}:")
        user_id = alert.get("user_id") if alert else None
        if user_id:
            invalidate(f"caregiver_dashboard:{caregiver_id}:{user_id}")
        else:
            invalidate_prefix(f"caregiver_dashboard:{caregiver_id}:")
        return alert
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in mark_alert_read: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to mark alert as read: {str(e)}"
        )


@router.delete("/caregivers/alerts/{alert_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_alert(
    alert_id: str,
    caregiver_id: str,
    current_user: dict = Depends(get_current_user_jwt),
):
    """
    Delete a caregiver alert.
    """
    try:
        await _require_self_caregiver_path(caregiver_id, current_user)
        deleted = await delete_caregiver_alert(alert_id, caregiver_id)
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Alert not found",
            )
        invalidate_prefix(f"caregiver_alerts:{caregiver_id}:")
        invalidate_prefix(f"caregiver_dashboard:{caregiver_id}:")
        return None
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting alert: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete alert: {str(e)}",
        )


# High-accuracy speech-to-text processing
# TODO: Implement SpeechToTextService
# @router.post("/process-audio-transcription")
# async def process_audio_transcription(
#     audio_file: UploadFile = File(..., description="Audio file to transcribe"),
#     patient_id: str = Form(..., description="Patient ID"),
#     visit_id: str = Form(..., description="Visit ID")
# ):
#     """
#     Process uploaded audio file with high-accuracy Whisper transcription.
#     Use this for critical medical conversations requiring maximum accuracy.
#     """
#     try:
#         stt_service = SpeechToTextService()

#         # Save uploaded file temporarily
#         temp_dir = "/tmp"  # Use appropriate temp directory
#         file_extension = os.path.splitext(audio_file.filename)[1] or ".wav"
#         temp_path = f"{temp_dir}/audio_{patient_id}_{visit_id}{file_extension}"

#         with open(temp_path, "wb") as buffer:
#             shutil.copyfileobj(audio_file.file, buffer)

#         # Transcribe with Whisper
#         transcript = await stt_service.transcribe_audio_file(temp_path)

#         # Clean up temp file
#         os.remove(temp_path)

#         if not transcript:
#             raise HTTPException(
#                 status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
#                 detail="Failed to transcribe audio file"
#             )

#         # Process with AI summary
#         ai_summary_data = {
#             "transcript": transcript,
#             "summary": f"High-accuracy transcription processed for patient {patient_id}",
#             "action_items": ["Review transcription for accuracy"],
#             "medications": [],
#             "patient_id": patient_id,
#             "visit_id": visit_id
#         }

#         return {
#             "status": "success",
#             "transcript": transcript,
#             "accuracy_method": "whisper_high_accuracy",
#             "data": ai_summary_data
#         }

#     except Exception as e:
#         logger.error(f"Error processing audio transcription: {str(e)}")
#         raise HTTPException(
#             status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
#             detail=f"Failed to process audio transcription: {str(e)}"
#         )


# ============================================================================
# FCM Push Notifications
# ============================================================================

@router.post("/fcm/token")
async def update_fcm_token(
    token_data: FCMTokenUpdate,
    user_id: str = Depends(get_current_user)
):
    """
    Store FCM device token for a patient.
    This is called when the patient logs in to register their device.
    """
    try:
        success = await save_fcm_token(user_id, token_data.fcm_token, token_data.device_type)
        return {"success": success, "user_id": user_id}

    except Exception as e:
        logger.error(f"Error saving FCM token: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to save FCM token: {str(e)}"
        )


@router.delete("/fcm/token", status_code=status.HTTP_204_NO_CONTENT)
async def deregister_fcm_token(user_id: str = Depends(get_current_user)):
    """Remove FCM token on logout so the user stops receiving push notifications."""
    try:
        await delete_fcm_token(user_id)
    except Exception as e:
        logger.error(f"Error deregistering FCM token: {str(e)}")


@router.post("/reminders/{reminder_id}/notify")
async def send_reminder_push_notification(
    reminder_id: str,
    user_id: str = Depends(get_current_user)
):
    """
    Send FCM push notification for a specific reminder.
    Called when caregiver sets or modifies a reminder for a patient.
    """
    try:
        reminder = await get_reminder_by_id(reminder_id, user_id)
        if not reminder:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reminder not found"
            )

        fcm_token = await get_patient_fcm_token(user_id)
        if not fcm_token:
            return {"success": False, "message": "No FCM token registered"}

        success = await send_fcm_notification(
            fcm_token=fcm_token,
            title=reminder.get("title", "Medication Reminder"),
            body=reminder.get("message", "Time to take your medication"),
            data={
                "type": "medication_reminder",
                "reminder_id": str(reminder_id),
                "medication_id": str(reminder.get("medication_id", "") or ""),
                "deep_link": f"/patient/reminder/{reminder_id}",
            }
        )

        return {"success": success, "reminder_id": reminder_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sending push notification: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send push notification: {str(e)}"
        )

import asyncio
import logging
import secrets
from datetime import date, datetime, time, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from pydantic import BaseModel, EmailStr

from services.auth_gateway import get_current_user_jwt as get_current_user
from services.cache_service import get, set, invalidate
from services.db_service import (
    add_care_team_member,
    cancel_care_team_invitation,
    create_care_team_invitation,
    decline_care_team_invitation_by_invitee,
    get_care_team_invitation_by_token,
    get_care_team_members,
    get_care_team_member_by_id,
    get_my_care_team_invitations,
    get_my_patients_for_caregiver,
    get_pending_care_team_invitations,
    get_symptom_journal_for_patient,
    get_user_email,
    get_user_uuid,
    mark_care_team_invitation_accepted,
    remove_care_team_member,
    resend_care_team_invitation,
    update_care_team_member_permission,
    upgrade_user_to_caregiver_if_user_role,
    validate_caregiver_signup_allowed,
)
from services.invitation_email_service import send_invite_email
from services.phi_access_log import log_phi_access
from route.caregiver_notes import _require_patient_in_my_care_team

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/care-team", tags=["Care Team"])


class CareTeamInviteRequest(BaseModel):
    email: EmailStr
    role: str
    permission: str


class CareTeamAcceptRequest(BaseModel):
    token: str
    consent_version: Optional[str] = "phase1-v1"


class CaregiverSignupValidateBody(BaseModel):
    """Pre-Firebase signup: verify email has a pending care-team invite (optional token match)."""

    email: EmailStr
    token: Optional[str] = None


class CareTeamPermissionUpdateRequest(BaseModel):
    permission: str


@router.post("/public/validate-caregiver-signup", status_code=status.HTTP_200_OK)
async def public_validate_caregiver_signup(body: CaregiverSignupValidateBody):
    """
    Unauthenticated: returns whether this email may register as a caregiver
    (pending invitation, optionally verified by invite token).
    """
    ok, reason = await validate_caregiver_signup_allowed(body.email, body.token)
    return {"ok": ok, "reason": reason}


@router.get("/my-patients", status_code=status.HTTP_200_OK)
async def list_my_patients(
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    List all patients that the current caregiver is caring for.
    Returns patient info with medication adherence, alerts, etc.
    """
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid token")

        member_user_id = await get_user_uuid(firebase_uid)
        patients = await get_my_patients_for_caregiver(member_user_id)
        ip = request.client.host if request.client else None
        await log_phi_access(
            firebase_uid,
            None,
            "care_team_my_patients",
            route=str(request.url.path),
            ip_address=ip,
        )
        return patients

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to list my patients: {e}")
        raise HTTPException(status_code=500, detail="Failed to load patients")


@router.get("/patients/{patient_id}/symptoms", status_code=status.HTTP_200_OK)
async def get_patient_symptoms_journal(
    request: Request,
    patient_id: str,
    date_from: Optional[date] = Query(None, description="Inclusive start (UTC calendar day)"),
    date_to: Optional[date] = Query(None, description="Inclusive end (UTC calendar day)"),
    severity: Optional[str] = Query(
        None, description="Case-insensitive substring match on the severity field"
    ),
    limit: int = Query(200, ge=1, le=500),
    current_user: dict = Depends(get_current_user),
):
    """
    Caregiver read-only symptom lines from the patient's visit AI extractions (newest first).
    """
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid token")

        await _require_patient_in_my_care_team(firebase_uid, patient_id)

        df = None
        if date_from is not None:
            df = datetime.combine(date_from, time.min, tzinfo=timezone.utc)
        dte = None
        if date_to is not None:
            dte = datetime.combine(date_to + timedelta(days=1), time.min, tzinfo=timezone.utc)

        entries = await get_symptom_journal_for_patient(
            patient_id,
            date_from=df,
            date_to_exclusive=dte,
            severity_substring=severity,
            limit=limit,
        )
        ip = request.client.host if request.client else None
        await log_phi_access(
            firebase_uid,
            patient_id,
            "symptom_journal",
            route=str(request.url.path),
            ip_address=ip,
        )
        return {
            "patient_id": patient_id,
            "entries": entries,
            "filters_applied": {
                "date_from": date_from.isoformat() if date_from else None,
                "date_to": date_to.isoformat() if date_to else None,
                "severity_substring": (severity.strip() if severity else "") or None,
                "limit": limit,
            },
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed symptom journal for patient_id=%s: %s", patient_id, e)
        raise HTTPException(status_code=500, detail="Failed to load symptom journal")


@router.get("", status_code=status.HTTP_200_OK)
async def list_care_team_members(
    current_user: dict = Depends(get_current_user),
):
    """
    List care team members for the current patient.
    """
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid token")

        patient_id = await get_user_uuid(firebase_uid)
        cache_key = f"care_team_list:{patient_id}"
        cached = get(cache_key)
        if cached is not None:
            return cached
        members = await get_care_team_members(patient_id)
        set(cache_key, members, 60)
        return members

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to list care team members: {e}")
        raise HTTPException(status_code=500, detail="Failed to load care team")


@router.post("/invite", status_code=status.HTTP_201_CREATED)
async def invite_care_team_member(
    request: CareTeamInviteRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Create a care team invitation for a caregiver.
    """
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid token")

        if request.permission not in {"view", "full"}:
            raise HTTPException(status_code=400, detail="Invalid permission")

        if not request.role.strip():
            raise HTTPException(status_code=400, detail="Role is required")

        patient_id = await get_user_uuid(firebase_uid)
        token = secrets.token_urlsafe(32)

        await create_care_team_invitation(
            patient_id=patient_id,
            invitee_email=request.email,
            role=request.role.strip(),
            permission=request.permission,
            token=token,
            invited_by_user_id=patient_id,
        )

        patient_name = current_user.get("name") or "Your patient"
        try:
            email_ok = await asyncio.to_thread(
                send_invite_email,
                to_email=request.email,
                invite_token=token,
                patient_name=patient_name,
            )
        except Exception as e:
            logger.warning(f"Failed to send care team invite email: {e}")
            invalidate(f"care_team_pending:{patient_id}")
            invalidate(f"care_team_list:{patient_id}")
            raise HTTPException(
                status_code=503,
                detail="Invitation was created but email could not be sent. Try resend from Care Team.",
            ) from e

        if not email_ok:
            logger.error(
                "care team invite email returned failure for patient_id=%s to=%s",
                patient_id,
                request.email,
            )
            invalidate(f"care_team_pending:{patient_id}")
            invalidate(f"care_team_list:{patient_id}")
            raise HTTPException(
                status_code=503,
                detail="Invitation was created but email delivery failed. Try resend or check your email configuration.",
            )

        invalidate(f"care_team_pending:{patient_id}")
        invalidate(f"care_team_list:{patient_id}")
        return {"status": "sent"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create care team invitation: {e}")
        raise HTTPException(status_code=500, detail="Failed to create invitation")


@router.post("/accept", status_code=status.HTTP_200_OK)
async def accept_care_team_invitation(
    request: CareTeamAcceptRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Accept a care team invitation by token.
    """
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid token")

        invitation = await get_care_team_invitation_by_token(request.token)
        if not invitation:
            raise HTTPException(status_code=404, detail="Invitation not found")

        if invitation["status"] != "pending":
            raise HTTPException(status_code=400, detail="Invitation is not pending")

        expires_at = invitation.get("expires_at")
        if expires_at:
            if isinstance(expires_at, str):
                expires_at = datetime.fromisoformat(expires_at)
            if expires_at < datetime.now(timezone.utc):
                raise HTTPException(status_code=400, detail="Invitation expired")

        member_user_id = await get_user_uuid(firebase_uid)

        await add_care_team_member(
            patient_id=str(invitation["patient_id"]),
            member_user_id=member_user_id,
            role=str(invitation["role"]),
            permission=str(invitation["permission"]),
            status="active",
            invited_by_user_id=invitation.get("invited_by_user_id"),
            consent_version=request.consent_version or "phase1-v1",
        )

        await upgrade_user_to_caregiver_if_user_role(
            member_user_id,
            firebase_uid=firebase_uid,
        )

        updated = await mark_care_team_invitation_accepted(
            invitation_id=str(invitation["id"]),
            accepted_by_user_id=member_user_id,
        )
        if not updated:
            raise HTTPException(status_code=404, detail="Invitation not found")

        patient_id = str(invitation["patient_id"])
        invalidate(f"care_team_pending:{patient_id}")
        invalidate(f"care_team_list:{patient_id}")
        invalidate(f"care_team_my_invites:{member_user_id}")
        return {"status": "accepted"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to accept care team invitation: {e}")
        raise HTTPException(status_code=500, detail="Failed to accept invitation")


@router.get("/my-invitations", status_code=status.HTTP_200_OK)
async def list_my_care_team_invitations(
    current_user: dict = Depends(get_current_user),
):
    """
    List care team invitations for the current caregiver (recent history + pending).
    """
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid token")

        user_id = await get_user_uuid(firebase_uid)
        cache_key = f"care_team_my_invites:{user_id}"
        cached = get(cache_key)
        if cached is not None:
            return cached
        user_email = await get_user_email(user_id)
        invitations = await get_my_care_team_invitations(user_email)
        set(cache_key, invitations, 60)
        return invitations

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to list care team invitations: {e}")
        raise HTTPException(status_code=500, detail="Failed to load invitations")


@router.post(
    "/my-invitations/{invitation_id}/decline",
    status_code=status.HTTP_200_OK,
)
async def decline_my_care_team_invitation(
    invitation_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Decline a pending invitation received by the current caregiver."""
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid token")

        user_id = await get_user_uuid(firebase_uid)
        user_email = await get_user_email(user_id)
        patient_id = await decline_care_team_invitation_by_invitee(
            invitation_id, user_email
        )
        if not patient_id:
            raise HTTPException(status_code=404, detail="Invitation not found")

        invalidate(f"care_team_my_invites:{user_id}")
        invalidate(f"care_team_pending:{patient_id}")
        invalidate(f"care_team_list:{patient_id}")
        return {"success": True}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to decline care team invitation: {e}")
        raise HTTPException(status_code=500, detail="Failed to decline invitation")


@router.get("/pending", status_code=status.HTTP_200_OK)
async def list_pending_care_team_invitations(
    current_user: dict = Depends(get_current_user),
):
    """
    List pending care team invitations for the current patient.
    """
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid token")

        patient_id = await get_user_uuid(firebase_uid)
        cache_key = f"care_team_pending:{patient_id}"
        cached = get(cache_key)
        if cached is not None:
            return cached
        invitations = await get_pending_care_team_invitations(patient_id)
        set(cache_key, invitations, 60)
        return invitations

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to list pending care team invitations: {e}")
        raise HTTPException(status_code=500, detail="Failed to load invitations")


@router.delete("/pending/{invitation_id}", status_code=status.HTTP_200_OK)
async def cancel_pending_care_team_invitation(
    invitation_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Cancel a pending care team invitation for the current patient.
    """
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid token")

        patient_id = await get_user_uuid(firebase_uid)
        updated = await cancel_care_team_invitation(
            patient_id=patient_id,
            invitation_id=invitation_id,
        )
        if not updated:
            raise HTTPException(status_code=404, detail="Invitation not found")

        invalidate(f"care_team_pending:{patient_id}")
        invalidate(f"care_team_list:{patient_id}")
        return {"success": True}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to cancel care team invitation: {e}")
        raise HTTPException(status_code=500, detail="Failed to cancel invitation")


@router.post("/pending/{invitation_id}/resend", status_code=status.HTTP_200_OK)
async def resend_pending_care_team_invitation(
    invitation_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Resend a pending care team invitation for the current patient.
    """
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid token")

        patient_id = await get_user_uuid(firebase_uid)
        token = await resend_care_team_invitation(
            patient_id=patient_id,
            invitation_id=invitation_id,
        )
        if not token:
            raise HTTPException(status_code=404, detail="Invitation not found")

        invitation = await get_care_team_invitation_by_token(token)
        if not invitation:
            raise HTTPException(status_code=404, detail="Invitation not found")

        patient_name = current_user.get("name") or "Your patient"
        try:
            email_ok = await asyncio.to_thread(
                send_invite_email,
                to_email=invitation["invitee_email"],
                invite_token=token,
                patient_name=patient_name,
            )
        except Exception as e:
            logger.warning(f"Failed to resend care team invite email: {e}")
            raise HTTPException(
                status_code=503,
                detail="Could not send invitation email. Please try again later.",
            ) from e

        if not email_ok:
            logger.error(
                "resend invite email failed for patient_id=%s invitation_id=%s",
                patient_id,
                invitation_id,
            )
            raise HTTPException(
                status_code=503,
                detail="Could not send invitation email. Please try again later.",
            )

        invalidate(f"care_team_pending:{patient_id}")
        invalidate(f"care_team_list:{patient_id}")
        return {"success": True}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to resend care team invitation: {e}")
        raise HTTPException(status_code=500, detail="Failed to resend invitation")


@router.patch("/{member_id}", status_code=status.HTTP_200_OK)
async def update_care_team_permission(
    member_id: str,
    request: CareTeamPermissionUpdateRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Update a care team member's permission for the current patient.
    """
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid token")

        if request.permission not in {"view", "full"}:
            raise HTTPException(status_code=400, detail="Invalid permission")

        patient_id = await get_user_uuid(firebase_uid)
        member = await get_care_team_member_by_id(member_id)
        if not member:
            raise HTTPException(status_code=404, detail="Care team member not found")
        if str(member["patient_id"]) != str(patient_id):
            raise HTTPException(status_code=403, detail="Not authorized")

        updated = await update_care_team_member_permission(
            member_id=member_id,
            permission=request.permission,
        )
        if not updated:
            raise HTTPException(status_code=404, detail="Care team member not found")

        invalidate(f"care_team_list:{patient_id}")
        return {"success": True}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update care team permission: {e}")
        raise HTTPException(status_code=500, detail="Failed to update permission")


@router.delete("/{member_id}", status_code=status.HTTP_200_OK)
async def delete_care_team_member_endpoint(
    member_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Delete a care team member for the current patient.
    """
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid token")

        patient_id = await get_user_uuid(firebase_uid)
        member = await get_care_team_member_by_id(member_id)
        if not member:
            raise HTTPException(status_code=404, detail="Care team member not found")
        if str(member["patient_id"]) != str(patient_id):
            raise HTTPException(status_code=403, detail="Not authorized")

        deleted = await remove_care_team_member(member_id=member_id)
        if not deleted:
            raise HTTPException(status_code=404, detail="Care team member not found")

        invalidate(f"care_team_list:{patient_id}")
        return {"success": True}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete care team member: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete member")

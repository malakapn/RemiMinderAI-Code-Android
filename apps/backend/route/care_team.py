import asyncio
import logging
import os
import secrets
from datetime import date, datetime, time, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import RedirectResponse
from pydantic import BaseModel, EmailStr

from services.auth_gateway import get_current_user_jwt as get_current_user
from services.cache_service import get, set, invalidate
from services.db_service import (
    cancel_care_team_invitation,
    create_care_team_invitation,
    decline_care_team_invitation_by_invitee,
    ensure_user_exists,
    get_care_team_invitation_by_token,
    get_care_team_member_by_id,
    get_care_team_members,
    get_my_care_team_invitations,
    get_my_patients_for_caregiver,
    get_pending_care_team_invitations,
    get_user_by_email,
    get_user_email,
    get_user_uuid,
    mark_care_team_invitation_accepted,
    remove_care_team_member,
    resend_care_team_invitation,
    update_care_team_member_permission,
    validate_caregiver_signup_allowed,
)
from services.invitation_email_service import send_invite_email
from services.phi_access_log import log_phi_access
from route.caregiver_notes import _require_patient_in_my_care_team

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/care-team", tags=["Care Team"])

# Alias router: email links and legacy frontends
invitations_router = APIRouter(prefix="/api/invitations", tags=["Invitations"])


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


async def _invitation_verify_payload(token: str) -> dict:
    invitation = await get_care_team_invitation_by_token(token)
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

    return {
        "patient_name": "Patient",
        "caregiver_email": invitation["invitee_email"],
    }


# --- /api/invitations (email deep links) ---


@invitations_router.get("/verify")
async def verify_invitation_alias(token: str):
    return await _invitation_verify_payload(token)


@invitations_router.get("/accept")
async def accept_invitation_redirect(token: str):
    """
    Handle clicks from invitation emails (no Authorization header).
    Marks invitation accepted when possible and redirects to the web app.
    """
    try:
        invitation = await get_care_team_invitation_by_token(token)
        frontend_url = os.getenv("REACT_APP_FRONTEND_URL", "https://remiminderai.com").rstrip(
            "/"
        )
        if not invitation:
            logger.error("Invite redirect: invitation not found for token=%s", token)
            return RedirectResponse(
                url=f"{frontend_url}?status=error&message=invalid_token"
            )

        if invitation["status"] != "pending":
            return RedirectResponse(
                url=f"{frontend_url}?status=error&message=not_pending"
            )

        expires_at = invitation.get("expires_at")
        if expires_at:
            if isinstance(expires_at, str):
                expires_at = datetime.fromisoformat(expires_at)
            if expires_at < datetime.now(timezone.utc):
                return RedirectResponse(
                    url=f"{frontend_url}?status=error&message=expired"
                )

        email = invitation.get("invitee_email")
        user = await get_user_by_email(email) if email else None

        if user and user.get("firebase_uid"):
            member_uid = str(user["firebase_uid"])
            await mark_care_team_invitation_accepted(
                invitation_id=str(invitation["id"]),
                accepted_by_user_id=member_uid,
            )
            logger.info(
                "Auto-linked existing user %s via GET /api/invitations/accept",
                email,
            )
            return RedirectResponse(url=f"{frontend_url}?status=success")

        # Invitee not in our users table yet: keep invitation pending for POST /accept after signup/login.
        return RedirectResponse(
            url=f"{frontend_url}?status=pending&invite_token={token}"
        )

    except Exception as e:
        logger.error("Error in GET invitation accept redirect: %s", e, exc_info=True)
        frontend_url = os.getenv("REACT_APP_FRONTEND_URL", "https://remiminderai.com").rstrip(
            "/"
        )
        return RedirectResponse(url=f"{frontend_url}?status=error")


@invitations_router.post("/accept")
async def accept_invitation_alias(
    request: CareTeamAcceptRequest,
    current_user: dict = Depends(get_current_user),
):
    return await accept_care_team_invitation(request, current_user)


# --- /api/care-team ---


@router.get("", status_code=status.HTTP_200_OK)
async def list_care_team_members(
    current_user: dict = Depends(get_current_user),
):
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

        patient_label = (
            (current_user.get("name") or "").strip()
            or (current_user.get("email") or "").strip()
            or "Your patient"
        )

        email_ok = False
        try:
            email_ok = await asyncio.to_thread(
                send_invite_email,
                request.email,
                token,
                patient_label,
            )
        except Exception as e:
            logger.warning("Exception sending care team invite email: %s", e)
            invalidate(f"care_team_pending:{patient_id}")
            invalidate(f"care_team_list:{patient_id}")
            raise HTTPException(
                status_code=503,
                detail="Invitation was saved but the email could not be sent. "
                "Check Brevo and public API URL env vars, then use Resend.",
            ) from e

        invalidate(f"care_team_pending:{patient_id}")
        invalidate(f"care_team_list:{patient_id}")

        if not email_ok:
            logger.error(
                "care team invite email failed (Brevo or URL config) patient_id=%s to=%s",
                patient_id,
                request.email,
            )
            raise HTTPException(
                status_code=503,
                detail="Invitation was saved but email delivery failed. "
                "Configure BREVO_API_KEY and a public API base URL "
                "(BACKEND_URL or MOBILE_API_BASE_URL), then tap Resend.",
            )

        return {"status": "invited", "email_sent": True}

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
    try:
        auth_uid = current_user.get("sub")
        if not auth_uid:
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

        email = current_user.get("email") or invitation.get("invitee_email")
        name = current_user.get("name") or "Caregiver"

        await ensure_user_exists(
            firebase_uid=auth_uid,
            email=email,
            firebase_name=name,
            role="caregiver",
        )

        member_user_id = await get_user_uuid(auth_uid)

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
        logger.error(f"Failed to accept care team invitation: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to accept invitation")


@router.get("/my-invitations", status_code=status.HTTP_200_OK)
async def list_my_care_team_invitations(
    current_user: dict = Depends(get_current_user),
):
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

        patient_label = (
            (current_user.get("name") or "").strip()
            or (current_user.get("email") or "").strip()
            or "Your patient"
        )

        email_ok = False
        try:
            email_ok = await asyncio.to_thread(
                send_invite_email,
                invitation["invitee_email"],
                token,
                patient_label,
            )
        except Exception as e:
            logger.warning("Exception resending care team invite email: %s", e)
            raise HTTPException(
                status_code=503,
                detail="Could not send invitation email. Try again later.",
            ) from e

        invalidate(f"care_team_pending:{patient_id}")
        invalidate(f"care_team_list:{patient_id}")

        if not email_ok:
            raise HTTPException(
                status_code=503,
                detail="Could not send invitation email. Check email provider configuration.",
            )

        return {"success": True, "email_sent": True}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to resend care team invitation: {e}")
        raise HTTPException(status_code=500, detail="Failed to resend invitation")


@router.get("/invitations/verify")
async def verify_care_team_invitation(token: str):
    try:
        return await _invitation_verify_payload(token)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to verify care team invitation: {e}")
        raise HTTPException(status_code=500, detail="Failed to verify invitation")


@router.post("/validate-caregiver-signup", status_code=status.HTTP_200_OK)
async def validate_caregiver_signup(body: CaregiverSignupValidateBody):
    """
    Pre-Firebase registration: ensure the email has a pending care-team invite
    (and optional invite token matches). Mobile expects {"ok": bool, "reason": str}.
    """
    try:
        allowed, reason = await validate_caregiver_signup_allowed(
            body.email,
            invite_token=body.token,
        )
        return {"ok": allowed, "reason": reason if allowed else reason}
    except Exception as e:
        logger.error("validate_caregiver_signup failed: %s", e)
        raise HTTPException(status_code=500, detail="Validation failed")


@router.get("/my-patients", status_code=status.HTTP_200_OK)
async def list_my_patients_for_caregiver_view(
    current_user: dict = Depends(get_current_user),
):
    """Caregiver roster for dashboard / patient pickers (SQL care-team memberships)."""
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid token")
        caregiver_uuid = await get_user_uuid(firebase_uid)
        return await get_my_patients_for_caregiver(caregiver_uuid)
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to list caregiver patients: %s", e)
        raise HTTPException(status_code=500, detail="Failed to load patients")


@router.patch("/{member_id}", status_code=status.HTTP_200_OK)
async def update_care_team_permission(
    member_id: str,
    request: CareTeamPermissionUpdateRequest,
    current_user: dict = Depends(get_current_user),
):
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

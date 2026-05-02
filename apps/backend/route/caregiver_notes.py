import logging
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel
from datetime import datetime

from services.auth_gateway import get_current_user_jwt as get_current_user
from services.db_caregiver_notes import (
    get_note,
    get_notes,
    create_note,
    update_note,
    delete_note,
    visit_belongs_to_patient,
    reminder_belongs_to_patient,
)
from services.phi_access_log import log_phi_access

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/caregiver-notes", tags=["caregiver-notes"])


class NoteCreate(BaseModel):
    patient_id: str
    title: str
    content: str
    visit_id: Optional[str] = None
    reminder_id: Optional[str] = None


class NoteUpdate(BaseModel):
    title: str
    content: str


class NoteResponse(BaseModel):
    id: str
    caregiver_id: str
    patient_id: str
    title: str
    content: str
    created_at: datetime
    updated_at: datetime
    visit_id: Optional[str] = None
    reminder_id: Optional[str] = None

    class Config:
        from_attributes = True


def _client_ip(request: Request) -> Optional[str]:
    if request.client:
        return request.client.host
    return None


def _normalize_note_ids(note: dict) -> dict:
    """
    Convert UUID-like fields to strings so response validation is stable across
    mixed Firebase UID / UUID-backed columns.
    """
    normalized = dict(note)
    for key in ("id", "caregiver_id", "patient_id", "visit_id", "reminder_id"):
        if key in normalized and normalized[key] is not None:
            normalized[key] = str(normalized[key])
    return normalized


def _get_firebase_uid(current_user: dict) -> str:
    uid = current_user.get("sub") or current_user.get("uid")
    if not uid:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    return uid


async def _require_patient_in_my_care_team(
    caregiver_firebase_uid: str, patient_id: str
) -> None:
    """Ensure the caregiver is actively linked to this patient (care team)."""
    from services.db_service import get_user_uuid, get_my_patients_for_caregiver

    caregiver_uuid = await get_user_uuid(caregiver_firebase_uid)
    patients = await get_my_patients_for_caregiver(caregiver_uuid)
    pid = str(patient_id)
    if not any(
        str(p.get("patient_id", "")) == pid or str(p.get("firebase_uid", "")) == pid
        for p in patients
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized for this patient",
        )


@router.get("", response_model=List[NoteResponse])
async def list_notes(
    request: Request,
    patient_id: str,
    current_user: dict = Depends(get_current_user),
):
    """List all notes for a patient written by the authenticated caregiver."""
    caregiver_id = _get_firebase_uid(current_user)
    try:
        await _require_patient_in_my_care_team(caregiver_id, patient_id)
        notes = await get_notes(caregiver_id, patient_id)
        await log_phi_access(
            caregiver_id,
            patient_id,
            "caregiver_notes_list",
            route=str(request.url.path),
            ip_address=_client_ip(request),
        )
        return [_normalize_note_ids(n) for n in notes]
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error listing notes: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))


@router.post("", response_model=NoteResponse, status_code=status.HTTP_201_CREATED)
async def add_note(
    request: Request,
    data: NoteCreate,
    current_user: dict = Depends(get_current_user),
):
    """Create a new note for a patient (optional link to a visit or reminder on care coordination)."""
    caregiver_id = _get_firebase_uid(current_user)
    try:
        await _require_patient_in_my_care_team(caregiver_id, data.patient_id)
        vid = (data.visit_id or "").strip() or None
        rid = (data.reminder_id or "").strip() or None
        if vid and rid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Link to either visit_id or reminder_id, not both",
            )
        if vid and not await visit_belongs_to_patient(vid, data.patient_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="visit_id is not valid for this patient",
            )
        if rid and not await reminder_belongs_to_patient(rid, data.patient_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="reminder_id is not valid for this patient",
            )
        note = await create_note(
            caregiver_id,
            data.patient_id,
            data.title,
            data.content,
            visit_id=vid,
            reminder_id=rid,
        )
        if not note:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create note")
        await log_phi_access(
            caregiver_id,
            data.patient_id,
            "caregiver_notes_create",
            route=str(request.url.path),
            ip_address=_client_ip(request),
        )
        return _normalize_note_ids(note)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating note: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))


@router.put("/{note_id}", response_model=NoteResponse)
async def edit_note(
    request: Request,
    note_id: str,
    data: NoteUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Update an existing note (only the owning caregiver can edit)."""
    caregiver_id = _get_firebase_uid(current_user)
    try:
        existing = await get_note(note_id, caregiver_id)
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Note not found or not authorized",
            )
        await _require_patient_in_my_care_team(caregiver_id, str(existing["patient_id"]))
        note = await update_note(note_id, caregiver_id, data.title, data.content)
        if not note:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Note not found or not authorized")
        await log_phi_access(
            caregiver_id,
            str(existing["patient_id"]),
            "caregiver_notes_update",
            route=str(request.url.path),
            ip_address=_client_ip(request),
        )
        return _normalize_note_ids(note)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating note: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))


@router.delete("/{note_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_note(
    request: Request,
    note_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Delete a note (only the owning caregiver can delete)."""
    caregiver_id = _get_firebase_uid(current_user)
    try:
        existing = await get_note(note_id, caregiver_id)
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Note not found or not authorized",
            )
        await _require_patient_in_my_care_team(caregiver_id, str(existing["patient_id"]))
        deleted = await delete_note(note_id, caregiver_id)
        if not deleted:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Note not found or not authorized")
        await log_phi_access(
            caregiver_id,
            str(existing["patient_id"]),
            "caregiver_notes_delete",
            route=str(request.url.path),
            ip_address=_client_ip(request),
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting note: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

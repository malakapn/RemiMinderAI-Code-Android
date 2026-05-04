"""
User management routes for authentication
"""
import logging
from fastapi import APIRouter, Depends, HTTPException, Body, Response, status

logger = logging.getLogger(__name__)
from pydantic import BaseModel
from typing import Optional
from services.auth_gateway import get_current_user_jwt as get_current_user
from services.cache_service import get, set, invalidate
from services.db_provider import get_cloud_sql_engine
from services.db_service import (
    ensure_user_exists,
    delete_user_account,
    get_user_language_preferences,
    update_user_language_preferences,
    get_user_uuid,
    get_caregiver_alert_email_enabled,
    set_caregiver_alert_email_enabled,
    sync_caregiver_role_from_active_membership,
)
from sqlalchemy import text

router = APIRouter(prefix="/api/users", tags=["Users"])


def resolve_display_name(full_name: Optional[str]) -> str:
    """
    Centralized display name resolution logic.

    Resolution order:
    1. users.full_name (if non-null and non-empty)
    2. "User" (final fallback)

    Args:
        full_name: The full_name field from database

    Returns:
        Resolved display name (never empty)
    """
    if full_name and full_name.strip():
        return full_name.strip()
    return "User"


class UserResponse(BaseModel):
    id: str
    email: str
    full_name: Optional[str] = None
    display_name: str
    role: str


class CreateUserRequest(BaseModel):
    auth_uid: str
    email: str
    role: str
    full_name: Optional[str] = None


class UpdateRoleRequest(BaseModel):
    role: str


class UserMeResponse(BaseModel):
    full_name: Optional[str] = None
    email: str
    phone: Optional[str] = None
    role: str  # "patient" | "caregiver"


@router.get("/profile")
def get_user_profile(current_user: dict = Depends(get_current_user)):
    """Get current user's profile"""
    # Extract firebase_uid from JWT (Firebase auth only)
    firebase_uid = current_user.get("sub")
    if not firebase_uid:
        raise HTTPException(401, "Invalid token: missing user ID")

    # Cloud SQL query by firebase_uid
    try:
        cache_key = f"user_profile:{firebase_uid}"
        cached = get(cache_key)
        if cached is not None:
            display_name = resolve_display_name(cached.get("full_name"))
            return UserResponse(
                id=str(cached["id"]),
                email=cached["email"],
                full_name=cached.get("full_name"),
                display_name=display_name,
                role=cached.get("db_role"),
            )
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            result = conn.execute(
                text("SELECT id, email, full_name, phone, role FROM users WHERE firebase_uid = :firebase_uid LIMIT 1"),
                {"firebase_uid": firebase_uid}
            )
            row = result.fetchone()

            if not row:
                raise HTTPException(404, "User not found")

            # Resolve display name
            display_name = resolve_display_name(row[2])

            # Convert row to dict matching the expected response format
            user_data = {
                "id": str(row[0]),
                "email": row[1],
                "full_name": row[2],
                "phone": row[3],
                "db_role": row[4],
            }

            set(cache_key, user_data, 600)
            return UserResponse(
                id=user_data["id"],
                email=user_data["email"],
                full_name=user_data.get("full_name"),
                display_name=display_name,
                role=user_data["db_role"],
            )

    except Exception as e:
        raise HTTPException(500, f"Database error: {str(e)}")


@router.post("/")
def create_user_profile(request: CreateUserRequest):
    """Create user profile after signup - SUPABASE AUTH DECOMMISSIONED"""
    # SUPABASE AUTH DECOMMISSIONED: Block all new user creation via Supabase
    raise HTTPException(
        status_code=410,  # Gone
        detail="Supabase authentication is no longer available for new users. Please use modern authentication methods."
    )


@router.put("/{target_firebase_uid}/role")
def update_user_role(target_firebase_uid: str, request: UpdateRoleRequest, current_user: dict = Depends(get_current_user)):
    """Update user role - only allow users to update their own role"""
    current_firebase_uid = current_user.get("sub")
    if not current_firebase_uid:
        raise HTTPException(401, "Invalid token: missing user ID")

    # Only allow users to update their own role
    if current_firebase_uid != target_firebase_uid:
        raise HTTPException(403, "You can only update your own role")

    # Validate role and map 'patient' to 'user' for database compatibility
    if request.role not in ["patient", "caregiver"]:
        raise HTTPException(400, "Invalid role. Must be 'patient' or 'caregiver'")

    # Map patient to user for database storage (database constraint only allows 'user', 'caregiver')
    db_role = "user" if request.role == "patient" else request.role

    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            # Update user role
            update_result = conn.execute(
                text("UPDATE users SET role = :role WHERE firebase_uid = :firebase_uid"),
                {"role": db_role, "firebase_uid": target_firebase_uid}
            )
            conn.commit()

            if update_result.rowcount == 0:
                raise HTTPException(404, "User not found")

            # Return updated user data
            result = conn.execute(
                text("SELECT id, email, full_name, role FROM users WHERE firebase_uid = :firebase_uid LIMIT 1"),
                {"firebase_uid": target_firebase_uid}
            )
            row = result.fetchone()

            if not row:
                raise HTTPException(404, "User not found after update")

            # Resolve display name
            display_name = resolve_display_name(row[2])

            # Convert to response format
            user_data = {
                "id": str(row[0]),
                "email": row[1],
                "full_name": row[2],
                "display_name": display_name,
                "role": row[3]
            }

            invalidate(f"user_profile:{target_firebase_uid}")
            return UserResponse(**user_data)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(500, f"Database error: {str(e)}")


class BootstrapRequest(BaseModel):
    full_name: Optional[str] = None
    # Client-selected role at sign-up / OAuth ("patient" | "caregiver"). Persisted on create
    # and used to upgrade legacy "user" rows to caregiver when the user picks caregiver.
    app_role: Optional[str] = None


@router.post("/bootstrap")
async def bootstrap_user(
    request: Optional[BootstrapRequest] = Body(default=None),
    current_user: dict = Depends(get_current_user)
):
    """Bootstrap user in Cloud SQL after Firebase authentication"""
    firebase_uid = current_user.get("sub")
    if not firebase_uid:
        raise HTTPException(401, "Invalid token: missing user ID")

    email = current_user.get("email")
    if not email:
        raise HTTPException(400, "Email missing from Firebase token")

    # Extract name from Firebase token if available
    firebase_name = current_user.get("name")

    # Safely read request full_name
    request_full_name = request.full_name if request else None
    app_role = (request.app_role if request else None) or None
    if app_role is not None and app_role not in ("patient", "caregiver"):
        raise HTTPException(
            status_code=400,
            detail="Invalid app_role. Must be 'patient' or 'caregiver'.",
        )

    try:
        created = await ensure_user_exists(
            firebase_uid,
            email,
            request_full_name,
            firebase_name,
            app_role=app_role,
        )

        if created:
            return {"status": "created"}

        return {"status": "exists"}

    except Exception as e:
        raise HTTPException(500, f"Bootstrap failed: {str(e)}")


@router.get("/me", response_model=UserMeResponse)
async def get_current_user_profile(current_user: dict = Depends(get_current_user)):
    """Get current user's profile information"""
    firebase_uid = current_user.get("sub")
    if not firebase_uid:
        raise HTTPException(401, "Invalid token: missing user ID")

    try:
        await sync_caregiver_role_from_active_membership(firebase_uid)
        cache_key = f"user_profile:{firebase_uid}"
        cached = get(cache_key)
        if cached is not None:
            db_role = cached.get("db_role")
            api_role = "patient" if db_role == "user" else db_role
            return UserMeResponse(
                full_name=cached.get("full_name"),
                email=cached["email"],
                phone=cached.get("phone"),
                role=api_role,
            )
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            result = conn.execute(
                text("SELECT id, full_name, email, phone, role FROM users WHERE firebase_uid = :firebase_uid LIMIT 1"),
                {"firebase_uid": firebase_uid}
            )
            row = result.fetchone()

            if not row:
                raise HTTPException(404, "User not found")

            user_id, full_name, email, phone, db_role = row

            # Map database role to API role
            api_role = "patient" if db_role == "user" else db_role

            user_data = {
                "id": str(user_id),
                "email": email,
                "full_name": full_name,
                "phone": phone,
                "db_role": db_role,
            }
            set(cache_key, user_data, 600)
            return UserMeResponse(
                full_name=full_name,
                email=email,
                phone=phone,
                role=api_role,
            )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(500, f"Failed to get user profile: {str(e)}")


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_current_user_account(
    current_user: dict = Depends(get_current_user),
):
    """
    Permanently delete the authenticated user's account and related data.
    """
    firebase_uid = current_user.get("sub")
    if not firebase_uid:
        raise HTTPException(401, "Invalid token: missing user ID")

    deleted_user_id = await delete_user_account(firebase_uid)
    if not deleted_user_id:
        raise HTTPException(404, "User not found")

    invalidate(f"user_profile:{firebase_uid}")
    invalidate(f"user_uuid:{firebase_uid}")
    invalidate(f"language_prefs:{deleted_user_id}")
    invalidate(f"care_team_my_invites:{deleted_user_id}")
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# =========================================
# Language Preferences Models
# =========================================

class LanguagePreferencesResponse(BaseModel):
    app_language: str
    visit_language: str


class UpdateLanguagePreferencesRequest(BaseModel):
    app_language: str
    visit_language: str


class UpdatePhoneRequest(BaseModel):
    phone: Optional[str] = None


class UpdatePhoneResponse(BaseModel):
    phone: Optional[str] = None


# =========================================
# Language Preferences Endpoints
# =========================================

@router.get("/language-preferences", response_model=LanguagePreferencesResponse)
@router.get("/me/language-preferences", response_model=LanguagePreferencesResponse)
async def get_language_preferences(current_user: dict = Depends(get_current_user)):
    """
    Get user's language preferences.

    Returns:
    {
      "app_language": "en",
      "visit_language": "es"
    }

    curl -X GET "http://localhost:8000/api/users/language-preferences" \
         -H "Authorization: Bearer YOUR_JWT_TOKEN"
    """
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid user authentication")

        user_uuid = await get_user_uuid(firebase_uid)

        cache_key = f"language_prefs:{user_uuid}"
        cached = get(cache_key)
        if cached is not None:
            return LanguagePreferencesResponse(**cached)
        preferences = await get_user_language_preferences(user_uuid)
        if preferences is None:
            raise HTTPException(status_code=404, detail="User not found")

        set(cache_key, preferences, 1800)
        return LanguagePreferencesResponse(**preferences)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get language preferences: {str(e)}")
        raise HTTPException(500, f"Failed to get language preferences: {str(e)}")


@router.put("/language-preferences")
@router.put("/me/language-preferences")
async def update_language_preferences(
    request: UpdateLanguagePreferencesRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Update user's language preferences.

    Body:
    {
      "app_language": "es",
      "visit_language": "en"
    }

    curl -X PUT "http://localhost:8000/api/users/language-preferences" \
         -H "Authorization: Bearer YOUR_JWT_TOKEN" \
         -H "Content-Type: application/json" \
         -d '{"app_language": "es", "visit_language": "en"}'
    """
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid user authentication")

        user_uuid = await get_user_uuid(firebase_uid)

        success = await update_user_language_preferences(
            firebase_uid=user_uuid,
            app_language=request.app_language,
            visit_language=request.visit_language
        )

        if not success:
            raise HTTPException(status_code=404, detail="User not found")

        invalidate(f"language_prefs:{user_uuid}")
        return {"status": "updated"}

    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to update language preferences: {str(e)}")
        raise HTTPException(500, f"Failed to update language preferences: {str(e)}")


@router.put("/me/name")
async def update_user_name(
    body: dict = Body(...),
    current_user: dict = Depends(get_current_user)
):
    """Update the current user's full name."""
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid user authentication")
        full_name = (body.get("full_name") or "").strip()
        if not full_name:
            raise HTTPException(status_code=400, detail="full_name is required")
        from services.cloud_sql_engine import get_cloud_sql_engine
        from sqlalchemy import text
        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            conn.execute(
                text("UPDATE users SET full_name = :name WHERE firebase_uid = :uid"),
                {"name": full_name, "uid": firebase_uid},
            )
        from services.cache_service import invalidate
        invalidate(f"user_me:{firebase_uid}")
        return {"full_name": full_name}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update name: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/me/phone", response_model=UpdatePhoneResponse)
async def update_user_phone(
    request: UpdatePhoneRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Update current user's phone number.

    Body:
    {
      "phone": "+919999999999"
    }

    Returns:
    {
      "phone": "+919999999999"
    }

    curl -X PUT "http://localhost:8000/api/users/me/phone" \
         -H "Authorization: Bearer YOUR_JWT_TOKEN" \
         -H "Content-Type: application/json" \
         -d '{"phone": "+919999999999"}'
    """
    try:
        firebase_uid = current_user.get("sub")
        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid user authentication")

        # Validate phone input
        phone_to_save = None
        if request.phone is not None:
            phone_str = request.phone.strip()
            if phone_str and len(phone_str) < 8:
                raise HTTPException(status_code=400, detail="Phone number must be at least 8 characters long")
            phone_to_save = phone_str if phone_str else None

        # Update phone in database
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            result = conn.execute(
                text("UPDATE users SET phone = :phone WHERE firebase_uid = :firebase_uid"),
                {"phone": phone_to_save, "firebase_uid": firebase_uid}
            )
            conn.commit()

            if result.rowcount == 0:
                raise HTTPException(status_code=404, detail="User not found")

        invalidate(f"user_profile:{firebase_uid}")
        return UpdatePhoneResponse(phone=phone_to_save)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update user phone: {str(e)}")
        raise HTTPException(500, f"Failed to update phone: {str(e)}")


class CaregiverAlertEmailPreferenceResponse(BaseModel):
    caregiver_alert_email_enabled: bool


class CaregiverAlertEmailPreferenceUpdate(BaseModel):
    caregiver_alert_email_enabled: bool


@router.get(
    "/me/notification-preferences",
    response_model=CaregiverAlertEmailPreferenceResponse,
)
async def get_notification_preferences(current_user: dict = Depends(get_current_user)):
    """
    Caregiver alert email opt-in (synced with mobile Profile).
    When false, SES caregiver alert emails are skipped for this account (if CAREGIVER_ALERT_EMAIL is enabled).
    """
    firebase_uid = current_user.get("sub")
    if not firebase_uid:
        raise HTTPException(status_code=401, detail="Invalid user authentication")
    enabled = await get_caregiver_alert_email_enabled(firebase_uid)
    return CaregiverAlertEmailPreferenceResponse(
        caregiver_alert_email_enabled=enabled
    )


@router.put(
    "/me/notification-preferences",
    response_model=CaregiverAlertEmailPreferenceResponse,
)
async def put_notification_preferences(
    body: CaregiverAlertEmailPreferenceUpdate,
    current_user: dict = Depends(get_current_user),
):
    firebase_uid = current_user.get("sub")
    if not firebase_uid:
        raise HTTPException(status_code=401, detail="Invalid user authentication")
    await set_caregiver_alert_email_enabled(
        firebase_uid, body.caregiver_alert_email_enabled
    )
    invalidate(f"user_profile:{firebase_uid}")
    return CaregiverAlertEmailPreferenceResponse(
        caregiver_alert_email_enabled=body.caregiver_alert_email_enabled
    )
"""
Minimal Cloud SQL service for audio/image upload lifecycle.
Only contains functions actively used by upload endpoints.
"""

import json
import logging
import secrets
from typing import Optional, Dict, Any
from fastapi import HTTPException
from .cloud_sql_engine import get_cloud_sql_engine
from sqlalchemy import text
from .ai.vertex_gemini_service import GEMINI_MODEL
from services.cache_service import get_or_set

logger = logging.getLogger(__name__)


async def get_user_uuid(firebase_uid: str) -> str:
    """
    Validate Firebase UID exists in users table and return it.
    """
    try:
        cache_key = f"user_uuid:{firebase_uid}"

        def _load_user_uuid() -> str:
            engine = get_cloud_sql_engine()
            with engine.connect() as conn:
                query = text("""
                    SELECT firebase_uid FROM users WHERE firebase_uid = :firebase_uid
                """)

                result = conn.execute(query, {"firebase_uid": firebase_uid})
                row = result.fetchone()

                if not row:
                    raise HTTPException(status_code=404, detail=f"User not found for Firebase UID {firebase_uid}")

                return str(row[0])

        return get_or_set(cache_key, 1800, _load_user_uuid)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error validating Firebase UID {firebase_uid}: {e}")
        raise


async def get_user_email(user_id: str) -> str:
    """
    Get the user's email from Cloud SQL by user ID.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            query = text("""
                SELECT email FROM users WHERE firebase_uid = :user_id
            """)
            result = conn.execute(query, {"user_id": user_id})
            row = result.fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="User not found")
            return str(row[0])
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting user email for user_id={user_id}: {e}")
        raise


async def save_raw_transcript(
    visit_id: str,
    user_id: str,
    transcript: str,
    confidence: float | None = None,
    language: str | None = None
) -> str:
    """Save raw STT transcript to visit_transcripts table.

    Returns the transcript_id of the saved record.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            # Update existing record with transcript (only guaranteed columns)
            update_query = text("""
                UPDATE visit_transcripts
                SET transcript_text = :transcript
                WHERE visit_id = :visit_id
            """)

            conn.execute(update_query, {
                "transcript": transcript,
                "visit_id": visit_id
            })

            # Get the transcript_id for the updated record
            select_query = text("""
                SELECT transcript_id FROM visit_transcripts
                WHERE visit_id = :visit_id
            """)

            result = conn.execute(select_query, {"visit_id": visit_id})
            row = result.fetchone()

            if not row:
                raise HTTPException(status_code=404, detail=f"No transcript record found for visit {visit_id}")

            transcript_id = str(row[0])
            conn.commit()
            logger.info(f"Saved transcript for visit {visit_id}: {len(transcript)} characters, transcript_id: {transcript_id}")

            return transcript_id

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error saving transcript for visit {visit_id}: {e}")
        raise


async def get_audio_gcs_url(visit_id: str, user_id: str) -> str:
    """
    Fetch audio_url for a visit from Cloud SQL only.
    No Supabase.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            # Query visit_transcripts table for audio_url
            query = text("""
                SELECT audio_url FROM visit_transcripts
                WHERE visit_id = :visit_id AND user_id = :user_id
            """)

            result = conn.execute(query, {"visit_id": visit_id, "user_id": user_id})
            row = result.fetchone()

            if not row or not row[0]:
                raise HTTPException(status_code=404, detail=f"No audio file found for visit {visit_id}")

            return str(row[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching audio URL for visit {visit_id}: {e}")
        raise


async def get_user_by_email(email: str) -> Optional[dict]:
    """
    Fetch user by email (citext match). Used for invite email deep-link accept.
    Returns id, firebase_uid, email, full_name or None.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            query = text("""
                SELECT id, firebase_uid, email, full_name
                FROM users
                WHERE email = :email
                LIMIT 1
            """)
            result = conn.execute(query, {"email": email.strip()})
            row = result.fetchone()
            if not row:
                return None
            if hasattr(row, "_mapping"):
                return dict(row._mapping)
            return {
                "id": row[0],
                "firebase_uid": row[1],
                "email": row[2],
                "full_name": row[3],
            }
    except Exception as e:
        logger.error(f"Error fetching user by email={email}: {e}")
        raise


async def ensure_user_exists(
    firebase_uid: str,
    email: str,
    request_full_name: Optional[str] = None,
    firebase_name: Optional[str] = None,
    role: str = "user",
) -> bool:
    """
    Ensure a user row exists in Cloud SQL.
    Returns True if created, False if already exists.
    Populates full_name if empty using request or Firebase token data.
    """
    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        # Check if user exists by firebase_uid
        result = conn.execute(
            text("SELECT id, full_name FROM users WHERE firebase_uid = :firebase_uid"),
            {"firebase_uid": firebase_uid},
        )
        existing_user = result.fetchone()

        if existing_user:
            # User exists - update full_name if empty
            user_id, current_full_name = existing_user
            if not current_full_name or current_full_name.strip() == "":
                # Determine name to use
                name_to_set = None
                if request_full_name and request_full_name.strip():
                    name_to_set = request_full_name.strip()
                elif firebase_name and firebase_name.strip():
                    name_to_set = firebase_name.strip()

                # Update if we have a name to set
                if name_to_set:
                    conn.execute(
                        text("UPDATE users SET full_name = :full_name WHERE id = :user_id"),
                        {"full_name": name_to_set, "user_id": user_id},
                    )
            return False

        # User doesn't exist - create new user
        # Determine full_name for new user
        full_name = None
        if request_full_name and request_full_name.strip():
            full_name = request_full_name.strip()
        elif firebase_name and firebase_name.strip():
            full_name = firebase_name.strip()

        conn.execute(
            text("""
                INSERT INTO users (firebase_uid, email, full_name, role, is_active)
                VALUES (:firebase_uid, :email, :full_name, :role, true)
            """),
            {
                "firebase_uid": firebase_uid,
                "email": email,
                "full_name": full_name,
                "role": role,
            },
        )
        return True


async def get_transcript_text(transcript_id: str) -> str:
    """
    Fetch raw transcript text from visit_transcripts table.
    Used by AI pipeline to get text for summarization.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            query = text("""
                SELECT transcript_text FROM visit_transcripts
                WHERE transcript_id = :transcript_id
            """)

            result = conn.execute(query, {"transcript_id": transcript_id})
            row = result.fetchone()

            if not row or not row[0]:
                raise HTTPException(status_code=404, detail=f"No transcript text found for transcript_id {transcript_id}")

            return str(row[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching transcript text for transcript_id {transcript_id}: {e}")
        raise


async def insert_ai_summary_log(transcript_id: str, visit_id: str, user_id: str, summary_text: str, structured_data: dict = None) -> str:
    """
    Insert AI-generated summary into summaries_log table with structured data.
    Used by AI pipeline to persist generated summaries.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            insert_query = text("""
                INSERT INTO summaries_log
                (transcript_id, visit_id, user_id, model_name, summary_text, structured_data_json, cost_usd)
                VALUES (:transcript_id, :visit_id, :user_id, :model, :summary, :structured_data, :cost)
                RETURNING id
            """)

            # Convert structured_data dict to JSON string if provided
            structured_data_json = None
            if structured_data is not None:
                structured_data_json = json.dumps(structured_data)

            result = conn.execute(insert_query, {
                "transcript_id": transcript_id,
                "visit_id": visit_id,
                "user_id": user_id,
                "model": GEMINI_MODEL,  # Updated to use structured model
                "summary": summary_text,
                "structured_data": structured_data_json,  # JSON string for JSONB column
                "cost": 0.001  # Placeholder cost, should be calculated properly
            })

            from services.cache_service import invalidate
            invalidate(f"summaries_list:{user_id}")
            row = result.fetchone()
            summary_id = str(row[0]) if row and row[0] else ""
            logger.info(f"Inserted AI summary with structured data for transcript {transcript_id}")
            return summary_id

    except Exception as e:
        logger.error(f"Error inserting AI summary for transcript {transcript_id}: {e}")
        raise


async def update_visit_with_structured_data(visit_id: str, doctor_name: str = None, specialty: str = None, title: str = None) -> None:
    """
    Update visit table with structured data extracted from AI summary.
    Only updates fields that are provided and not None.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            # Build dynamic update query based on provided fields
            update_fields = []
            update_values = {"visit_id": visit_id}

            if doctor_name is not None:
                update_fields.append("doctor = :doctor")
                update_values["doctor"] = doctor_name

            if specialty is not None:
                update_fields.append("specialty = :specialty")
                update_values["specialty"] = specialty

            if title is not None:
                update_fields.append("title = :title")
                update_values["title"] = title

            if not update_fields:
                logger.info(f"No structured data fields to update for visit {visit_id}")
                return

            update_query = text(f"""
                UPDATE visits
                SET {', '.join(update_fields)}
                WHERE id = :visit_id
            """)

            logger.info(
                "Updating visit %s with fields: %s",
                visit_id,
                ", ".join(update_values.keys()),
            )
            conn.execute(update_query, update_values)
            logger.info(f"Updated visit {visit_id} with structured data: {list(update_values.keys())}")

    except Exception as e:
        logger.error(f"Error updating visit {visit_id} with structured data: {e}")
        raise


async def delete_user_summary(summary_id: str, user_id: str) -> bool:
    """
    Delete a summary from summaries_log table.
    Only allows deletion if the summary belongs to the specified user.

    Args:
        summary_id: The UUID of the summary to delete
        user_id: The UUID of the user (to verify ownership)

    Returns:
        bool: True if summary was deleted, False if not found or not owned by user

    Raises:
        Exception: If database operation fails
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            # Delete query that checks ownership
            delete_query = text("""
                DELETE FROM summaries_log
                WHERE id = :summary_id AND user_id = :user_id
            """)

            result = conn.execute(delete_query, {
                "summary_id": summary_id,
                "user_id": user_id,
            })

            deleted_count = result.rowcount
            logger.info(f"Deleted {deleted_count} summary rows for summary_id={summary_id}, user_id={user_id}")

            return deleted_count > 0

    except Exception as e:
        logger.error(f"Error deleting summary {summary_id} for user {user_id}: {e}")
        raise


async def get_latest_ai_summary_for_visit(visit_id: str, user_id: str) -> Optional[str]:
    """
    Get the latest AI-generated summary for a visit from summaries_log table.
    Returns summary_text if exists, None if not found.
    Used by visit summary API to fetch processed summaries.
    """
    try:
        logger.info(f"Querying summaries_log for visit_id={visit_id}, user_id={user_id}")

        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            query = text("""
                SELECT summary_text, created_at FROM summaries_log
                WHERE visit_id = :visit_id AND user_id = :user_id
                ORDER BY created_at DESC
                LIMIT 1
            """)

            result = conn.execute(query, {"visit_id": visit_id, "user_id": user_id})
            row = result.fetchone()

            if row and row[0]:
                logger.info(f"Found summary for visit_id={visit_id}, user_id={user_id}: created_at={row[1]}")
                return str(row[0])
            else:
                logger.info(f"No summary found for visit_id={visit_id}, user_id={user_id}")

            return None

    except Exception as e:
        logger.error(f"Error fetching AI summary for visit {visit_id}: {e}")
        raise


async def get_latest_ai_structured_summary_for_visit(visit_id: str, user_id: str) -> Optional[dict]:
    """
    Get the latest structured AI summary for a visit from summaries_log table.
    Returns structured_data_json if exists, None if not found.
    Used by visit summary API to fetch structured summaries.
    """
    try:
        logger.info(f"Querying summaries_log structured data for visit_id={visit_id}, user_id={user_id}")

        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            query = text("""
                SELECT structured_data_json, created_at FROM summaries_log
                WHERE visit_id = :visit_id AND user_id = :user_id
                ORDER BY created_at DESC
                LIMIT 1
            """)

            result = conn.execute(query, {"visit_id": visit_id, "user_id": user_id})
            row = result.fetchone()

            if row and row[0]:
                logger.info(
                    "Found structured summary for visit_id=%s, user_id=%s: created_at=%s",
                    visit_id,
                    user_id,
                    row[1],
                )
                structured_data = row[0]
                if isinstance(structured_data, str):
                    structured_data = json.loads(structured_data)
                return structured_data
            else:
                logger.info(f"No structured summary found for visit_id={visit_id}, user_id={user_id}")

            return None

    except Exception as e:
        logger.error(f"Error fetching structured AI summary for visit {visit_id}: {e}")
        raise


async def get_user_summaries(user_id: str) -> list[dict]:
    """
    Get all summaries for a user by joining summaries_log and visits tables.
    Returns list of summary objects with visit metadata, ordered by newest first.
    """
    try:
        logger.info(f"Fetching summaries for user_id={user_id}")

        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            query = text("""
                SELECT
                    s.id AS summary_id,
                    s.visit_id,
                    s.created_at AS summary_created_at,
                    s.model_name,
                    s.summary_text,
                    v.doctor AS doctor_name,
                    v.specialty AS specialty,
                    v.title AS title,
                    s.created_at AS visit_date
                FROM summaries_log s
                JOIN visits v ON v.id = s.visit_id
                WHERE s.user_id = :user_id
                ORDER BY s.created_at DESC;
            """)

            result = conn.execute(query, {"user_id": user_id})
            rows = result.fetchall()

            summaries = []
            for row in rows:
                summary_id, visit_id, summary_created_at, model_name, summary_text, doctor_name, specialty, title, visit_date = row

                # Truncate summary_text to ~160 characters for preview
                summary_preview = summary_text[:160] + "..." if len(summary_text) > 160 else summary_text

                summaries.append({
                    "summary_id": str(summary_id),
                    "visit_id": str(visit_id),
                    "doctor_name": doctor_name,
                    "specialty": specialty,
                    "title": title,
                    "visit_date": str(visit_date) if visit_date else None,
                    "summary_created_at": str(summary_created_at),
                    "summary_preview": summary_preview,
                    "model_name": model_name,
                })

            logger.info(f"Found {len(summaries)} summaries for user_id={user_id}")
            return summaries

    except Exception as e:
        logger.error(f"Error fetching user summaries for user_id={user_id}: {e}")
        raise


async def get_user_language_preferences(firebase_uid: str) -> dict:
    """
    Get user's language preferences.

    Returns:
    {
      "app_language": "en",
      "visit_language": "en"
    }
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            query = text("""
                SELECT app_language, visit_language
                FROM users
                WHERE firebase_uid = :firebase_uid
            """)

            result = conn.execute(query, {"firebase_uid": firebase_uid})
            row = result.fetchone()

            if not row:
                return None

            # Handle both tuple and Row objects safely
            if hasattr(row, '_mapping'):
                # SQLAlchemy Row object with column names
                app_language = row._mapping.get('app_language', 'en')
                visit_language = row._mapping.get('visit_language', 'en')
            else:
                # Tuple unpacking
                app_language, visit_language = row

            preferences = {
                "app_language": app_language or 'en',
                "visit_language": visit_language or 'en'
            }

            return preferences

    except Exception as e:
        logger.error(f"Error getting language preferences for firebase_uid={firebase_uid}: {e}")
        raise


async def update_user_language_preferences(firebase_uid: str, app_language: str, visit_language: str) -> bool:
    """
    Update user's language preferences.

    Returns:
        True if update was successful, False if user not found
    """
    try:
        # Simple validation
        if not app_language or not visit_language:
            raise ValueError("App language and visit language are required")

        if len(app_language) > 10 or len(visit_language) > 10:
            raise ValueError("Language codes must be 10 characters or less")

        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            query = text("""
                UPDATE users
                SET app_language = :app_language,
                    visit_language = :visit_language,
                    updated_at = now()
                WHERE firebase_uid = :firebase_uid
            """)

            result = conn.execute(query, {
                "firebase_uid": firebase_uid,
                "app_language": app_language,
                "visit_language": visit_language
            })

            success = result.rowcount > 0
            return success

    except Exception as e:
        logger.error(f"Error updating language preferences for firebase_uid={firebase_uid}: {e}")
        raise


async def create_care_team_invitation(
    patient_id: str,
    invitee_email: str,
    role: str,
    permission: str,
    token: str,
    invited_by_user_id: str | None = None,
    expires_at: str | None = None,
) -> str:
    """
    Create a new care team invitation and a pending shadow row in care_team_members.
    Returns the invitation ID.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            query_inv = text("""
                INSERT INTO care_team_invitations
                (patient_id, invitee_email, role, permission, status, token, invited_by_user_id, expires_at)
                VALUES (:patient_id, :invitee_email, :role, :permission, 'pending', :token, :invited_by_user_id, :expires_at)
                RETURNING id
            """)
            result_inv = conn.execute(query_inv, {
                "patient_id": patient_id,
                "invitee_email": invitee_email,
                "role": role,
                "permission": permission,
                "token": token,
                "invited_by_user_id": invited_by_user_id,
                "expires_at": expires_at,
            })
            row_inv = result_inv.fetchone()
            if not row_inv:
                raise Exception("Failed to create care team invitation")
            inv_id = str(row_inv[0])

            query_mem = text("""
                INSERT INTO care_team_members
                (patient_id, member_user_id, role, permission, status, invited_by_user_id, invitee_email)
                VALUES (:patient_id, NULL, :role, :permission, 'pending', :invited_by_user_id, :invitee_email)
            """)
            conn.execute(query_mem, {
                "patient_id": patient_id,
                "role": role,
                "permission": permission,
                "invited_by_user_id": invited_by_user_id,
                "invitee_email": invitee_email,
            })
            return inv_id
    except Exception as e:
        logger.error(f"Error creating care team invitation for patient_id={patient_id}: {e}")
        raise


async def get_care_team_invitation_by_token(token: str) -> Optional[dict]:
    """
    Fetch a care team invitation by token.
    Returns invitation data if found, otherwise None.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            query = text("""
                SELECT
                    id,
                    patient_id,
                    invitee_email,
                    token,
                    role,
                    permission,
                    status,
                    invited_by_user_id,
                    accepted_by_user_id,
                    expires_at,
                    created_at,
                    accepted_at
                FROM care_team_invitations
                WHERE token = :token
                LIMIT 1
            """)
            result = conn.execute(query, {"token": token})
            row = result.fetchone()
            if not row:
                return None
            if hasattr(row, "_mapping"):
                return dict(row._mapping)
            return {
                "id": row[0],
                "patient_id": row[1],
                "invitee_email": row[2],
                "token": row[3],
                "role": row[4],
                "permission": row[5],
                "status": row[6],
                "invited_by_user_id": row[7],
                "accepted_by_user_id": row[8],
                "expires_at": row[9],
                "created_at": row[10],
                "accepted_at": row[11],
            }
    except Exception as e:
        logger.error(f"Error fetching care team invitation by token: {e}")
        raise


async def mark_care_team_invitation_accepted(
    invitation_id: str,
    accepted_by_user_id: Optional[str],
) -> bool:
    """
    Mark invitation accepted and reconcile the pending care_team_members shadow row.
    accepted_by_user_id may be None when the invitee has not registered yet (email-click flow).
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            logger.info(
                "Updating invitation: id=%s, accepted_by_user_id=%s",
                invitation_id,
                accepted_by_user_id,
            )
            query_inv = text("""
                UPDATE care_team_invitations
                SET status = 'accepted',
                    accepted_by_user_id = :accepted_by_user_id,
                    accepted_at = now()
                WHERE id = :invitation_id
                RETURNING patient_id, invitee_email, invited_by_user_id
            """)
            result_inv = conn.execute(query_inv, {
                "invitation_id": invitation_id,
                "accepted_by_user_id": accepted_by_user_id,
            })
            row_inv = result_inv.fetchone()
            if not row_inv:
                return False

            if hasattr(row_inv, "_mapping"):
                rd = dict(row_inv._mapping)
                pat_id = rd["patient_id"]
                inv_email = rd["invitee_email"]
            else:
                pat_id = row_inv[0]
                inv_email = row_inv[1]

            mem_status = "active" if accepted_by_user_id else "accepted"
            query_mem = text("""
                UPDATE care_team_members
                SET status = :status,
                    member_user_id = :member_user_id
                WHERE patient_id = :patient_id
                  AND invitee_email = :email
                  AND status = 'pending'
            """)
            conn.execute(query_mem, {
                "patient_id": pat_id,
                "email": inv_email,
                "status": mem_status,
                "member_user_id": accepted_by_user_id,
            })
            return True
    except Exception as e:
        logger.error(f"Error marking care team invitation accepted: {e}", exc_info=True)
        raise


async def add_care_team_member(
    patient_id: str,
    member_user_id: str,
    role: str,
    permission: str,
    status: str,
    invited_by_user_id: str | None = None,
) -> Optional[str]:
    """
    Add a care team member.
    Returns the member ID if created, otherwise None.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            query = text("""
                INSERT INTO care_team_members
                (patient_id, member_user_id, role, permission, status, invited_by_user_id)
                VALUES (:patient_id, :member_user_id, :role, :permission, :status, :invited_by_user_id)
                ON CONFLICT (patient_id, member_user_id) DO NOTHING
                RETURNING id
            """)
            result = conn.execute(query, {
                "patient_id": patient_id,
                "member_user_id": member_user_id,
                "role": role,
                "permission": permission,
                "status": status,
                "invited_by_user_id": invited_by_user_id,
            })
            row = result.fetchone()
            return str(row[0]) if row else None
    except Exception as e:
        logger.error(f"Error adding care team member for patient_id={patient_id}: {e}")
        raise


async def get_care_team_membership(
    patient_id: str,
    member_user_id: str,
) -> Optional[dict]:
    """
    Fetch an active care team membership for a patient/member pair.
    Returns membership data if found, otherwise None.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            query = text("""
                SELECT
                    id,
                    patient_id,
                    member_user_id,
                    role,
                    permission,
                    status,
                    invited_by_user_id,
                    created_at,
                    revoked_at
                FROM care_team_members
                WHERE patient_id = :patient_id
                  AND member_user_id = :member_user_id
                  AND status = 'active'
                LIMIT 1
            """)
            result = conn.execute(query, {
                "patient_id": patient_id,
                "member_user_id": member_user_id,
            })
            row = result.fetchone()
            if not row:
                return None
            if hasattr(row, "_mapping"):
                return dict(row._mapping)
            return {
                "id": row[0],
                "patient_id": row[1],
                "member_user_id": row[2],
                "role": row[3],
                "permission": row[4],
                "status": row[5],
                "invited_by_user_id": row[6],
                "created_at": row[7],
                "revoked_at": row[8],
            }
    except Exception as e:
        logger.error(
            "Error fetching care team membership for patient_id=%s, member_user_id=%s: %s",
            patient_id,
            member_user_id,
            e,
        )
        raise


async def get_care_team_members(patient_id: str) -> list[dict]:
    """
    Fetch all care team members for a patient, including user info.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            query = text("""
                SELECT
                    m.id,
                    m.patient_id,
                    m.member_user_id,
                    u.full_name,
                    u.email,
                    m.role,
                    m.permission,
                    m.status,
                    m.invited_by_user_id,
                    m.created_at,
                    m.revoked_at
                FROM care_team_members m
                LEFT JOIN users u ON u.firebase_uid = m.member_user_id
                WHERE m.patient_id = :patient_id
                ORDER BY m.created_at DESC
            """)
            result = conn.execute(query, {"patient_id": patient_id})
            rows = result.fetchall()

            members = []
            for row in rows:
                if hasattr(row, "_mapping"):
                    members.append(dict(row._mapping))
                else:
                    members.append({
                        "id": row[0],
                        "patient_id": row[1],
                        "member_user_id": row[2],
                        "full_name": row[3],
                        "email": row[4],
                        "role": row[5],
                        "permission": row[6],
                        "status": row[7],
                        "invited_by_user_id": row[8],
                        "created_at": row[9],
                        "revoked_at": row[10],
                    })
            return members
    except Exception as e:
        logger.error(f"Error fetching care team members for patient_id={patient_id}: {e}")
        raise


async def get_my_care_team_invitations(user_email: str) -> list[dict]:
    """
    Fetch pending care team invitations for the given email.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            query = text("""
                SELECT
                    i.id,
                    i.patient_id,
                    i.invitee_email,
                    i.role,
                    i.permission,
                    i.status,
                    i.token,
                    i.created_at,
                    u.full_name AS patient_name
                FROM care_team_invitations i
                JOIN users u ON u.firebase_uid = i.patient_id
                WHERE i.invitee_email = :email
                  AND i.status = 'pending'
                ORDER BY i.created_at DESC;
            """)
            result = conn.execute(query, {"email": user_email})
            rows = result.fetchall()
            invitations = []
            for row in rows:
                if hasattr(row, "_mapping"):
                    invitations.append(dict(row._mapping))
                else:
                    invitations.append({
                        "id": row[0],
                        "patient_id": row[1],
                        "invitee_email": row[2],
                        "role": row[3],
                        "permission": row[4],
                        "status": row[5],
                        "token": row[6],
                        "created_at": row[7],
                        "patient_name": row[8],
                    })
            return invitations
    except Exception as e:
        logger.error(f"Error fetching care team invitations for email={user_email}: {e}")
        raise


async def get_care_team_member_by_id(member_id: str) -> Optional[dict]:
    """
    Fetch a care team member by ID.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            query = text("""
                SELECT id, patient_id, member_user_id, role, permission, status
                FROM care_team_members
                WHERE id = :member_id
                LIMIT 1
            """)
            result = conn.execute(query, {"member_id": member_id})
            row = result.fetchone()
            if not row:
                return None
            if hasattr(row, "_mapping"):
                return dict(row._mapping)
            return {
                "id": row[0],
                "patient_id": row[1],
                "member_user_id": row[2],
                "role": row[3],
                "permission": row[4],
                "status": row[5],
            }
    except Exception as e:
        logger.error(f"Error fetching care team member for member_id={member_id}: {e}")
        raise


async def update_care_team_member_permission(
    member_id: str,
    permission: str,
) -> bool:
    """
    Update a care team member's permission.
    Returns True if updated, False if not found.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            query = text("""
                UPDATE care_team_members
                SET permission = :permission
                WHERE id = :member_id
            """)
            result = conn.execute(query, {
                "permission": permission,
                "member_id": member_id,
            })
            return result.rowcount > 0
    except Exception as e:
        logger.error(
            "Error updating care team permission for member_id=%s: %s",
            member_id,
            e,
        )
        raise


async def remove_care_team_member(
    member_id: str,
) -> bool:
    """
    Delete a care team member by ID.
    Returns True if deleted, False if not found.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            query = text("""
                DELETE FROM care_team_members
                WHERE id = :member_id
            """)
            result = conn.execute(query, {
                "member_id": member_id,
            })
            return result.rowcount > 0
    except Exception as e:
        logger.error(
            "Error deleting care team member for member_id=%s: %s",
            member_id,
            e,
        )
        raise


async def get_pending_care_team_invitations(patient_id: str) -> list[dict]:
    """
    Fetch pending care team invitations for a patient.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            query = text("""
                SELECT
                    id,
                    invitee_email,
                    role,
                    permission,
                    status,
                    created_at
                FROM care_team_invitations
                WHERE patient_id = :patient_id
                  AND status = 'pending'
                ORDER BY created_at DESC
            """)
            result = conn.execute(query, {"patient_id": patient_id})
            rows = result.fetchall()
            invitations = []
            for row in rows:
                if hasattr(row, "_mapping"):
                    invitations.append(dict(row._mapping))
                else:
                    invitations.append({
                        "id": row[0],
                        "invitee_email": row[1],
                        "role": row[2],
                        "permission": row[3],
                        "status": row[4],
                        "created_at": row[5],
                    })
            return invitations
    except Exception as e:
        logger.error(
            "Error fetching pending care team invitations for patient_id=%s: %s",
            patient_id,
            e,
        )
        raise


async def cancel_care_team_invitation(
    patient_id: str,
    invitation_id: str,
) -> bool:
    """
    Mark a care team invitation as revoked for a patient.
    Returns True if updated, False if not found or not owned by patient.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            query = text("""
                UPDATE care_team_invitations
                SET status = 'revoked'
                WHERE id = :invitation_id
                  AND patient_id = :patient_id
            """)
            result = conn.execute(query, {
                "invitation_id": invitation_id,
                "patient_id": patient_id,
            })
            return result.rowcount > 0
    except Exception as e:
        logger.error(
            "Error cancelling care team invitation for patient_id=%s, invitation_id=%s: %s",
            patient_id,
            invitation_id,
            e,
        )
        raise


async def resend_care_team_invitation(
    patient_id: str,
    invitation_id: str,
) -> Optional[str]:
    """
    Regenerate token for a pending care team invitation.
    Returns new token if updated, otherwise None.
    """
    try:
        new_token = secrets.token_urlsafe(32)
        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            query = text("""
                UPDATE care_team_invitations
                SET token = :token,
                    created_at = now(),
                    status = 'pending'
                WHERE id = :invitation_id
                  AND patient_id = :patient_id
                  AND status = 'pending'
                RETURNING token
            """)
            result = conn.execute(query, {
                "token": new_token,
                "invitation_id": invitation_id,
                "patient_id": patient_id,
            })
            row = result.fetchone()
            return str(row[0]) if row else None
    except Exception as e:
        logger.error(
            "Error resending care team invitation for patient_id=%s, invitation_id=%s: %s",
            patient_id,
            invitation_id,
            e,
        )
        raise
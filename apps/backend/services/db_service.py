"""
Minimal Cloud SQL service for audio/image upload lifecycle.
Only contains functions actively used by upload endpoints.
"""

import json
import logging
import secrets
from typing import Optional, Dict, Any, List
from datetime import datetime, timezone
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
                    SELECT id FROM users WHERE firebase_uid = :firebase_uid
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


async def get_firebase_uid_from_uuid(internal_uuid: str) -> str:
    """
    Look up Firebase UID from internal user UUID.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            result = conn.execute(
                text("SELECT firebase_uid FROM users WHERE id = CAST(:id AS uuid)"),
                {"id": internal_uuid},
            )
            row = result.fetchone()
            if not row:
                raise HTTPException(status_code=404, detail=f"User not found for UUID {internal_uuid}")
            return str(row[0])
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting firebase_uid for uuid={internal_uuid}: {e}")
        raise


async def get_user_email(user_id: str) -> str:
    """
    Get the user's email from Cloud SQL by internal user UUID.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            query = text("""
                SELECT email FROM users WHERE id = CAST(:user_id AS uuid)
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
    confidence: Optional[float] = None,
    language: Optional[str] = None
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


def _new_user_db_role(app_role: Optional[str], role: Optional[str]) -> str:
    """Map bootstrap app_role or explicit DB role to users.role column."""
    if role is not None and str(role).strip():
        return str(role).strip()
    if (app_role or "").strip().lower() == "caregiver":
        return "caregiver"
    return "user"


def _wants_caregiver_role(app_role: Optional[str], role: Optional[str]) -> bool:
    if (role or "").strip().lower() == "caregiver":
        return True
    return (app_role or "").strip().lower() == "caregiver"


def _maybe_upgrade_user_to_caregiver(
    conn,
    user_id: str,
    current_db_role: str,
    app_role: Optional[str],
    role: Optional[str],
) -> None:
    if str(current_db_role).strip().lower() != "user":
        return
    if not _wants_caregiver_role(app_role, role):
        return
    conn.execute(
        text("UPDATE users SET role = 'caregiver' WHERE id = :user_id"),
        {"user_id": user_id},
    )


async def ensure_user_exists(
    firebase_uid: str,
    email: str,
    request_full_name: Optional[str] = None,
    firebase_name: Optional[str] = None,
    app_role: Optional[str] = None,
    role: Optional[str] = None,
) -> bool:
    """
    Ensure a user row exists in Cloud SQL.
    Returns True if created, False if already exists.
    Populates full_name if empty using request or Firebase token data.

    app_role: 'patient' | 'caregiver' from /api/users/bootstrap.
    role: explicit DB role (e.g. 'caregiver' when accepting a care-team invite).
    If app_role is caregiver, existing rows with role 'user' upgrade to caregiver.
    """
    insert_role = _new_user_db_role(app_role, role)
    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        # Check if user exists by firebase_uid
        result = conn.execute(
            text(
                "SELECT id, full_name, role FROM users WHERE firebase_uid = :firebase_uid"
            ),
            {"firebase_uid": firebase_uid},
        )
        existing_user = result.fetchone()

        if existing_user:
            # User exists - update full_name if empty; optional caregiver upgrade
            user_id, current_full_name, current_db_role = existing_user
            _maybe_upgrade_user_to_caregiver(
                conn, str(user_id), str(current_db_role), app_role, role
            )
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

        # No firebase_uid match yet. If the email already exists, link this
        # Firebase account to the existing row instead of inserting a duplicate.
        email_result = conn.execute(
            text(
                "SELECT id, full_name, firebase_uid, role FROM users WHERE email = :email"
            ),
            {"email": email},
        )
        email_user = email_result.fetchone()

        if email_user:
            user_id, current_full_name, existing_firebase_uid, current_db_role = (
                email_user
            )

            # The email has already been verified by Firebase, so if the Firebase
            # UID changed (for example after the user deleted and recreated their
            # Firebase account), relink the existing backend row instead of
            # treating it as a hard conflict.
            if existing_firebase_uid != firebase_uid:
                conn.execute(
                    text("UPDATE users SET firebase_uid = :firebase_uid WHERE id = :user_id"),
                    {"firebase_uid": firebase_uid, "user_id": user_id},
                )

            _maybe_upgrade_user_to_caregiver(
                conn, str(user_id), str(current_db_role), app_role, role
            )

            # Fill in a name if the existing row doesn't have one yet.
            if not current_full_name or current_full_name.strip() == "":
                name_to_set = None
                if request_full_name and request_full_name.strip():
                    name_to_set = request_full_name.strip()
                elif firebase_name and firebase_name.strip():
                    name_to_set = firebase_name.strip()

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
                INSERT INTO users (
                    firebase_uid, email, full_name, role, is_active,
                    plan, trial_start_date, trial_end_date,
                    summary_count, remivox_interaction_count
                )
                VALUES (
                    :firebase_uid, :email, :full_name, :role, true,
                    'TRIAL', now(), now() + interval '14 days',
                    0, 0
                )
            """),
            {
                "firebase_uid": firebase_uid,
                "email": email,
                "full_name": full_name,
                "role": insert_role,
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


async def delete_user_summary(
    summary_id: str,
    user_id: str,
    firebase_uid: Optional[str] = None,
) -> bool:
    """
    Delete a summary from summaries_log table.
    Only allows deletion if the summary belongs to the specified user.

    Args:
        summary_id: The UUID of the summary to delete
        user_id: The internal users.id UUID (to verify ownership)
        firebase_uid: Firebase UID for rows stored with firebase_uid as user_id

    Returns:
        bool: True if summary was deleted, False if not found or not owned by user

    Raises:
        Exception: If database operation fails
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            # summaries_log.user_id may be internal uuid or firebase_uid depending on pipeline age
            delete_query = text("""
                DELETE FROM summaries_log
                WHERE id = :summary_id
                  AND (
                    user_id::text = :user_id
                    OR (:firebase_uid IS NOT NULL AND user_id::text = :firebase_uid)
                  )
            """)

            result = conn.execute(delete_query, {
                "summary_id": summary_id,
                "user_id": user_id,
                "firebase_uid": firebase_uid,
            })

            deleted_count = result.rowcount
            logger.info(f"Deleted {deleted_count} summary rows for summary_id={summary_id}, user_id={user_id}")

            return deleted_count > 0

    except Exception as e:
        logger.error(f"Error deleting summary {summary_id} for user {user_id}: {e}")
        raise


async def delete_scanned_document(
    visit_id: str,
    user_id: str,
    firebase_uid: Optional[str] = None,
) -> bool:
    """
    Remove a scanned document (image + OCR) for a visit owned by the user.
    Clears image fields on visit_transcripts and deletes the GCS image object.
    """
    try:
        from services.account_purge_service import delete_gcs_urls, delete_visit_media_prefixes

        engine = get_cloud_sql_engine()
        image_urls: list[str] = []
        with engine.begin() as conn:
            rows = conn.execute(
                text("""
                    SELECT image_url
                    FROM visit_transcripts
                    WHERE visit_id = :visit_id
                      AND image_url IS NOT NULL
                      AND (
                        user_id::text = :user_id
                        OR (:firebase_uid IS NOT NULL AND user_id::text = :firebase_uid)
                      )
                """),
                {
                    "visit_id": visit_id,
                    "user_id": user_id,
                    "firebase_uid": firebase_uid,
                },
            ).fetchall()
            image_urls = [str(r[0]) for r in rows if r and r[0]]

            result = conn.execute(
                text("""
                    UPDATE visit_transcripts
                    SET image_url = NULL,
                        image_metadata = NULL,
                        ocr_text = NULL,
                        ocr_status = NULL
                    WHERE visit_id = :visit_id
                      AND image_url IS NOT NULL
                      AND (
                        user_id::text = :user_id
                        OR (:firebase_uid IS NOT NULL AND user_id::text = :firebase_uid)
                      )
                """),
                {
                    "visit_id": visit_id,
                    "user_id": user_id,
                    "firebase_uid": firebase_uid,
                },
            )
            deleted = int(result.rowcount or 0) > 0
            logger.info(
                "Cleared scanned document visit_id=%s user_id=%s rows=%s",
                visit_id,
                user_id,
                result.rowcount,
            )

        if deleted:
            delete_gcs_urls(image_urls)
            # Also clear images/{visit_id}/ prefix used by upload_image.
            delete_visit_media_prefixes([visit_id])

        return deleted
    except Exception as e:
        logger.error(
            "Error deleting scanned document visit_id=%s user_id=%s: %s",
            visit_id,
            user_id,
            e,
        )
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


async def get_user_summaries(
    user_id: str,
    firebase_uid: Optional[str] = None,
) -> list[dict]:
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
                WHERE s.user_id::text = :user_id
                   OR s.user_id::text = :firebase_uid
                ORDER BY s.created_at DESC;
            """)

            result = conn.execute(query, {
                "user_id": user_id,
                "firebase_uid": firebase_uid or user_id,
            })
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


async def get_audio_visits_without_summary(
    user_id: str,
    firebase_uid: Optional[str] = None,
) -> list[dict]:
    """
    Visits with uploaded audio but no summaries_log row yet (processing/failed).
    Shown in Overview so users can open visit details and retry.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            rows = conn.execute(
                text("""
                    SELECT
                        v.id AS visit_id,
                        v.created_at AS visit_date,
                        v.doctor AS doctor_name,
                        v.specialty AS specialty,
                        v.title AS title
                    FROM visits v
                    JOIN visit_transcripts vt ON vt.visit_id = v.id
                    WHERE (v.user_id::text = :user_id OR v.user_id::text = :firebase_uid)
                      AND vt.audio_url IS NOT NULL
                      AND NOT EXISTS (
                        SELECT 1 FROM summaries_log s
                        WHERE s.visit_id = v.id
                          AND (
                            s.user_id::text = :user_id
                            OR s.user_id::text = :firebase_uid
                          )
                      )
                    ORDER BY v.created_at DESC
                """),
                {
                    "user_id": user_id,
                    "firebase_uid": firebase_uid or user_id,
                },
            ).fetchall()

        pending = []
        for row in rows:
            m = row._mapping if hasattr(row, "_mapping") else None
            visit_id = str(m["visit_id"] if m else row[0])
            visit_date = m["visit_date"] if m else row[1]
            doctor_name = m["doctor_name"] if m else row[2]
            specialty = m["specialty"] if m else row[3]
            title = m["title"] if m else row[4]
            pending.append(
                {
                    "summary_id": f"pending-{visit_id}",
                    "visit_id": visit_id,
                    "doctor_name": doctor_name or "Audio Visit",
                    "specialty": specialty or "",
                    "title": title or "Audio Visit",
                    "visit_date": visit_date.isoformat() if visit_date else None,
                    "summary_created_at": visit_date.isoformat() if visit_date else None,
                    "summary_preview": "Summary not ready yet",
                    "model_name": "pending",
                    "is_pending": True,
                }
            )
        return pending
    except Exception as e:
        logger.error(
            "Error fetching pending audio visits for user_id=%s: %s",
            user_id,
            e,
        )
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
                WHERE id::text = :internal_user_id
            """)

            result = conn.execute(query, {"internal_user_id": firebase_uid})
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
        logger.error(f"Error getting language preferences for user_id={firebase_uid}: {e}")
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
                WHERE id::text = :internal_user_id
            """)

            result = conn.execute(query, {
                "internal_user_id": firebase_uid,
                "app_language": app_language,
                "visit_language": visit_language
            })

            success = result.rowcount > 0
            return success

    except Exception as e:
        logger.error(f"Error updating language preferences for user_id={firebase_uid}: {e}")
        raise


async def create_care_team_invitation(
    patient_id: str,
    invitee_email: str,
    role: str,
    permission: str,
    token: str,
    invited_by_user_id: Optional[str] = None,
    expires_at: Optional[str] = None,
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
                VALUES (
                    :patient_id,
                    :invitee_email,
                    :role,
                    :permission,
                    'pending',
                    :token,
                    :invited_by_user_id,
                    :expires_at
                )
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
    invited_by_user_id: Optional[str] = None,
    consent_version: Optional[str] = None,
) -> Optional[str]:
    """
    Add a care team member.
    Returns the member ID if created, otherwise None.
    When consent_version is set, consent_accepted_at is stored (invitation accept flow).
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            query = text("""
                INSERT INTO care_team_members
                (patient_id, member_user_id, role, permission, status, invited_by_user_id,
                 consent_version, consent_accepted_at)
                VALUES (
                    :patient_id,
                    :member_user_id,
                    :role,
                    :permission,
                    :status,
                    :invited_by_user_id,
                    :consent_version,
                    CASE WHEN :consent_version IS NOT NULL THEN timezone('utc', now()) ELSE NULL END
                )
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
                "consent_version": consent_version,
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
                WHERE patient_id::text IN (
                    CAST(:patient_id AS text),
                    COALESCE((SELECT id::text FROM users WHERE firebase_uid = :patient_id LIMIT 1), CAST(:patient_id AS text))
                )
                  AND member_user_id::text IN (
                    CAST(:member_user_id AS text),
                    COALESCE((SELECT id::text FROM users WHERE firebase_uid = :member_user_id LIMIT 1), CAST(:member_user_id AS text))
                )
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
                LEFT JOIN users u ON (
                    u.firebase_uid::text = m.member_user_id::text
                    OR u.id::text = m.member_user_id::text
                )
                WHERE m.patient_id::text IN (
                    CAST(:patient_id AS text),
                    COALESCE((SELECT id::text FROM users WHERE firebase_uid = :patient_id LIMIT 1), CAST(:patient_id AS text))
                )
                  AND m.status = 'active'
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


async def has_pending_care_team_invitation_for_email(email: str) -> bool:
    """
    True if there is at least one pending care-team invite for this address (case-insensitive).
    Used for pre-signup caregiver eligibility (public validate endpoint).
    """
    normalized = (email or "").strip().lower()
    if not normalized:
        return False
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            result = conn.execute(
                text("""
                    SELECT 1
                    FROM care_team_invitations i
                    WHERE LOWER(TRIM(i.invitee_email::text)) = :email
                      AND i.status = 'pending'
                    LIMIT 1
                """),
                {"email": normalized},
            )
            return result.fetchone() is not None
    except Exception as e:
        logger.error("Error checking pending invite for email=%s: %s", email, e)
        raise


async def validate_caregiver_signup_allowed(
    email: str, invite_token: Optional[str] = None
) -> tuple[bool, str]:
    """
    Returns (allowed, reason_code). reason_code is 'ok' or a stable machine string.
    If invite_token is set, it must match a pending invitation for the same email.
    """
    normalized = (email or "").strip().lower()
    if not normalized:
        return False, "email_required"

    if invite_token and str(invite_token).strip():
        inv = await get_care_team_invitation_by_token(str(invite_token).strip())
        if not inv:
            return False, "invalid_token"
        inv_email = (inv.get("invitee_email") or "").strip().lower()
        if inv_email != normalized:
            return False, "email_mismatch"
        if inv.get("status") != "pending":
            return False, "not_pending"
        exp = inv.get("expires_at")
        if exp:
            if isinstance(exp, str):
                try:
                    exp = datetime.fromisoformat(exp.replace("Z", "+00:00"))
                except ValueError:
                    exp = None
            if exp and exp < datetime.now(timezone.utc):
                return False, "expired"
        return True, "ok"

    if await has_pending_care_team_invitation_for_email(normalized):
        return True, "ok"
    return False, "no_pending_invite"


async def get_my_care_team_invitations(user_email: str) -> list[dict]:
    """
    Fetch care team invitations for the invitee email (recent history + pending).
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
                    i.expires_at,
                    u.full_name AS patient_name,
                    inv.full_name AS invited_by_name
                FROM care_team_invitations i
                JOIN users u ON (
                    u.firebase_uid::text = i.patient_id::text
                    OR u.id::text = i.patient_id::text
                )
                LEFT JOIN users inv ON inv.id = i.invited_by_user_id
                WHERE LOWER(TRIM(i.invitee_email::text)) = LOWER(TRIM(:email))
                  AND i.status IN ('pending', 'accepted', 'declined', 'revoked')
                ORDER BY i.created_at DESC
                LIMIT 100;
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
                        "expires_at": row[8],
                        "patient_name": row[9],
                        "invited_by_name": row[10],
                    })
            return invitations
    except Exception as e:
        logger.error(f"Error fetching care team invitations for email={user_email}: {e}")
        raise


async def decline_care_team_invitation_by_invitee(
    invitation_id: str, invitee_email: str
) -> Optional[str]:
    """
    Caregiver declines a pending invitation addressed to invitee_email.
    Returns patient_id (text) if a row was updated, else None.
    """
    normalized = (invitee_email or "").strip().lower()
    if not normalized:
        return None
    try:
        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            result = conn.execute(
                text("""
                    UPDATE care_team_invitations
                    SET status = 'declined'
                    WHERE id = :invitation_id
                      AND LOWER(TRIM(invitee_email::text)) = :email
                      AND status = 'pending'
                    RETURNING patient_id::text
                """),
                {"invitation_id": invitation_id, "email": normalized},
            )
            row = result.fetchone()
            if not row:
                return None
            return str(row[0]) if row[0] is not None else None
    except Exception as e:
        logger.error(
            "Error declining care team invitation id=%s email=%s: %s",
            invitation_id,
            invitee_email,
            e,
        )
        raise


async def delete_user_account(firebase_uid: str) -> Optional[str]:
    """
    Permanently remove the user and all related app data for Play Data Safety:
    Cloud SQL rows, GCS media, Firestore docs, and Firebase Auth.

    Returns internal user id (text) if a user row was deleted, else None.
    """
    if not firebase_uid or not str(firebase_uid).strip():
        return None
    uid = str(firebase_uid).strip()
    try:
        from services.account_purge_service import (
            delete_gcs_urls,
            delete_visit_media_prefixes,
        )
        from services.firebase_account_purge import (
            delete_firebase_auth_user,
            delete_firestore_user_data,
        )

        engine = get_cloud_sql_engine()
        media_urls: list[str] = []
        visit_ids: list[str] = []

        with engine.begin() as conn:
            row = conn.execute(
                text(
                    "SELECT id::text FROM users WHERE firebase_uid = :f LIMIT 1"
                ),
                {"f": uid},
            ).fetchone()
            if not row:
                return None
            user_id = row[0]

            # Collect media URLs / visit IDs before cascading deletes.
            visit_rows = conn.execute(
                text(
                    """
                    SELECT id::text FROM visits
                    WHERE user_id::text = :uid_txt
                    """
                ),
                {"uid_txt": user_id},
            ).fetchall()
            visit_ids = [r[0] for r in visit_rows if r and r[0]]

            transcript_rows = conn.execute(
                text(
                    """
                    SELECT audio_url, image_url
                    FROM visit_transcripts
                    WHERE user_id::text = :uid_txt
                       OR user_id::text = :fb
                       OR visit_id IN (
                            SELECT id FROM visits WHERE user_id::text = :uid_txt
                       )
                    """
                ),
                {"uid_txt": user_id, "fb": uid},
            ).fetchall()
            for tr in transcript_rows:
                if tr[0]:
                    media_urls.append(str(tr[0]))
                if tr[1]:
                    media_urls.append(str(tr[1]))

            recording_rows = conn.execute(
                text(
                    """
                    SELECT object_key FROM visit_recordings
                    WHERE user_id::text = :uid_txt
                    """
                ),
                {"uid_txt": user_id},
            ).fetchall()
            for rr in recording_rows:
                if rr and rr[0]:
                    media_urls.append(str(rr[0]))

            conn.execute(
                text("""
                    DELETE FROM caregiver_notes_audit
                    WHERE note_id IN (
                        SELECT id FROM caregiver_notes
                        WHERE caregiver_id = :fb OR patient_id = :uid_txt
                    )
                """),
                {"fb": uid, "uid_txt": user_id},
            )
            conn.execute(
                text("""
                    DELETE FROM caregiver_notes
                    WHERE caregiver_id = :fb OR patient_id = :uid_txt
                """),
                {"fb": uid, "uid_txt": user_id},
            )

            conn.execute(
                text("DELETE FROM fcm_tokens WHERE user_id = :fb OR user_id = :uid_txt"),
                {"fb": uid, "uid_txt": user_id},
            )

            conn.execute(
                text("""
                    DELETE FROM care_team_invitations
                    WHERE patient_id::text = :uid_txt
                       OR invited_by_user_id::text = :uid_txt
                       OR accepted_by_user_id::text = :uid_txt
                """),
                {"uid_txt": user_id},
            )
            conn.execute(
                text("""
                    DELETE FROM care_team_members
                    WHERE patient_id::text = :uid_txt
                       OR member_user_id::text = :uid_txt
                       OR invited_by_user_id::text = :uid_txt
                """),
                {"uid_txt": user_id},
            )

            conn.execute(
                text("DELETE FROM patient_tasks WHERE user_id::text = :uid_txt"),
                {"uid_txt": user_id},
            )

            # Explicit PHI / product data wipe (covers rows without CASCADE / orphans).
            conn.execute(
                text("""
                    DELETE FROM feedback_log
                    WHERE summary_id IN (
                        SELECT id FROM summaries_log
                        WHERE user_id::text = :uid_txt OR user_id::text = :fb
                    )
                """),
                {"uid_txt": user_id, "fb": uid},
            )
            conn.execute(
                text(
                    "DELETE FROM summaries_log WHERE user_id::text = :uid_txt OR user_id::text = :fb"
                ),
                {"uid_txt": user_id, "fb": uid},
            )
            conn.execute(
                text(
                    """
                    DELETE FROM reminder_logs
                    WHERE user_id::text = :uid_txt
                       OR reminder_id IN (
                            SELECT id FROM reminders WHERE user_id::text = :uid_txt
                       )
                    """
                ),
                {"uid_txt": user_id},
            )
            conn.execute(
                text("DELETE FROM caregiver_alerts WHERE user_id::text = :uid_txt"),
                {"uid_txt": user_id},
            )
            conn.execute(
                text("DELETE FROM reminders WHERE user_id::text = :uid_txt"),
                {"uid_txt": user_id},
            )
            conn.execute(
                text(
                    """
                    DELETE FROM visit_summaries
                    WHERE user_id::text = :uid_txt
                       OR visit_id IN (
                            SELECT id FROM visits WHERE user_id::text = :uid_txt
                       )
                    """
                ),
                {"uid_txt": user_id},
            )
            conn.execute(
                text(
                    """
                    DELETE FROM visit_transcripts
                    WHERE user_id::text = :uid_txt
                       OR user_id::text = :fb
                       OR visit_id IN (
                            SELECT id FROM visits WHERE user_id::text = :uid_txt
                       )
                    """
                ),
                {"uid_txt": user_id, "fb": uid},
            )
            conn.execute(
                text("DELETE FROM visit_recordings WHERE user_id::text = :uid_txt"),
                {"uid_txt": user_id},
            )
            conn.execute(
                text("DELETE FROM visits WHERE user_id::text = :uid_txt"),
                {"uid_txt": user_id},
            )
            conn.execute(
                text(
                    """
                    UPDATE invitations SET patient_id = NULL
                    WHERE patient_id::text = :uid_txt
                    """
                ),
                {"uid_txt": user_id},
            )

            result = conn.execute(
                text("DELETE FROM users WHERE id::text = :uid_txt"),
                {"uid_txt": user_id},
            )
            if result.rowcount <= 0:
                return None

        # Outside SQL transaction: best-effort external purges.
        try:
            deleted_urls = delete_gcs_urls(media_urls)
            deleted_prefixes = delete_visit_media_prefixes(visit_ids)
            logger.info(
                "Account purge GCS uid=%s urls=%s prefixes=%s",
                uid,
                deleted_urls,
                deleted_prefixes,
            )
        except Exception as e:
            logger.warning("Account purge GCS failed uid=%s: %s", uid, e)

        try:
            delete_firestore_user_data(uid)
        except Exception as e:
            logger.warning("Account purge Firestore failed uid=%s: %s", uid, e)

        try:
            delete_firebase_auth_user(uid)
        except Exception as e:
            logger.warning("Account purge Auth failed uid=%s: %s", uid, e)

        return user_id
    except Exception as e:
        logger.error("Error deleting user account firebase_uid=%s: %s", uid, e)
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
                WHERE patient_id::text IN (
                    CAST(:patient_id AS text),
                    COALESCE((SELECT id::text FROM users WHERE firebase_uid = :patient_id LIMIT 1), CAST(:patient_id AS text))
                )
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
                  AND patient_id::text IN (
                      CAST(:patient_id AS text),
                      COALESCE((SELECT id::text FROM users WHERE firebase_uid = :patient_id LIMIT 1), CAST(:patient_id AS text))
                  )
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
                  AND patient_id::text IN (
                      CAST(:patient_id AS text),
                      COALESCE((SELECT id::text FROM users WHERE firebase_uid = :patient_id LIMIT 1), CAST(:patient_id AS text))
                  )
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


async def get_my_patients_for_caregiver(member_user_id: str) -> list[dict]:
    """
    Fetch all patients that the given caregiver (member_user_id) is caring for.
    Returns list of patient info with medication adherence, alerts, etc.
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            query = text("""
                SELECT
                    u.id AS patient_id,
                    u.firebase_uid,
                    u.full_name,
                    u.email,
                    COALESCE(m.role, 'Unknown') AS relationship,
                    m.status AS membership_status,
                    m.permission,
                    m.created_at AS joined_at,
                    0 AS medication_adherence,
                    (
                        SELECT COUNT(*)::int
                        FROM reminders r
                        WHERE (r.user_id::text = u.id::text OR r.user_id = u.firebase_uid)
                          AND r.reminder_type = 'appointment'
                          AND r.status = 'pending'
                          AND r.scheduled_time >= timezone('utc', now())
                          AND r.scheduled_time <= (timezone('utc', now()) + interval '14 days')
                    ) AS upcoming_appointments,
                    (
                        SELECT COUNT(*)::int
                        FROM reminders r
                        WHERE (r.user_id::text = u.id::text OR r.user_id = u.firebase_uid)
                          AND r.status = 'pending'
                          AND r.scheduled_time <= (timezone('utc', now()) + interval '48 hours')
                    ) AS reminders_due_soon,
                    (
                        SELECT COUNT(*)::int
                        FROM caregiver_alerts ca
                        WHERE ca.caregiver_id::text = m.member_user_id::text
                          AND ca.read = false
                          AND (
                              ca.user_id::text = u.id::text
                              OR ca.user_id = u.firebase_uid
                          )
                    ) AS unread_alerts,
                    (
                        SELECT MAX(v.created_at)
                        FROM visits v
                        WHERE v.user_id::text = u.id::text
                           OR v.user_id = u.firebase_uid
                    ) AS last_visit_at,
                    (
                        SELECT MAX(sub.t)
                        FROM (
                            SELECT ca.sent_at AS t
                            FROM caregiver_alerts ca
                            WHERE ca.caregiver_id::text = m.member_user_id::text
                              AND (
                                  ca.user_id::text = u.id::text
                                  OR ca.user_id = u.firebase_uid
                              )
                            UNION ALL
                            SELECT rl.created_at AS t
                            FROM reminder_logs rl
                            WHERE rl.user_id::text = u.id::text
                               OR rl.user_id = u.firebase_uid
                            UNION ALL
                            SELECT v.created_at AS t
                            FROM visits v
                            WHERE v.user_id::text = u.id::text
                               OR v.user_id = u.firebase_uid
                        ) AS sub
                    ) AS last_activity_at,
                    (
                        SELECT COALESCE(
                            json_agg(
                                json_build_object(
                                    'type', evt.type,
                                    'summary', evt.summary,
                                    'occurred_at', evt.occurred_at
                                )
                                ORDER BY evt.occurred_at DESC
                            ),
                            '[]'::json
                        )
                        FROM (
                            SELECT * FROM (
                                SELECT
                                    'alert'::text AS type,
                                    left(
                                        trim(
                                            coalesce(
                                                nullif(trim(ca.message), ''),
                                                ca.alert_type,
                                                'Alert'
                                            )
                                        ),
                                        200
                                    ) AS summary,
                                    ca.sent_at AS occurred_at
                                FROM caregiver_alerts ca
                                WHERE ca.caregiver_id::text = m.member_user_id::text
                                  AND (
                                      ca.user_id::text = u.id::text
                                      OR ca.user_id = u.firebase_uid
                                  )
                                UNION ALL
                                SELECT
                                    'reminder'::text AS type,
                                    left(
                                        ('Reminder ' || coalesce(rl.action, 'event'))::text,
                                        200
                                    ) AS summary,
                                    rl.created_at AS occurred_at
                                FROM reminder_logs rl
                                WHERE rl.user_id::text = u.id::text
                                   OR rl.user_id = u.firebase_uid
                                UNION ALL
                                SELECT
                                    'visit'::text AS type,
                                    left(
                                        trim(coalesce(v.title, 'Visit recorded')),
                                        200
                                    ) AS summary,
                                    v.created_at AS occurred_at
                                FROM visits v
                                WHERE v.user_id::text = u.id::text
                                   OR v.user_id = u.firebase_uid
                            ) AS combined
                            ORDER BY combined.occurred_at DESC
                            LIMIT 8
                        ) AS evt
                    ) AS recent_activities
                FROM care_team_members m
                JOIN users u ON u.id::text = m.patient_id::text
                WHERE m.member_user_id::text = :member_user_id
                  AND m.status = 'active'
                ORDER BY last_activity_at DESC NULLS LAST, u.full_name;
            """)
            result = conn.execute(query, {"member_user_id": member_user_id})
            rows = result.fetchall()
            patients = []
            for row in rows:
                if hasattr(row, "_mapping"):
                    patients.append(dict(row._mapping))
                else:
                    patients.append({
                        "patient_id": str(row[0]),
                        "firebase_uid": row[1],
                        "full_name": row[2],
                        "email": row[3],
                        "relationship": row[4],
                        "membership_status": row[5],
                        "permission": row[6],
                        "joined_at": row[7],
                        "medication_adherence": row[8] or 0,
                        "upcoming_appointments": row[9] or 0,
                        "reminders_due_soon": row[10] or 0,
                        "unread_alerts": row[11] or 0,
                        "last_visit_at": row[12],
                        "last_activity_at": row[13],
                        "recent_activities": row[14],
                    })
            return patients
    except Exception as e:
        logger.error(f"Error fetching patients for caregiver member_user_id={member_user_id}: {e}")
        raise


async def get_symptom_journal_for_patient(
    patient_ident: str,
    date_from: Optional[datetime] = None,
    date_to_exclusive: Optional[datetime] = None,
    severity_substring: Optional[str] = None,
    limit: int = 200,
) -> List[Dict[str, Any]]:
    """
    Read-only symptom lines from visit AI structured summaries (summaries_log.structured_data_json).

    patient_ident may be internal users.id (uuid string) or the patient's firebase_uid.
    summaries_log.user_id is stored as text (uuid or firebase uid depending on pipeline).
    """
    try:
        engine = get_cloud_sql_engine()
        user_match = """
            (
              s.user_id::text = :patient_ident
              OR s.user_id::text = (SELECT id::text FROM users WHERE firebase_uid = :patient_ident LIMIT 1)
              OR s.user_id::text = (SELECT firebase_uid FROM users WHERE id::text = :patient_ident LIMIT 1)
            )
            AND (
              v.user_id::text = :patient_ident
              OR v.user_id::text = (SELECT id::text FROM users WHERE firebase_uid = :patient_ident LIMIT 1)
              OR v.user_id::text = (SELECT firebase_uid FROM users WHERE id::text = :patient_ident LIMIT 1)
            )
        """
        extra = []
        params: Dict[str, Any] = {
            "patient_ident": patient_ident,
            "limit": limit,
        }
        if date_from is not None:
            extra.append("s.created_at >= :date_from")
            params["date_from"] = date_from
        if date_to_exclusive is not None:
            extra.append("s.created_at < :date_to_exclusive")
            params["date_to_exclusive"] = date_to_exclusive
        if severity_substring and severity_substring.strip():
            extra.append("COALESCE(sym->>'severity', '') ILIKE :severity_ilike")
            params["severity_ilike"] = f"%{severity_substring.strip()}%"
        extra_sql = (" AND " + " AND ".join(extra)) if extra else ""

        query = text(f"""
            SELECT
              s.id::text AS summary_id,
              s.visit_id::text AS visit_id,
              s.created_at AS logged_at,
              COALESCE(v.title::text, '') AS visit_title,
              COALESCE(v.doctor::text, '') AS doctor_name,
              COALESCE(sym->>'description', '') AS description,
              COALESCE(sym->>'duration', '') AS duration,
              COALESCE(sym->>'severity', '') AS severity,
              LEFT(COALESCE(s.summary_text, ''), 220) AS note_preview
            FROM summaries_log s
            JOIN visits v ON v.id = s.visit_id
            CROSS JOIN LATERAL jsonb_array_elements(
              CASE
                WHEN jsonb_typeof(COALESCE(s.structured_data_json->'symptoms', '[]'::jsonb)) = 'array'
                THEN s.structured_data_json->'symptoms'
                ELSE '[]'::jsonb
              END
            ) AS sym
            WHERE s.structured_data_json IS NOT NULL
              AND {user_match}
              {extra_sql}
            ORDER BY s.created_at DESC
            LIMIT :limit
        """)

        with engine.connect() as conn:
            result = conn.execute(query, params)
            rows = result.fetchall()
        out: List[Dict[str, Any]] = []
        for idx, row in enumerate(rows):
            if hasattr(row, "_mapping"):
                m = dict(row._mapping)
            else:
                m = {
                    "summary_id": row[0],
                    "visit_id": row[1],
                    "logged_at": row[2],
                    "visit_title": row[3],
                    "doctor_name": row[4],
                    "description": row[5],
                    "duration": row[6],
                    "severity": row[7],
                    "note_preview": row[8],
                }
            logged = m.get("logged_at")
            sid = str(m.get("summary_id", ""))
            out.append(
                {
                    "id": f"{sid}:{idx}",
                    "summary_id": sid,
                    "visit_id": str(m.get("visit_id", "")),
                    "visit_title": m.get("visit_title") or "",
                    "doctor_name": m.get("doctor_name") or "",
                    "logged_at": logged.isoformat() if hasattr(logged, "isoformat") else str(logged),
                    "description": m.get("description") or "",
                    "duration": m.get("duration") or "",
                    "severity": m.get("severity") or "",
                    "note_preview": (m.get("note_preview") or "").strip(),
                }
            )
        return out
    except Exception as e:
        logger.error("Error fetching symptom journal for patient_ident=%s: %s", patient_ident, e)
        raise


async def get_primary_caregiver_for_patient(patient_ident: str) -> Optional[Dict[str, Any]]:
    """
    Pick one active care-team caregiver to notify for this patient.
    Prefers permission = 'full', then earliest membership.

    patient_ident may be internal users.id (uuid string) or the patient's firebase_uid.

    Returns:
        caregiver_firebase_uid, caregiver_email, caregiver_full_name (may be None)
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            result = conn.execute(
                text("""
                    SELECT
                        caregiver.firebase_uid AS caregiver_firebase_uid,
                        caregiver.email AS caregiver_email,
                        caregiver.full_name AS caregiver_full_name
                    FROM care_team_members m
                    JOIN users caregiver
                      ON caregiver.id::text = m.member_user_id::text
                      OR caregiver.firebase_uid::text = m.member_user_id::text
                    WHERE m.status = 'active'
                      AND m.patient_id::text IN (
                          CAST(:pid AS text),
                          COALESCE(
                              (SELECT id::text FROM users WHERE firebase_uid = :pid LIMIT 1),
                              CAST(:pid AS text)
                          )
                      )
                    ORDER BY
                        CASE WHEN m.permission = 'full' THEN 0 ELSE 1 END,
                        m.created_at ASC NULLS LAST
                    LIMIT 1
                """),
                {"pid": patient_ident},
            )
            row = result.fetchone()
            if not row:
                return None
            if hasattr(row, "_mapping"):
                return dict(row._mapping)
            return {
                "caregiver_firebase_uid": row[0],
                "caregiver_email": row[1],
                "caregiver_full_name": row[2],
            }
    except Exception as e:
        logger.error(
            "Error resolving primary caregiver for patient_ident=%s: %s",
            patient_ident,
            e,
        )
        raise


async def get_caregivers_for_patient_alerts(patient_ident: str) -> List[Dict[str, Any]]:
    """
    All active care-team caregivers for a patient who can receive in-app/email alerts.
    Excludes members without a Firebase UID (cannot match caregiver_alerts.caregiver_id insert path).

    patient_ident may be internal users.id (uuid string) or the patient's firebase_uid.

    Returns rows: caregiver_firebase_uid, caregiver_email, caregiver_full_name
    """
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            result = conn.execute(
                text("""
                    SELECT
                        caregiver.firebase_uid AS caregiver_firebase_uid,
                        caregiver.email AS caregiver_email,
                        caregiver.full_name AS caregiver_full_name
                    FROM care_team_members m
                    JOIN users caregiver
                      ON caregiver.id::text = m.member_user_id::text
                      OR caregiver.firebase_uid::text = m.member_user_id::text
                    WHERE m.status = 'active'
                      AND caregiver.firebase_uid IS NOT NULL
                      AND TRIM(caregiver.firebase_uid) <> ''
                      AND m.patient_id::text IN (
                          CAST(:pid AS text),
                          COALESCE(
                              (SELECT id::text FROM users WHERE firebase_uid = :pid LIMIT 1),
                              CAST(:pid AS text)
                          )
                      )
                    ORDER BY
                        CASE WHEN m.permission = 'full' THEN 0 ELSE 1 END,
                        m.created_at ASC NULLS LAST
                """),
                {"pid": patient_ident},
            )
            rows = result.fetchall()
            out: List[Dict[str, Any]] = []
            for row in rows:
                if hasattr(row, "_mapping"):
                    out.append(dict(row._mapping))
                else:
                    out.append(
                        {
                            "caregiver_firebase_uid": row[0],
                            "caregiver_email": row[1],
                            "caregiver_full_name": row[2],
                        }
                    )
            return out
    except Exception as e:
        logger.error(
            "Error listing caregivers for alerts patient_ident=%s: %s",
            patient_ident,
            e,
        )
        raise


async def get_caregiver_alert_email_enabled(firebase_uid: str) -> bool:
    """Default True when column missing or user not found (send if infra allows)."""
    uid = (firebase_uid or "").strip()
    if not uid:
        return True
    try:
        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            result = conn.execute(
                text("""
                    SELECT caregiver_alert_email_enabled
                    FROM public.users
                    WHERE firebase_uid = :uid
                    LIMIT 1
                """),
                {"uid": uid},
            )
            row = result.fetchone()
            if not row:
                return True
            val = row[0]
            return bool(val) if val is not None else True
    except Exception as e:
        logger.warning(
            "get_caregiver_alert_email_enabled failed uid=%s (column may be missing): %s",
            uid,
            e,
        )
        return True


async def set_caregiver_alert_email_enabled(firebase_uid: str, enabled: bool) -> None:
    uid = (firebase_uid or "").strip()
    if not uid:
        raise HTTPException(status_code=400, detail="Invalid user")
    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        result = conn.execute(
            text("""
                UPDATE public.users
                SET caregiver_alert_email_enabled = :enabled
                WHERE firebase_uid = :uid
            """),
            {"uid": uid, "enabled": enabled},
        )
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="User not found")

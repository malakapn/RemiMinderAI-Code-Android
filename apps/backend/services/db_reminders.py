import logging
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Dict, Any
import uuid

from dateutil import parser
import pytz
from sqlalchemy import text

from services.cloud_sql_engine import get_cloud_sql_engine

logger = logging.getLogger(__name__)


def _row_to_dict(row: Any) -> Optional[Dict[str, Any]]:
    if not row:
        return None
    if hasattr(row, "_mapping"):
        return dict(row._mapping)
    return dict(row)


def _rows_to_dicts(rows: List[Any]) -> List[Dict[str, Any]]:
    return [dict(row._mapping) if hasattr(row, "_mapping") else dict(row) for row in rows]


async def create_reminder(data: dict) -> Optional[Dict[str, Any]]:
    """Create a new reminder in the database."""
    # Convert UUIDs to strings if needed (exclude user_id, which is Firebase UID)
    user_id = data["user_id"]
    visit_id = str(data["visit_id"]) if data.get("visit_id") and isinstance(data["visit_id"], uuid.UUID) else data.get("visit_id")

    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        result = conn.execute(
            text("""
                INSERT INTO reminders
                (user_id, visit_id, reminder_type, title, message, scheduled_time, timezone, recurrence, status)
                VALUES (:user_id, :visit_id, :reminder_type, :title, :message, :scheduled_time, :timezone, :recurrence, :status)
                RETURNING *
            """),
            {
                "user_id": user_id,
                "visit_id": visit_id,
                "reminder_type": data["reminder_type"],
                "title": data["title"],
                "message": data["message"],
                "scheduled_time": data["scheduled_time"],
                "timezone": data["timezone"],
                "recurrence": data.get("recurrence", "once"),
                "status": "pending",
            },
        )
        return _row_to_dict(result.fetchone())


async def insert_ai_reminders(
    ai_summary_result: Dict,
    user_id: str,
    visit_id: str
) -> List[Optional[Dict[str, Any]]]:
    """Transform AI-generated reminders into database format and insert them."""
    USER_TIMEZONE = 'America/New_York'
    reminders_to_insert = ai_summary_result.get("reminders", [])
    inserted_reminders = []
    
    for reminder_item in reminders_to_insert:
        scheduled_datetime_utc = None

        # Extract reminder data
        title = ai_summary_result.get("title", "Doctor Office Visit")
        message = reminder_item["text"]
        reminder_type = reminder_item["type"]
        recurrence = reminder_item.get("recurrence", "once")

        # Parse scheduled time
        scheduled_date_str = reminder_item.get("scheduled_date", "")
        scheduled_time_str = reminder_item.get("scheduled_time", "")

        if scheduled_date_str:
            try:
                datetime_str = f"{scheduled_date_str} {scheduled_time_str or '00:00'}"
                dt_naive = parser.parse(datetime_str)

                # Convert NY time to UTC
                ny_tz = pytz.timezone(USER_TIMEZONE)
                dt_ny_aware = ny_tz.localize(dt_naive)
                scheduled_datetime_utc = dt_ny_aware.astimezone(timezone.utc)

            except Exception as e:
                logger.warning(f"Failed to parse date/time for reminder '{message}': {e}")
                continue 

        # Handle recurring reminders without specific dates
        elif recurrence != 'once':
            # Schedule first instance for tomorrow at 8 AM NY time
            ny_tz = pytz.timezone(USER_TIMEZONE)
            tomorrow_ny = datetime.now(ny_tz) + timedelta(days=1)
            tomorrow_8am_ny = tomorrow_ny.replace(hour=8, minute=0, second=0, microsecond=0)
            scheduled_datetime_utc = tomorrow_8am_ny.astimezone(timezone.utc)

        # Insert reminder if we have a valid scheduled time
        if scheduled_datetime_utc is not None:
            db_data = {
                "user_id": user_id,
                "visit_id": visit_id,
                "reminder_type": reminder_type,
                "title": title,
                "message": message,
                "scheduled_time": scheduled_datetime_utc,
                "timezone": USER_TIMEZONE,
                "recurrence": recurrence,
            }

            try:
                inserted = await create_reminder(db_data)
                inserted_reminders.append(inserted)
            except Exception as e:
                logger.error(f"Error inserting reminder '{message}': {e}")
                inserted_reminders.append(None)
                
    return inserted_reminders

async def get_reminder(reminder_id: str, user_id: str) -> Optional[Dict[str, Any]]:
    """Fetch a single reminder by ID. Handles both internal UUID and Firebase UID."""
    engine = get_cloud_sql_engine()
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT *
                FROM reminders
                WHERE id = :reminder_id
                  AND (
                    user_id = :user_id
                    OR user_id = COALESCE(
                        (SELECT firebase_uid FROM users WHERE id::text = :user_id LIMIT 1),
                        (SELECT id::text FROM users WHERE firebase_uid = :user_id LIMIT 1)
                    )
                  )
                LIMIT 1
            """),
            {"reminder_id": reminder_id, "user_id": user_id},
        )
        return _row_to_dict(result.fetchone())

async def get_all_reminders(user_id: str) -> List[Dict[str, Any]]:
    """Fetch all reminders for a patient.

    user_id may be the internal users.id UUID or Firebase UID — handles both
    so reminders created before/after the UUID migration are always found.
    """
    engine = get_cloud_sql_engine()
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT *
                FROM reminders
                WHERE user_id = :user_id
                   OR user_id = COALESCE(
                       (SELECT firebase_uid FROM users WHERE id::text = :user_id LIMIT 1),
                       (SELECT id::text FROM users WHERE firebase_uid = :user_id LIMIT 1)
                   )
                ORDER BY scheduled_time ASC
            """),
            {"user_id": user_id},
        )
        return _rows_to_dicts(result.fetchall())


async def update_reminder(reminder_id: str, user_id: str, updates: dict) -> Optional[Dict[str, Any]]:
    """Update a reminder."""
    # Convert datetime to ISO string if present
    if "scheduled_time" in updates and isinstance(updates["scheduled_time"], datetime):
        updates["scheduled_time"] = updates["scheduled_time"]

    if not updates:
        return await get_reminder(reminder_id, user_id)

    set_clauses = []
    params = {"reminder_id": reminder_id, "user_id": user_id}
    for key, value in updates.items():
        set_clauses.append(f"{key} = :{key}")
        params[key] = value

    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        result = conn.execute(
            text(f"""
                UPDATE reminders
                SET {', '.join(set_clauses)}
                WHERE id = :reminder_id
                  AND user_id = :user_id
                RETURNING *
            """),
            params,
        )
        return _row_to_dict(result.fetchone())


async def delete_reminder(reminder_id: str, user_id: str) -> bool:
    """Delete a reminder."""
    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        result = conn.execute(
            text("""
                DELETE FROM reminders
                WHERE id = :reminder_id
                  AND user_id = :user_id
                RETURNING id
            """),
            {"reminder_id": reminder_id, "user_id": user_id},
        )
        return result.fetchone() is not None


# ============================================================================
# REMINDER STATUS UPDATES
# ============================================================================

async def mark_reminder_complete(reminder_id: str, user_id: str, notes: Optional[str] = None) -> Optional[Dict[str, Any]]:
    """Mark a reminder as completed."""
    now = datetime.now(timezone.utc)

    # Update reminder status and reset skip count
    reminder = await update_reminder(
        reminder_id,
        user_id,
        {
            "status": "completed",
            "completed_at": now.isoformat(),
            "consecutive_skips": 0
        }
    )

    # Create next recurring instance if needed
    if reminder and reminder.get("recurrence") and reminder["recurrence"] != "once":
        await create_recurring_reminder(reminder)

    # Log the action
    if reminder:
        await log_reminder_action(reminder_id, user_id, "completed", notes)

    return reminder


async def snooze_reminder(reminder_id: str, user_id: str, snooze_minutes: int = 30) -> Optional[Dict[str, Any]]:
    """Snooze a reminder once."""
    # Get current reminder
    reminder = await get_reminder(reminder_id, user_id)
    if not reminder:
        return None
    
    # Check if already snoozed once (MVP: only allow one snooze)
    if reminder.get("snoozed_count", 0) >= 1:
        return None  # Already snoozed once
    
    now = datetime.now(timezone.utc)
    new_scheduled_time = now + timedelta(minutes=snooze_minutes)
    updated = await update_reminder(
        reminder_id, user_id,
        {
            "status": "snoozed",
            "snoozed_count": reminder.get("snoozed_count", 0) + 1,
            "scheduled_time": new_scheduled_time.isoformat(),
            "snooze_until": None  # Clear it
        }
    )    

    if updated:
        # Log the action
        await log_reminder_action(reminder_id, user_id, "snoozed", f"Snoozed for {snooze_minutes} minutes")
    
    return updated


async def skip_reminder(reminder_id: str, user_id: str, reason: Optional[str] = None) -> Optional[Dict[str, Any]]:
    """Skip a reminder: set status, increment consecutive_skips in one write, then log."""
    prev = await get_reminder(reminder_id, user_id)
    if not prev:
        return None

    current_skips = prev.get("consecutive_skips", 0) or 0
    reminder = await update_reminder(
        reminder_id,
        user_id,
        {
            "status": "skipped",
            "consecutive_skips": current_skips + 1,
        },
    )

    if prev.get("recurrence") and prev["recurrence"] != "once":
        await create_recurring_reminder(prev)

    if reminder:
        await log_reminder_action(reminder_id, user_id, "skipped", reason)

    return reminder


# ============================================================================
# REMINDER LOGS
# ============================================================================

async def log_reminder_action(
    reminder_id: str,
    user_id: str,
    action: str,
    notes: Optional[str] = None
) -> Optional[Dict[str, Any]]:
    """Log a reminder action to reminder_logs table."""
    # Convert UUIDs to strings if needed (exclude user_id, which is Firebase UID)
    reminder_id = str(reminder_id) if isinstance(reminder_id, uuid.UUID) else reminder_id
    user_id = user_id

    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        result = conn.execute(
            text("""
                INSERT INTO reminder_logs
                (reminder_id, user_id, action, notes)
                VALUES (:reminder_id, :user_id, :action, :notes)
                RETURNING *
            """),
            {
                "reminder_id": reminder_id,
                "user_id": user_id,
                "action": action,
                "notes": notes,
            },
        )
        return _row_to_dict(result.fetchone())


async def get_reminder_logs(reminder_id: str) -> List[Dict[str, Any]]:
    """Fetch all logs for a specific reminder."""
    engine = get_cloud_sql_engine()
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT *
                FROM reminder_logs
                WHERE reminder_id = :reminder_id
                ORDER BY created_at DESC
            """),
            {"reminder_id": reminder_id},
        )
        return _rows_to_dicts(result.fetchall())


# ============================================================================
# SCHEDULER QUERIES
# ============================================================================

async def get_pending_reminders() -> List[Dict[str, Any]]:
    """Fetch all pending reminders that are due now (for scheduler)."""
    now = datetime.now(timezone.utc).isoformat()
    engine = get_cloud_sql_engine()
    with engine.connect() as conn:
        pending = conn.execute(
            text("""
                SELECT *
                FROM reminders
                WHERE status = 'pending'
                  AND scheduled_time <= :now
                  AND retry_count < 2
                  AND snooze_until IS NULL
            """),
            {"now": now},
        ).fetchall()
        snoozed = conn.execute(
            text("""
                SELECT *
                FROM reminders
                WHERE status = 'snoozed'
                  AND scheduled_time <= :now
                  AND retry_count < 2
            """),
            {"now": now},
        ).fetchall()
        return _rows_to_dicts(pending + snoozed)


async def get_missed_reminders_for_auto_skip() -> List[Dict[str, Any]]:
    """
    Fetch reminders that are 1+ days overdue and still pending.
    These will be auto-skipped by the scheduler.
    """
    # Calculate cutoff: 24 hours ago
    cutoff_time = (datetime.now(timezone.utc) - timedelta(days=1)).isoformat()
    engine = get_cloud_sql_engine()
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT *
                FROM reminders
                WHERE status = 'pending'
                  AND scheduled_time <= :cutoff
            """),
            {"cutoff": cutoff_time},
        )
        return _rows_to_dicts(result.fetchall())


async def get_pending_reminders_past_grace(
    grace_minutes: int = 60,
    max_age_days: int = 30,
    limit: int = 500,
) -> List[Dict[str, Any]]:
    """
    Pending reminders whose scheduled_time is past grace_minutes ago
    (candidates for caregiver missed notifications).
    """
    engine = get_cloud_sql_engine()
    now = datetime.now(timezone.utc)
    grace_cutoff = (now - timedelta(minutes=grace_minutes)).isoformat()
    age_cutoff = (now - timedelta(days=max_age_days)).isoformat()
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT *
                FROM reminders
                WHERE status = 'pending'
                  AND scheduled_time <= :grace_cutoff
                  AND scheduled_time >= :age_cutoff
                ORDER BY scheduled_time ASC
                LIMIT :limit
            """),
            {"grace_cutoff": grace_cutoff, "age_cutoff": age_cutoff, "limit": limit},
        )
        return _rows_to_dicts(result.fetchall())


async def get_reminders_due_in_window(
    past_minutes: float = 2.0,
    future_minutes: float = 2.0,
    limit: int = 200,
) -> List[Dict[str, Any]]:
    """
    Pending/snoozed reminders whose scheduled_time is within [now - past, now + future].
    Used by cron to send due-time FCM to patient and caregivers.
    """
    engine = get_cloud_sql_engine()
    now = datetime.now(timezone.utc)
    t0 = now - timedelta(minutes=past_minutes)
    t1 = now + timedelta(minutes=future_minutes)
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT id, user_id, title, message, scheduled_time, reminder_type, status
                FROM reminders
                WHERE status IN ('pending', 'snoozed')
                  AND scheduled_time >= :t0
                  AND scheduled_time <= :t1
                ORDER BY scheduled_time ASC
                LIMIT :limit
            """),
            {"t0": t0, "t1": t1, "limit": limit},
        )
        return _rows_to_dicts(result.fetchall())


async def try_claim_reminder_due_push(reminder_id: str, scheduled_time: Any) -> bool:
    """
    Idempotent insert for (reminder_id, scheduled_time). Returns True if this call won the race.
    """
    engine = get_cloud_sql_engine()
    if isinstance(scheduled_time, datetime):
        st = scheduled_time
        if st.tzinfo is None:
            st = st.replace(tzinfo=timezone.utc)
    else:
        st = parser.parse(str(scheduled_time))
        if st.tzinfo is None:
            st = st.replace(tzinfo=timezone.utc)

    rid = str(reminder_id).strip()
    if not rid:
        return False

    with engine.begin() as conn:
        result = conn.execute(
            text("""
                INSERT INTO reminder_due_push_log (reminder_id, scheduled_time, sent_at)
                VALUES (CAST(:rid AS uuid), :st, NOW())
                ON CONFLICT (reminder_id, scheduled_time) DO NOTHING
                RETURNING reminder_id
            """),
            {"rid": rid, "st": st},
        )
        return result.fetchone() is not None


async def caregiver_alert_exists_for_context(
    patient_user_id: str,
    alert_type: str,
    context_id: str,
    caregiver_firebase_uid: Optional[str] = None,
) -> bool:
    """Idempotency: patient + type + context_id; optional per-caregiver scope for fan-out."""
    if not context_id:
        return False
    engine = get_cloud_sql_engine()
    cg = (caregiver_firebase_uid or "").strip()
    extra_cg = ""
    params: Dict[str, Any] = {
        "user_id": patient_user_id,
        "alert_type": alert_type,
        "context_id": context_id,
    }
    if cg:
        extra_cg = """
                  AND caregiver_id IN (
                    SELECT id FROM public.users
                    WHERE firebase_uid = :cfb OR id::text = :cfb
                    LIMIT 1
                  )
        """
        params["cfb"] = cg
    with engine.connect() as conn:
        result = conn.execute(
            text(f"""
                SELECT 1
                FROM caregiver_alerts
                WHERE user_id::text = CAST(:user_id AS text)
                  AND alert_type = :alert_type
                  AND context_id = :context_id
                  {extra_cg}
                LIMIT 1
            """),
            params,
        )
        return result.fetchone() is not None


async def create_recurring_reminder(original_reminder: dict) -> Optional[Dict[str, Any]]:
    """Create a new reminder for recurring schedule (used by scheduler)."""
    # Parse original scheduled time
    original_time = datetime.fromisoformat(original_reminder["scheduled_time"].replace("Z", "+00:00"))
    
    # Calculate next scheduled time based on recurrence
    if original_reminder["recurrence"] == "daily":
        next_time = original_time + timedelta(days=1)
    elif original_reminder["recurrence"] == "weekly":
        next_time = original_time + timedelta(weeks=1)
    else:
        return None  # No recurrence
    
    # Create new reminder (copy of original with new time)
    new_reminder_data = {
        "user_id": original_reminder["user_id"],
        "visit_id": original_reminder.get("visit_id"),
        "reminder_type": original_reminder["reminder_type"],
        "title": original_reminder["title"],
        "message": original_reminder["message"],
        "scheduled_time": next_time.isoformat(),
        "timezone": original_reminder["timezone"],
        "recurrence": original_reminder["recurrence"],
        "status": "pending"
    }
    
    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        result = conn.execute(
            text("""
                INSERT INTO reminders
                (user_id, visit_id, reminder_type, title, message, scheduled_time, timezone, recurrence, status)
                VALUES (:user_id, :visit_id, :reminder_type, :title, :message, :scheduled_time, :timezone, :recurrence, :status)
                RETURNING *
            """),
            new_reminder_data,
        )
        return _row_to_dict(result.fetchone())


# ============================================================================
# CAREGIVER QUERIES
# ============================================================================

async def get_patient_info(user_id: str) -> Optional[Dict[str, Any]]:
    """Get patient name and email. user_id may be firebase_uid or internal users.id string."""
    engine = get_cloud_sql_engine()
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT id, full_name, email
                FROM users
                WHERE firebase_uid = :user_id
                   OR id::text = CAST(:user_id AS text)
                LIMIT 1
            """),
            {"user_id": user_id},
        )
        return _row_to_dict(result.fetchone())


async def get_next_reminders_for_patient(user_id: str, limit: int = 5) -> List[Dict[str, Any]]:
    """Get next upcoming reminders for caregiver dashboard."""
    now = datetime.now(timezone.utc).isoformat()
    engine = get_cloud_sql_engine()
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT id, title, scheduled_time, reminder_type, status
                FROM reminders
                WHERE user_id = :user_id
                  AND status = 'pending'
                  AND scheduled_time >= :now
                ORDER BY scheduled_time ASC
                LIMIT :limit
            """),
            {"user_id": user_id, "now": now, "limit": limit},
        )
        return _rows_to_dicts(result.fetchall())


async def get_recent_activity_for_patient(user_id: str, hours: int = 24) -> List[Dict[str, Any]]:
    """Get recent reminder activity for caregiver dashboard."""
    cutoff_time = (datetime.now(timezone.utc) - timedelta(hours=hours)).isoformat()
    engine = get_cloud_sql_engine()
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT rl.reminder_id, rl.action, rl.created_at AS timestamp, r.title
                FROM reminder_logs rl
                LEFT JOIN reminders r ON r.id = rl.reminder_id
                WHERE rl.user_id = :user_id
                  AND rl.created_at >= :cutoff
                ORDER BY rl.created_at DESC
            """),
            {"user_id": user_id, "cutoff": cutoff_time},
        )
        rows = result.fetchall()
        activity = []
        for row in rows:
            mapping = row._mapping if hasattr(row, "_mapping") else row
            activity.append({
                "reminder_id": mapping[0],
                "action": mapping[1],
                "timestamp": mapping[2],
                "reminders": {"title": mapping[3]},
            })
        return activity


async def create_caregiver_alert(
    caregiver_id: str,
    user_id: str,
    reminder_id: Optional[str],
    alert_type: str,
    message: str,
    context_id: Optional[str] = None,
) -> Optional[Dict[str, Any]]:
    """Create a caregiver alert. reminder_id may be NULL for non-reminder events."""
    caregiver_id = str(caregiver_id) if isinstance(caregiver_id, uuid.UUID) else caregiver_id
    rid = None
    if reminder_id is not None and str(reminder_id).strip():
        rid = str(reminder_id) if isinstance(reminder_id, uuid.UUID) else str(reminder_id)

    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        # Ensure a caregivers row exists for this Firebase auth user.
        # Some environments have users rows but missing caregivers profile rows,
        # which otherwise causes FK errors / empty INSERT..SELECT results.
        conn.execute(
            text("""
                WITH matched_user AS (
                    SELECT
                        u.id AS user_uuid,
                        u.email AS email,
                        COALESCE(NULLIF(TRIM(u.full_name), ''), 'Caregiver') AS full_name
                    FROM users u
                    WHERE u.firebase_uid = :caregiver_id
                    LIMIT 1
                )
                INSERT INTO caregivers (auth_uid, email, full_name, phone)
                SELECT
                    mu.user_uuid,
                    mu.email,
                    mu.full_name,
                    ''
                FROM matched_user mu
                ON CONFLICT (email) DO UPDATE
                SET
                    auth_uid = COALESCE(caregivers.auth_uid, EXCLUDED.auth_uid),
                    full_name = COALESCE(NULLIF(TRIM(caregivers.full_name), ''), EXCLUDED.full_name)
            """),
            {"caregiver_id": caregiver_id},
        )

        result = conn.execute(
            text("""
                INSERT INTO caregiver_alerts
                (caregiver_id, user_id, reminder_id, alert_type, message, context_id)
                SELECT
                    caregiver.id,
                    :user_id,
                    CASE WHEN :reminder_id IS NULL THEN NULL ELSE CAST(:reminder_id AS uuid) END,
                    :alert_type,
                    :message,
                    :context_id
                FROM caregivers caregiver
                WHERE caregiver.id::text = CAST(:caregiver_id AS text)
                   OR caregiver.auth_uid::text = CAST(:caregiver_id AS text)
                   OR caregiver.auth_uid IN (
                        SELECT id FROM users
                        WHERE firebase_uid = :caregiver_id
                        LIMIT 1
                   )
                RETURNING *
            """),
            {
                "caregiver_id": caregiver_id,
                "user_id": user_id,
                "reminder_id": rid,
                "alert_type": alert_type,
                "message": message,
                "context_id": context_id,
            },
        )
        response_row = _row_to_dict(result.fetchone())
    from services.cache_service import invalidate, invalidate_prefix
    invalidate_prefix(f"caregiver_alerts:{caregiver_id}:")
    invalidate(f"caregiver_dashboard:{caregiver_id}:{user_id}")
    return response_row


async def get_caregiver_alerts(caregiver_id: str, unread_only: bool = False) -> List[Dict[str, Any]]:
    """Get alerts for a caregiver."""
    engine = get_cloud_sql_engine()
    with engine.connect() as conn:
        if unread_only:
            result = conn.execute(
                text("""
                    SELECT *
                    FROM caregiver_alerts
                    WHERE caregiver_id::text IN (
                      CAST(:caregiver_id AS text),
                      COALESCE((
                        SELECT c.id::text
                        FROM caregivers c
                        WHERE c.id::text = CAST(:caregiver_id AS text)
                           OR c.auth_uid::text = CAST(:caregiver_id AS text)
                           OR c.auth_uid IN (
                                SELECT id FROM users
                                WHERE firebase_uid = :caregiver_id
                                LIMIT 1
                           )
                        LIMIT 1
                      ), CAST(:caregiver_id AS text))
                    )
                      AND read = false
                    ORDER BY sent_at DESC
                """),
                {"caregiver_id": caregiver_id},
            )
        else:
            result = conn.execute(
                text("""
                    SELECT *
                    FROM caregiver_alerts
                    WHERE caregiver_id::text IN (
                      CAST(:caregiver_id AS text),
                      COALESCE((
                        SELECT c.id::text
                        FROM caregivers c
                        WHERE c.id::text = CAST(:caregiver_id AS text)
                           OR c.auth_uid::text = CAST(:caregiver_id AS text)
                           OR c.auth_uid IN (
                                SELECT id FROM users
                                WHERE firebase_uid = :caregiver_id
                                LIMIT 1
                           )
                        LIMIT 1
                      ), CAST(:caregiver_id AS text))
                    )
                    ORDER BY sent_at DESC
                """),
                {"caregiver_id": caregiver_id},
            )
        return _rows_to_dicts(result.fetchall())


async def mark_alert_as_read(alert_id: str, caregiver_id: str) -> Optional[Dict[str, Any]]:
    """Mark a caregiver alert as read."""
    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        result = conn.execute(
            text("""
                UPDATE caregiver_alerts
                SET read = true
                WHERE id = :alert_id
                  AND caregiver_id::text IN (
                    CAST(:caregiver_id AS text),
                    COALESCE((
                      SELECT c.id::text
                      FROM caregivers c
                      WHERE c.id::text = CAST(:caregiver_id AS text)
                         OR c.auth_uid::text = CAST(:caregiver_id AS text)
                         OR c.auth_uid IN (
                              SELECT id FROM users
                              WHERE firebase_uid = :caregiver_id
                              LIMIT 1
                         )
                      LIMIT 1
                    ), CAST(:caregiver_id AS text))
                  )
                RETURNING *
            """),
            {"alert_id": alert_id, "caregiver_id": caregiver_id},
        )
        return _row_to_dict(result.fetchone())


async def delete_caregiver_alert(alert_id: str, caregiver_id: str) -> bool:
    """Delete a caregiver alert owned by this caregiver."""
    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        result = conn.execute(
            text("""
                DELETE FROM caregiver_alerts
                WHERE id = :alert_id
                  AND caregiver_id::text IN (
                    CAST(:caregiver_id AS text),
                    COALESCE((
                      SELECT c.id::text
                      FROM caregivers c
                      WHERE c.id::text = CAST(:caregiver_id AS text)
                         OR c.auth_uid::text = CAST(:caregiver_id AS text)
                         OR c.auth_uid IN (
                              SELECT id FROM users
                              WHERE firebase_uid = :caregiver_id
                              LIMIT 1
                         )
                      LIMIT 1
                    ), CAST(:caregiver_id AS text))
                  )
                RETURNING id
            """),
            {"alert_id": alert_id, "caregiver_id": caregiver_id},
        )
        return result.fetchone() is not None


async def get_alerts_summary(caregiver_id: str, user_id: str) -> Dict[str, int]:
    """Get alert summary counts for caregiver dashboard."""
    engine = get_cloud_sql_engine()
    with engine.connect() as conn:
        unread_count = conn.execute(
            text("""
                SELECT COUNT(*) FROM caregiver_alerts
                WHERE caregiver_id::text IN (
                  CAST(:caregiver_id AS text),
                  COALESCE((
                    SELECT c.id::text
                    FROM caregivers c
                    WHERE c.id::text = CAST(:caregiver_id AS text)
                       OR c.auth_uid::text = CAST(:caregiver_id AS text)
                       OR c.auth_uid IN (
                            SELECT id FROM users
                            WHERE firebase_uid = :caregiver_id
                            LIMIT 1
                       )
                    LIMIT 1
                  ), CAST(:caregiver_id AS text))
                )
                  AND user_id = :user_id
                  AND read = false
            """),
            {"caregiver_id": caregiver_id, "user_id": user_id},
        ).scalar() or 0

        today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
        missed_count = conn.execute(
            text("""
                SELECT COUNT(*) FROM reminder_logs
                WHERE user_id = :user_id
                  AND action = 'skipped'
                  AND created_at >= :today_start
            """),
            {"user_id": user_id, "today_start": today_start},
        ).scalar() or 0

        snoozed_count = conn.execute(
            text("""
                SELECT COUNT(*) FROM caregiver_alerts
                WHERE caregiver_id::text IN (
                  CAST(:caregiver_id AS text),
                  COALESCE((
                    SELECT c.id::text
                    FROM caregivers c
                    WHERE c.id::text = CAST(:caregiver_id AS text)
                       OR c.auth_uid::text = CAST(:caregiver_id AS text)
                       OR c.auth_uid IN (
                            SELECT id FROM users
                            WHERE firebase_uid = :caregiver_id
                            LIMIT 1
                       )
                    LIMIT 1
                  ), CAST(:caregiver_id AS text))
                )
                  AND user_id = :user_id
                  AND alert_type = 'multiple_snoozes'
                  AND read = false
            """),
            {"caregiver_id": caregiver_id, "user_id": user_id},
        ).scalar() or 0

    return {
        "unread_alerts": int(unread_count),
        "missed_today": int(missed_count),
        "snoozed_multiple": int(snoozed_count),
    }


# ============================================================================
# TEMPLATE QUERIES
# ============================================================================

async def get_reminder_template(template_id: str) -> Optional[Dict[str, Any]]:
    """Fetch a reminder message template."""
    engine = get_cloud_sql_engine()
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT *
                FROM reminder_templates
                WHERE id = :template_id
                LIMIT 1
            """),
            {"template_id": template_id},
        )
        return _row_to_dict(result.fetchone())


async def get_templates_by_type(reminder_type: str) -> List[Dict[str, Any]]:
    """Get all templates for a specific reminder type."""
    engine = get_cloud_sql_engine()
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT *
                FROM reminder_templates
                WHERE reminder_type = :reminder_type
            """),
            {"reminder_type": reminder_type},
        )
        return _rows_to_dicts(result.fetchall())


# ============================================================================
# FCM Token Management
# ============================================================================

async def save_fcm_token(user_id: str, fcm_token: str, device_type: str = "android") -> bool:
    """
    Save or update FCM token for a user in the database.
    Creates fcm_tokens table if it doesn't exist.
    """
    engine = get_cloud_sql_engine()
    
    try:
        with engine.begin() as conn:
            conn.execute(
                text("""
                    CREATE TABLE IF NOT EXISTS fcm_tokens (
                        user_id TEXT PRIMARY KEY,
                        fcm_token TEXT NOT NULL,
                        device_type TEXT DEFAULT 'android',
                        created_at TIMESTAMP DEFAULT NOW(),
                        updated_at TIMESTAMP DEFAULT NOW()
                    )
                """)
            )

        with engine.begin() as conn:
            conn.execute(
                text("""
                    INSERT INTO fcm_tokens (user_id, fcm_token, device_type, updated_at)
                    VALUES (:user_id, :fcm_token, :device_type, NOW())
                    ON CONFLICT (user_id)
                    DO UPDATE SET fcm_token = :fcm_token, device_type = :device_type, updated_at = NOW()
                """),
                {"user_id": user_id, "fcm_token": fcm_token, "device_type": device_type}
            )
        try:
            from services.firestore_fcm_sync import sync_patient_fcm_token

            sync_patient_fcm_token(user_id, fcm_token, device_type)
        except Exception as sync_err:
            logger.warning("Post-save FCM Firestore sync hook failed: %s", sync_err)
        return True
        
    except Exception as e:
        logger.error(f"Error saving FCM token: {str(e)}")
        return False


async def delete_fcm_token(user_id: str) -> bool:
    """Delete FCM token for a user on logout. user_id may be internal UUID or Firebase UID."""
    engine = get_cloud_sql_engine()
    try:
        with engine.begin() as conn:
            result = conn.execute(
                text("""
                    DELETE FROM fcm_tokens
                    WHERE user_id = :user_id
                       OR user_id = COALESCE(
                           (SELECT id::text FROM users WHERE firebase_uid = :user_id LIMIT 1),
                           (SELECT firebase_uid FROM users WHERE id::text = :user_id LIMIT 1)
                       )
                """),
                {"user_id": user_id},
            )
            return result.rowcount > 0
    except Exception as e:
        logger.error(f"Error deleting FCM token for user_id={user_id}: {e}")
        return False


async def get_patient_fcm_token(user_id: str) -> Optional[str]:
    """
    Get FCM token for a user.
    user_id may be internal UUID or Firebase UID — handles both.
    """
    engine = get_cloud_sql_engine()
    try:
        with engine.connect() as conn:
            result = conn.execute(
                text("""
                    SELECT fcm_token FROM fcm_tokens
                    WHERE user_id = :user_id
                       OR user_id = COALESCE(
                           (SELECT id::text FROM users WHERE firebase_uid = :user_id LIMIT 1),
                           (SELECT firebase_uid FROM users WHERE id::text = :user_id LIMIT 1)
                       )
                    LIMIT 1
                """),
                {"user_id": user_id}
            )
            row = result.fetchone()
            if row:
                return row[0]
            return None

    except Exception as e:
        logger.error(f"Error getting FCM token: {str(e)}")
        return None


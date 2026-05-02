import logging
import uuid
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any

from sqlalchemy import text

from services.cloud_sql_engine import get_cloud_sql_engine

logger = logging.getLogger(__name__)

_MAX_AUDIT_LEN = 2000


def _audit_chunk(s: Optional[str]) -> Optional[str]:
    if s is None:
        return None
    t = str(s)
    if len(t) <= _MAX_AUDIT_LEN:
        return t
    return t[:_MAX_AUDIT_LEN] + "…"


def _append_notes_audit(
    conn,
    note_id: str,
    caregiver_id: str,
    patient_id: str,
    action: str,
    old_title: Optional[str],
    old_content: Optional[str],
    new_title: Optional[str],
    new_content: Optional[str],
) -> None:
    try:
        conn.execute(
            text("""
                INSERT INTO public.caregiver_notes_audit
                (note_id, caregiver_id, patient_id, action, old_title, old_content, new_title, new_content)
                VALUES (
                    CAST(:note_id AS uuid), :caregiver_id, :patient_id, :action,
                    :old_title, :old_content, :new_title, :new_content
                )
            """),
            {
                "note_id": note_id,
                "caregiver_id": caregiver_id,
                "patient_id": patient_id,
                "action": action,
                "old_title": _audit_chunk(old_title),
                "old_content": _audit_chunk(old_content),
                "new_title": _audit_chunk(new_title),
                "new_content": _audit_chunk(new_content),
            },
        )
    except Exception as e:
        logger.warning("caregiver_notes_audit insert skipped: %s", e)


def _row_to_dict(row: Any) -> Optional[Dict[str, Any]]:
    if not row:
        return None
    if hasattr(row, "_mapping"):
        return dict(row._mapping)
    return dict(row)


def _rows_to_dicts(rows: List[Any]) -> List[Dict[str, Any]]:
    return [dict(row._mapping) if hasattr(row, "_mapping") else dict(row) for row in rows]


def _ensure_table_exists(conn) -> None:
    conn.execute(text("""
        CREATE TABLE IF NOT EXISTS public.caregiver_notes (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            caregiver_id TEXT NOT NULL,
            patient_id TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            visit_id TEXT NULL,
            reminder_id TEXT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
    """))
    conn.execute(text("""
        ALTER TABLE public.caregiver_notes
          ADD COLUMN IF NOT EXISTS visit_id TEXT NULL
    """))
    conn.execute(text("""
        ALTER TABLE public.caregiver_notes
          ADD COLUMN IF NOT EXISTS reminder_id TEXT NULL
    """))


async def visit_belongs_to_patient(visit_id: str, patient_ident: str) -> bool:
    """True if visit exists and belongs to the patient (internal id or firebase uid)."""
    vid = (visit_id or "").strip()
    pid = (patient_ident or "").strip()
    if not vid or not pid:
        return False
    engine = get_cloud_sql_engine()
    with engine.connect() as conn:
        row = conn.execute(
            text("""
                SELECT 1
                FROM visits v
                WHERE v.id::text = :vid
                  AND (
                    v.user_id::text = :pid
                    OR v.user_id::text = (
                        SELECT id::text FROM users WHERE firebase_uid = :pid LIMIT 1
                    )
                    OR v.user_id = (
                        SELECT firebase_uid FROM users WHERE id::text = :pid LIMIT 1
                    )
                  )
                LIMIT 1
            """),
            {"vid": vid, "pid": pid},
        ).fetchone()
        return row is not None


async def reminder_belongs_to_patient(reminder_id: str, patient_ident: str) -> bool:
    """True if reminder exists and belongs to the patient."""
    rid = (reminder_id or "").strip()
    pid = (patient_ident or "").strip()
    if not rid or not pid:
        return False
    engine = get_cloud_sql_engine()
    with engine.connect() as conn:
        row = conn.execute(
            text("""
                SELECT 1
                FROM reminders r
                WHERE r.id::text = :rid
                  AND (
                    r.user_id::text = :pid
                    OR r.user_id::text = (
                        SELECT id::text FROM users WHERE firebase_uid = :pid LIMIT 1
                    )
                    OR r.user_id = (
                        SELECT firebase_uid FROM users WHERE id::text = :pid LIMIT 1
                    )
                  )
                LIMIT 1
            """),
            {"rid": rid, "pid": pid},
        ).fetchone()
        return row is not None


async def get_note(note_id: str, caregiver_id: str) -> Optional[Dict[str, Any]]:
    """Fetch a single note if it exists and belongs to this caregiver."""
    engine = get_cloud_sql_engine()
    with engine.connect() as conn:
        _ensure_table_exists(conn)
        result = conn.execute(
            text("""
                SELECT * FROM public.caregiver_notes
                WHERE id = CAST(:note_id AS uuid) AND caregiver_id = :caregiver_id
            """),
            {"note_id": note_id, "caregiver_id": caregiver_id},
        )
        row = result.fetchone()
        return _row_to_dict(row) if row else None


async def get_notes(caregiver_id: str, patient_id: str) -> List[Dict[str, Any]]:
    engine = get_cloud_sql_engine()
    with engine.connect() as conn:
        _ensure_table_exists(conn)
        result = conn.execute(
            text("""
                SELECT * FROM public.caregiver_notes
                WHERE caregiver_id = :caregiver_id
                  AND patient_id = :patient_id
                ORDER BY created_at DESC
            """),
            {"caregiver_id": caregiver_id, "patient_id": patient_id},
        )
        return _rows_to_dicts(result.fetchall())


async def create_note(
    caregiver_id: str,
    patient_id: str,
    title: str,
    content: str,
    visit_id: Optional[str] = None,
    reminder_id: Optional[str] = None,
) -> Optional[Dict[str, Any]]:
    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        _ensure_table_exists(conn)
        note_id = str(uuid.uuid4())
        vid = (visit_id or "").strip() or None
        rid = (reminder_id or "").strip() or None
        result = conn.execute(
            text("""
                INSERT INTO public.caregiver_notes
                    (id, caregiver_id, patient_id, title, content, visit_id, reminder_id)
                VALUES
                    (:id, :caregiver_id, :patient_id, :title, :content, :visit_id, :reminder_id)
                RETURNING *
            """),
            {
                "id": note_id,
                "caregiver_id": caregiver_id,
                "patient_id": patient_id,
                "title": title,
                "content": content,
                "visit_id": vid,
                "reminder_id": rid,
            },
        )
        row = result.fetchone()
        if row:
            _append_notes_audit(
                conn,
                note_id,
                caregiver_id,
                patient_id,
                "create",
                None,
                None,
                title,
                content,
            )
        return _row_to_dict(row)


async def update_note(note_id: str, caregiver_id: str, title: str, content: str) -> Optional[Dict[str, Any]]:
    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        prev = conn.execute(
            text("""
                SELECT patient_id, title, content FROM public.caregiver_notes
                WHERE id = CAST(:note_id AS uuid) AND caregiver_id = :caregiver_id
            """),
            {"note_id": note_id, "caregiver_id": caregiver_id},
        ).fetchone()
        result = conn.execute(
            text("""
                UPDATE public.caregiver_notes
                SET title = :title, content = :content, updated_at = NOW()
                WHERE id = CAST(:note_id AS uuid) AND caregiver_id = :caregiver_id
                RETURNING *
            """),
            {"note_id": note_id, "caregiver_id": caregiver_id, "title": title, "content": content},
        )
        row = result.fetchone()
        if row and prev:
            m = dict(prev._mapping) if hasattr(prev, "_mapping") else {}
            _append_notes_audit(
                conn,
                note_id,
                caregiver_id,
                str(m.get("patient_id", "")),
                "update",
                m.get("title"),
                m.get("content"),
                title,
                content,
            )
        return _row_to_dict(row)


async def delete_note(note_id: str, caregiver_id: str) -> bool:
    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        prev = conn.execute(
            text("""
                SELECT patient_id, title, content FROM public.caregiver_notes
                WHERE id = CAST(:note_id AS uuid) AND caregiver_id = :caregiver_id
            """),
            {"note_id": note_id, "caregiver_id": caregiver_id},
        ).fetchone()
        result = conn.execute(
            text("""
                DELETE FROM public.caregiver_notes
                WHERE id = CAST(:note_id AS uuid) AND caregiver_id = :caregiver_id
                RETURNING id
            """),
            {"note_id": note_id, "caregiver_id": caregiver_id},
        )
        ok = result.fetchone() is not None
        if ok and prev:
            m = dict(prev._mapping) if hasattr(prev, "_mapping") else {}
            _append_notes_audit(
                conn,
                note_id,
                caregiver_id,
                str(m.get("patient_id", "")),
                "delete",
                m.get("title"),
                m.get("content"),
                None,
                None,
            )
        return ok

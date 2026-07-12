import json
import logging
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, HTTPException, Depends, File, UploadFile
# REMOVED: Legacy summary functions deleted during Supabase cleanup
# from services.db_service import (
#     fetch_visit_transcript,
#     fetch_visit_summary,
#     insert_visit_summary,
#     fetch_all_visit_summaries,
# )
from services.gcs_service import upload_audio, upload_image
from services.auth_gateway import get_current_user_jwt as get_current_user
from services.access_control import assert_patient_access
from services.db_service import get_user_uuid, get_symptom_journal_for_patient

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["Visit Summaries"])


def get_user_id(current_user=Depends(get_current_user)) -> str:
    """Extract firebase_uid from authenticated user"""
    # Firebase UID is the canonical user identity
    return current_user["sub"]

# DISABLED: Legacy summary generation route - functions removed during Supabase cleanup
# @router.post("/generate-summary/{visit_id}", response_model=VisitSummaryPayload)
# async def create_visit_summary(visit_id: str, user_id: str, transcript_id: str):
#     visit = await fetch_visit_transcript(visit_id, user_id, transcript_id)
#     if not visit or not visit.get("transcript_text"):
#         raise HTTPException(status_code=404, detail="Transcript not found")

#     ai_output = await generate_ai_summary({
#         "transcript": visit["transcript_text"],
#         "visit_id": visit_id,
#         "user_id": user_id,
#         "transcript_id": visit["transcript_id"]
#     })

#     await insert_visit_summary(visit_id, user_id, visit["transcript_id"], ai_output)

#     return {
#         "message": "Summary generated successfully",
#         "data": {
#             "visit_id": visit_id,
#             "user_id": user_id,
#             "transcript_id": transcript_id,
#             **ai_output,
#         }
#     }

# DISABLED: Legacy summary retrieval route - functions removed during Supabase cleanup
# @router.get("/visit-summaries/{visit_id}", response_model=VisitSummary)
# async def get_visit_summary(visit_id: int, user_id: int):
#     row = await fetch_visit_summary(visit_id, user_id)
#     if not row:
#         raise HTTPException(status_code=404, detail="Summary not found")
#     return row

# DISABLED: Legacy all summaries route - functions removed during Supabase cleanup
# @router.get("/visit-summaries")
# async def get_all_summaries(user_id: str = Depends(get_user_id)):
#     logger.info(f"Fetching visit summaries for user_id: {user_id}")
#     summaries = await fetch_all_visit_summaries(user_id)
#     logger.info(f"Found {len(summaries)} raw summaries from database")
#     formatted_summaries = []

#     for item in summaries:
#         visit_data = item.get('visits', {})
#         date_source = item.get('created_at')
#         visit_dt = datetime.now() if not date_source else datetime.fromisoformat(date_source.replace('Z', '+00:00'))

#         formatted_summaries.append({
#             "id": item.get('visit_id'),
#             "title": visit_data.get('title', 'Untitled Visit'),
#             "status": visit_data.get('status', 'Completed'),
#             "doctor": visit_data.get('doctor', 'N/A'),
#             "specialty": visit_data.get('specialty', 'General'),
#             "date": visit_dt.strftime("%b %d, %Y"),
#             "time": visit_dt.strftime("%I:%M %p"),
#             "duration": visit_data.get('duration', 'N/A'),
#             "summary": item.get('summary', 'No summary available.'),
#             "keyPoints": item.get('action_items', '').split(', ') if item.get('action_items') else [],
#         })

#     return formatted_summaries


@router.post("/visits/{visit_id}/audio/upload")
async def upload_audio_for_visit(
    visit_id: str,
    file: UploadFile = File(...),
    user_id: str = Depends(get_user_id)
):
    """
    Upload audio file with transactional database consistency.
    Creates visit and visit_transcripts rows if needed, then persists audio_url.
    """
    try:
        # Step 1: Resolve Firebase UID to Cloud SQL user UUID
        from services.db_service import get_user_uuid
        user_uuid = await get_user_uuid(user_id)
        await assert_patient_access(user_uuid, user_uuid, "full")

        # Step 2: Upload to GCS first (fail fast if storage fails)
        audio_url = await upload_audio(file, visit_id)

        # Step 3: Single transaction for all database operations
        from services.cloud_sql_engine import get_cloud_sql_engine
        from sqlalchemy import text

        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            # Create visit if it doesn't exist
            visit_query = text("""
                INSERT INTO visits (id, user_id, title, status)
                VALUES (:visit_id, :user_uuid, 'Audio Visit', 'active')
                ON CONFLICT (id) DO NOTHING
            """)
            conn.execute(visit_query, {
                "visit_id": visit_id,
                "user_uuid": user_uuid
            })

            # Create visit_transcripts row if it doesn't exist
            transcript_query = text("""
                INSERT INTO visit_transcripts (visit_id, user_id)
                VALUES (:visit_id, :user_uuid)
                ON CONFLICT (visit_id, user_id) DO NOTHING
            """)
            conn.execute(transcript_query, {
                "visit_id": visit_id,
                "user_uuid": user_uuid
            })

            # Update audio_url - this MUST affect exactly 1 row
            update_query = text("""
                UPDATE visit_transcripts
                SET audio_url = :audio_url
                WHERE visit_id = :visit_id AND user_id = :user_uuid
            """)
            result = conn.execute(update_query, {
                "audio_url": audio_url,
                "visit_id": visit_id,
                "user_uuid": user_uuid
            })

            # Verify exactly 1 row was updated
            if result.rowcount != 1:
                raise Exception(f"Expected 1 row updated, got {result.rowcount}")

        # Step 4: Log success
        logger.info(f"Audio upload completed: visit={visit_id}, user={user_uuid}")

        return {
            "message": "Audio uploaded successfully",
            "audio_url": audio_url,
            "expires_in": "24 hours"
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Audio upload failed for visit {visit_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Audio upload failed: {str(e)}")


@router.post("/visits/{visit_id}/image/upload")
async def upload_image_for_visit(
    visit_id: str,
    file: UploadFile = File(...),
    user_id: str = Depends(get_user_id)
):
    """
    Upload image file with transactional database consistency.
    Creates visit and visit_transcripts rows if needed, then persists image_url and metadata.
    """
    try:
        # Step 1: Resolve Firebase UID to Cloud SQL user UUID
        from services.db_service import get_user_uuid
        user_uuid = await get_user_uuid(user_id)
        await assert_patient_access(user_uuid, user_uuid, "full")

        # Step 2: Upload to GCS first (fail fast if storage fails)
        image_result = await upload_image(file, visit_id)

        metadata = {
            "blob_name": image_result["blob_name"],
            "content_type": image_result["content_type"],
            "file_size": image_result["file_size"],
            "uploaded_at": datetime.now().isoformat()
        }

        # Step 3: Single transaction for all database operations
        from services.cloud_sql_engine import get_cloud_sql_engine
        from sqlalchemy import text

        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            # Create visit if it doesn't exist
            visit_query = text("""
                INSERT INTO visits (id, user_id, title, status)
                VALUES (:visit_id, :user_uuid, 'Image Visit', 'active')
                ON CONFLICT (id) DO NOTHING
            """)
            conn.execute(visit_query, {
                "visit_id": visit_id,
                "user_uuid": user_uuid
            })

            # Create visit_transcripts row if it doesn't exist
            transcript_query = text("""
                INSERT INTO visit_transcripts (visit_id, user_id)
                VALUES (:visit_id, :user_uuid)
                ON CONFLICT (visit_id, user_id) DO NOTHING
            """)
            conn.execute(transcript_query, {
                "visit_id": visit_id,
                "user_uuid": user_uuid
            })

            # Update image_url, metadata, and OCR status - this MUST affect exactly 1 row
            update_query = text("""
                UPDATE visit_transcripts
                SET image_url = :image_url, image_metadata = :metadata, ocr_status = 'pending'
                WHERE visit_id = :visit_id AND user_id = :user_uuid
            """)
            result = conn.execute(update_query, {
                "image_url": image_result["signed_url"],
                "metadata": json.dumps(metadata),
                "visit_id": visit_id,
                "user_uuid": user_uuid
            })

            # Verify exactly 1 row was updated
            if result.rowcount != 1:
                raise Exception(f"Expected 1 row updated, got {result.rowcount}")

        # Step 4: Log success
        logger.info(f"Image upload completed: visit={visit_id}, user={user_uuid}")

        return {
            "image_url": image_result["signed_url"],
            "expires_in_hours": 24
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Image upload failed for visit {visit_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Image upload failed: {str(e)}")


@router.post("/visits/{visit_id}/ocr")
async def process_visit_ocr(
    visit_id: str,
    user_id: str = Depends(get_user_id)
):
    """
    Process uploaded image with OCR using Google Vision API.
    Thin route that delegates to image pipeline.
    """
    logger.info("OCR requested for visit_id=%s", visit_id)
    try:
        # Step 1: Resolve user UUID (for future validation if needed)
        from services.db_service import get_user_uuid
        user_uuid = await get_user_uuid(user_id)  # Validate user exists
        await assert_patient_access(user_uuid, user_uuid, "full")

        # Step 2: Run OCR pipeline
        from services.media.image_pipeline import run_ocr_for_visit
        result = await run_ocr_for_visit(visit_id)

        return result

    except ValueError as e:
        # Pipeline validation errors
        if "not found" in str(e):
            raise HTTPException(status_code=404, detail=str(e))
        elif "already" in str(e):
            raise HTTPException(status_code=409, detail=str(e))
        else:
            raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.exception(f"OCR route failed for visit {visit_id}")
        raise HTTPException(status_code=500, detail=f"OCR processing failed: {str(e)}")


@router.post("/visits/{visit_id}/process-audio")
async def process_visit_audio(
    visit_id: str,
    user_id: str = Depends(get_user_id)
):
    """
    Process uploaded audio file with Speech-to-Text and save transcript.
    Background pipeline: GCS -> STT -> Cloud SQL.
    """
    from services.jobs_service import create_job
    from services.db_service import get_user_uuid

    user_uuid = await get_user_uuid(user_id)
    await assert_patient_access(user_uuid, user_uuid, "full")

    job_id = create_job(
        job_type="STT_JOB",
        payload={
            "visit_id": visit_id,
            "firebase_uid": user_id,
        },
    )
    return {
        "status": "queued",
        "visit_id": visit_id,
        "job_id": job_id,
    }


@router.get("/visits/latest/status")
async def get_latest_visit_status(user_id: str = Depends(get_user_id)):
    """
    Check whether the latest visit for this user is still processing.
    """
    try:
        from services.cache_service import get, set
        from services.cloud_sql_engine import get_cloud_sql_engine
        from sqlalchemy import text

        cache_key = f"visit_status:{user_id}"
        cached = get(cache_key)
        if cached is not None:
            return cached

        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            failed_row = conn.execute(
                text("""
                    SELECT payload->>'visit_id' AS visit_id, last_error
                    FROM jobs
                    WHERE job_type = 'STT_JOB'
                      AND status = 'failed'
                      AND payload->>'firebase_uid' = :firebase_uid
                      AND updated_at > NOW() - INTERVAL '24 hours'
                    ORDER BY updated_at DESC
                    LIMIT 1
                """),
                {"firebase_uid": user_id},
            ).fetchone()

            if failed_row:
                visit_id = failed_row[0]
                error = failed_row[1]
                response = {
                    "processing": False,
                    "failed": True,
                    "visit_id": visit_id,
                    "error": error,
                }
                set(cache_key, response, 5)
                return response

            row = conn.execute(
                text("""
                    SELECT payload->>'visit_id' AS visit_id
                    FROM jobs
                    WHERE job_type = 'STT_JOB'
                      AND status IN ('pending', 'running')
                      AND payload->>'firebase_uid' = :firebase_uid
                      AND created_at > NOW() - INTERVAL '30 minutes'
                    ORDER BY created_at DESC
                    LIMIT 1
                """),
                {"firebase_uid": user_id},
            ).fetchone()

        if not row:
            response = {"processing": False}
            set(cache_key, response, 5)
            return response

        response = {"processing": True, "visit_id": row[0]}
        set(cache_key, response, 5)
        return response

    except Exception as e:
        logger.error("Failed to fetch latest visit status for user %s: %s", user_id, e)
        raise HTTPException(status_code=500, detail="Failed to fetch latest visit status")


@router.get("/visits/{visit_id}/audio")
async def get_visit_audio_url_endpoint(
    visit_id: str,
    user_id: str = Depends(get_user_id)
):
    try:
        # Get user UUID from Firebase UID
        from services.db_service import get_user_uuid
        user_uuid = await get_user_uuid(user_id)  # user_id is Firebase UID from JWT
        await assert_patient_access(user_uuid, user_uuid, "view")

        from services.db_service import get_audio_gcs_url
        audio_url = await get_audio_gcs_url(visit_id, user_uuid)

        return {
            "visit_id": visit_id,
            "audio_url": audio_url
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve audio: {str(e)}")


@router.get("/visits/{visit_id}")
async def get_visit_metadata(
    visit_id: str,
    user_id: str = Depends(get_user_id)
):
    """
    Get visit metadata from visits table.
    """
    try:
        from services.db_service import get_user_uuid
        from services.cloud_sql_engine import get_cloud_sql_engine
        from sqlalchemy import text

        user_uuid = await get_user_uuid(user_id)
        await assert_patient_access(user_uuid, user_uuid, "view")

        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            row = conn.execute(
                text("""
                    SELECT id, doctor, specialty, title, created_at, status
                    FROM visits
                    WHERE id = :visit_id AND user_id = :user_id
                    LIMIT 1
                """),
                {"visit_id": visit_id, "user_id": user_uuid},
            ).fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="Visit not found")

        return {
            "id": str(row[0]),
            "doctor": row[1],
            "specialty": row[2],
            "title": row[3],
            "created_at": row[4].isoformat() if row[4] else None,
            "status": row[5],
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve visit: {str(e)}")


@router.get("/visits/{visit_id}/summary")
async def get_visit_summary(
    visit_id: str,
    user_id: str = Depends(get_user_id)
):
    """
    Get the latest AI-generated summary for a visit.
    Returns processing status if not ready, or summary text if available.
    """
    try:
        logger.info(f"Getting summary for visit_id={visit_id}, firebase_uid={user_id}")

        # Step 1: Resolve Firebase UID to Cloud SQL user UUID
        from services.db_service import get_user_uuid, get_latest_ai_summary_for_visit
        user_uuid = await get_user_uuid(user_id)
        await assert_patient_access(user_uuid, user_uuid, "view")

        logger.info(f"Resolved firebase_uid={user_id} to user_uuid={user_uuid}")

        # Step 2: Fetch latest summary for this visit
        summary_text = await get_latest_ai_summary_for_visit(visit_id, user_uuid)

        logger.info(f"DB query result for visit_id={visit_id}, user_uuid={user_uuid}: summary_text={summary_text is not None}")

        # Step 3: Return appropriate response
        if summary_text:
            logger.info(f"Returning summary: {summary_text[:100]}...")
            return {"summary": summary_text}
        else:
            logger.info("Returning processing status")
            return {"status": "processing"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get summary for visit {visit_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve summary: {str(e)}")


@router.get("/visits/{visit_id}/summary-structured")
async def get_visit_summary_structured(
    visit_id: str,
    user_id: str = Depends(get_user_id)
):
    """
    Get the latest AI-generated structured summary for a visit.
    Returns processing status if not ready, or structured JSON if available.
    """
    try:
        logger.info(f"Getting structured summary for visit_id={visit_id}, firebase_uid={user_id}")

        # Step 1: Resolve Firebase UID to Cloud SQL user UUID
        from services.db_service import (
            get_user_uuid,
            get_latest_ai_structured_summary_for_visit,
            get_latest_ai_summary_for_visit,
        )
        user_uuid = await get_user_uuid(user_id)
        await assert_patient_access(user_uuid, user_uuid, "view")

        logger.info(f"Resolved firebase_uid={user_id} to user_uuid={user_uuid}")

        # Step 2: Fetch latest structured summary for this visit
        structured_data = await get_latest_ai_structured_summary_for_visit(visit_id, user_uuid)

        logger.info(
            "DB query result for visit_id=%s, user_uuid=%s: structured_data=%s",
            visit_id,
            user_uuid,
            structured_data is not None,
        )

        # Step 3: Return appropriate response
        if structured_data:
            return structured_data

        # Legacy rows: summary_text saved without structured_data_json — still show Visit Details UI.
        summary_text = await get_latest_ai_summary_for_visit(visit_id, user_uuid)
        if summary_text and str(summary_text).strip():
            logger.info(
                "Structured JSON missing; returning text summary only for visit_id=%s",
                visit_id,
            )
            return {
                "summary": str(summary_text).strip(),
                "medications": [],
                "actions": [],
            }

        logger.info("No summary yet for visit_id=%s (structured or text)", visit_id)
        return {"status": "processing"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get structured summary for visit {visit_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve structured summary: {str(e)}")


@router.get("/summaries")
async def get_user_summaries_endpoint(
    user_id: str = Depends(get_user_id)
):
    """
    Get all summaries for the current user by joining summaries_log and visits tables.
    Returns list of summaries with visit metadata, ordered by newest first.
    """
    try:
        logger.info(f"Getting summaries list for firebase_uid={user_id}")

        # Step 1: Resolve Firebase UID to Cloud SQL user UUID
        from services.db_service import (
            get_user_uuid,
            get_user_summaries,
            get_audio_visits_without_summary,
        )
        from services.cache_service import get, set
        user_uuid = await get_user_uuid(user_id)
        await assert_patient_access(user_uuid, user_uuid, "view")

        logger.info(f"Resolved firebase_uid={user_id} to user_uuid={user_uuid}")

        # Step 2: Fetch user summaries
        cache_key = f"summaries_list:{user_uuid}"
        cached = get(cache_key)
        if cached is not None:
            return cached
        summaries = await get_user_summaries(user_uuid, firebase_uid=user_id)
        pending = await get_audio_visits_without_summary(
            user_uuid,
            firebase_uid=user_id,
        )
        existing_visit_ids = {item["visit_id"] for item in summaries}
        for item in pending:
            if item["visit_id"] not in existing_visit_ids:
                summaries.append(item)

        logger.info(
            "Returning %s summaries (%s pending audio) for user_uuid=%s",
            len(summaries),
            len(pending),
            user_uuid,
        )
        set(cache_key, summaries, 120)
        return summaries

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get summaries for user {user_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve summaries: {str(e)}")


@router.delete("/summaries/{summary_id}")
async def delete_user_summary_endpoint(
    summary_id: str,
    user_id: str = Depends(get_user_id)
):
    """
    Delete a summary by ID.
    Only allows deletion of summaries belonging to the current user.
    """
    try:
        logger.info(f"Deleting summary {summary_id} for firebase_uid={user_id}")

        # Step 1: Resolve Firebase UID to Cloud SQL user UUID
        from services.db_service import get_user_uuid, delete_user_summary
        from services.cache_service import invalidate
        user_uuid = await get_user_uuid(user_id)
        await assert_patient_access(user_uuid, user_uuid, "full")

        logger.info(f"Resolved firebase_uid={user_id} to user_uuid={user_uuid}")

        # Step 2: Delete the summary (only if it belongs to this user)
        deleted = await delete_user_summary(summary_id, user_uuid, firebase_uid=user_id)

        if not deleted:
            logger.warning(f"Summary {summary_id} not found or not owned by user {user_uuid}")
            raise HTTPException(status_code=404, detail="Summary not found or access denied")

        invalidate(f"summaries_list:{user_uuid}")
        logger.info(f"Successfully deleted summary {summary_id} for user {user_uuid}")
        return {"status": "ok"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete summary {summary_id} for user {user_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to delete summary: {str(e)}")


@router.delete("/scanned-docs/{visit_id}")
async def delete_scanned_doc_endpoint(
    visit_id: str,
    user_id: str = Depends(get_user_id),
):
    """Delete a scanned document (image report) for the current user."""
    try:
        from services.db_service import get_user_uuid, delete_scanned_document
        from services.cache_service import invalidate

        user_uuid = await get_user_uuid(user_id)
        await assert_patient_access(user_uuid, user_uuid, "full")

        deleted = await delete_scanned_document(
            visit_id,
            user_uuid,
            firebase_uid=user_id,
        )
        if not deleted:
            raise HTTPException(
                status_code=404,
                detail="Scanned document not found or access denied",
            )

        invalidate(f"summaries_list:{user_uuid}")
        return {"status": "ok", "visit_id": visit_id}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(
            "Failed to delete scanned doc visit_id=%s user=%s: %s",
            visit_id,
            user_id,
            e,
        )
        raise HTTPException(
            status_code=500,
            detail=f"Failed to delete scanned document: {str(e)}",
        )


@router.get("/scanned-docs")
async def get_user_scanned_docs(user_id: str = Depends(get_user_id)):
    """
    List scanned documents (uploaded image reports) for the current user.
    """
    try:
        from services.db_service import get_user_uuid
        from services.cloud_sql_engine import get_cloud_sql_engine
        from sqlalchemy import text

        user_uuid = await get_user_uuid(user_id)
        await assert_patient_access(user_uuid, user_uuid, "view")

        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            rows = conn.execute(
                text("""
                    SELECT
                        vt.visit_id::text AS visit_id,
                        v.title AS visit_title,
                        v.created_at AS visit_date,
                        vt.image_url,
                        vt.ocr_status,
                        vt.ocr_text,
                        vt.image_metadata
                    FROM visit_transcripts vt
                    JOIN visits v ON v.id = vt.visit_id
                    WHERE (vt.user_id::text = :user_uuid OR vt.user_id::text = :firebase_uid)
                      AND vt.image_url IS NOT NULL
                    ORDER BY v.created_at DESC
                """),
                {"user_uuid": user_uuid, "firebase_uid": user_id},
            ).fetchall()

        docs = []
        for row in rows:
            m = row._mapping if hasattr(row, "_mapping") else row
            ocr_text = (m["ocr_text"] or "").strip()
            metadata = m["image_metadata"]
            uploaded_at = None
            if isinstance(metadata, dict):
                uploaded_at = metadata.get("uploaded_at")
            docs.append(
                {
                    "visit_id": str(m["visit_id"]),
                    "visit_title": m["visit_title"] or "Scanned report",
                    "visit_date": m["visit_date"].isoformat() if m["visit_date"] else None,
                    "image_url": m["image_url"],
                    "ocr_status": m["ocr_status"] or "pending",
                    "ocr_preview": ocr_text[:220] if ocr_text else "",
                    "uploaded_at": uploaded_at,
                }
            )
        return docs
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to fetch scanned docs for user %s: %s", user_id, e)
        raise HTTPException(status_code=500, detail=f"Failed to fetch scanned docs: {str(e)}")


@router.get("/caregiver/patients/{patient_id}/scanned-docs")
async def get_caregiver_patient_scanned_docs(
    patient_id: str,
    user_id: str = Depends(get_user_id),
):
    """
    Caregiver view: list scanned documents for a specific patient.
    Requires care-team membership (view/full).
    """
    try:
        from services.db_service import get_user_uuid
        from services.cloud_sql_engine import get_cloud_sql_engine
        from sqlalchemy import text

        caregiver_uuid = await get_user_uuid(user_id)

        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            patient_row = conn.execute(
                text(
                    """
                    SELECT id::text AS patient_uuid
                    FROM users
                    WHERE id::text = :patient_id OR firebase_uid = :patient_id
                    LIMIT 1
                    """
                ),
                {"patient_id": patient_id},
            ).fetchone()

        if not patient_row:
            raise HTTPException(status_code=404, detail="Patient not found")

        patient_uuid = str(
            patient_row._mapping["patient_uuid"]
            if hasattr(patient_row, "_mapping")
            else patient_row[0]
        )
        await assert_patient_access(caregiver_uuid, patient_uuid, "view")

        with engine.connect() as conn:
            rows = conn.execute(
                text(
                    """
                    SELECT
                        vt.visit_id::text AS visit_id,
                        v.title AS visit_title,
                        v.created_at AS visit_date,
                        vt.image_url,
                        vt.ocr_status,
                        vt.ocr_text,
                        vt.image_metadata
                    FROM visit_transcripts vt
                    JOIN visits v ON v.id = vt.visit_id
                    WHERE vt.user_id::text = :patient_uuid
                      AND vt.image_url IS NOT NULL
                    ORDER BY v.created_at DESC
                    """
                ),
                {"patient_uuid": patient_uuid},
            ).fetchall()

        docs = []
        for row in rows:
            m = row._mapping if hasattr(row, "_mapping") else row
            ocr_text = (m["ocr_text"] or "").strip()
            metadata = m["image_metadata"]
            uploaded_at = None
            if isinstance(metadata, dict):
                uploaded_at = metadata.get("uploaded_at")
            docs.append(
                {
                    "visit_id": str(m["visit_id"]),
                    "visit_title": m["visit_title"] or "Scanned report",
                    "visit_date": m["visit_date"].isoformat() if m["visit_date"] else None,
                    "image_url": m["image_url"],
                    "ocr_status": m["ocr_status"] or "pending",
                    "ocr_preview": ocr_text[:220] if ocr_text else "",
                    "uploaded_at": uploaded_at,
                }
            )
        return docs
    except HTTPException:
        raise
    except Exception as e:
        logger.error(
            "Failed caregiver scanned-docs fetch caregiver=%s patient=%s: %s",
            user_id,
            patient_id,
            e,
        )
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch patient scanned docs: {str(e)}",
        )


@router.get("/caregiver/patients/{patient_id}/symptom-journal")
async def get_caregiver_patient_symptom_journal(
    patient_id: str,
    user_id: str = Depends(get_user_id),
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    severity_contains: Optional[str] = None,
):
    """
    Caregiver read-only symptom lines derived from visit AI summaries.

    Mobile sends calendar-day bounds (ISO local-ish datetimes); [date_from, date_to]
    treated as inclusive on both days by advancing date_to by one day for the SQL exclusive bound.
    """
    try:
        caregiver_uuid = await get_user_uuid(user_id)
        await assert_patient_access(caregiver_uuid, patient_id, "view")

        df = None
        if date_from:
            try:
                df = datetime.fromisoformat(date_from.replace("Z", "+00:00"))
            except ValueError:
                df = None

        dt_exc = None
        if date_to:
            try:
                parsed_to = datetime.fromisoformat(date_to.replace("Z", "+00:00"))
                dt_exc = parsed_to + timedelta(days=1)
            except ValueError:
                dt_exc = None

        entries = await get_symptom_journal_for_patient(
            patient_ident=patient_id,
            date_from=df,
            date_to_exclusive=dt_exc,
            severity_substring=severity_contains,
        )
        filters = {
            "date_from": date_from,
            "date_to": date_to,
            "severity_contains": severity_contains,
        }
        return {"entries": entries, "filters_applied": filters}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(
            "symptom-journal caregiver=%s patient=%s: %s",
            user_id,
            patient_id,
            e,
        )
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch symptom journal: {str(e)}",
        )


@router.get("/lab-results")
async def get_user_lab_results(user_id: str = Depends(get_user_id)):
    """
    List OCR documents that look like lab reports using simple keyword matching.
    """
    try:
        from services.db_service import get_user_uuid
        from services.cloud_sql_engine import get_cloud_sql_engine
        from sqlalchemy import text

        user_uuid = await get_user_uuid(user_id)
        await assert_patient_access(user_uuid, user_uuid, "view")

        engine = get_cloud_sql_engine()
        with engine.connect() as conn:
            rows = conn.execute(
                text("""
                    SELECT
                        vt.visit_id::text AS visit_id,
                        v.title AS visit_title,
                        v.created_at AS visit_date,
                        vt.image_url,
                        vt.ocr_status,
                        vt.ocr_text
                    FROM visit_transcripts vt
                    JOIN visits v ON v.id = vt.visit_id
                    WHERE (vt.user_id::text = :user_uuid OR vt.user_id::text = :firebase_uid)
                      AND vt.image_url IS NOT NULL
                      AND (
                        COALESCE(vt.ocr_text, '') ILIKE '%lab%'
                        OR COALESCE(vt.ocr_text, '') ILIKE '%hemoglobin%'
                        OR COALESCE(vt.ocr_text, '') ILIKE '%cholesterol%'
                        OR COALESCE(vt.ocr_text, '') ILIKE '%glucose%'
                        OR COALESCE(vt.ocr_text, '') ILIKE '%cbc%'
                        OR COALESCE(v.title, '') ILIKE '%lab%'
                      )
                    ORDER BY v.created_at DESC
                """),
                {"user_uuid": user_uuid, "firebase_uid": user_id},
            ).fetchall()

        results = []
        for row in rows:
            m = row._mapping if hasattr(row, "_mapping") else row
            ocr_text = (m["ocr_text"] or "").strip()
            results.append(
                {
                    "visit_id": str(m["visit_id"]),
                    "visit_title": m["visit_title"] or "Lab report",
                    "visit_date": m["visit_date"].isoformat() if m["visit_date"] else None,
                    "image_url": m["image_url"],
                    "ocr_status": m["ocr_status"] or "pending",
                    "result_preview": ocr_text[:220] if ocr_text else "",
                }
            )
        return results
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Failed to fetch lab results for user %s: %s", user_id, e)
        raise HTTPException(status_code=500, detail=f"Failed to fetch lab results: {str(e)}")

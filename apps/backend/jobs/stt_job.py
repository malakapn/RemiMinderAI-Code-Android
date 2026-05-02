import asyncio
from typing import Dict, Any


def run_stt_job(payload: Dict[str, Any]) -> None:
    """
    Execute the STT pipeline for a visit and save the transcript.
    """
    visit_id = payload["visit_id"]
    firebase_uid = payload.get("firebase_uid") or payload.get("auth_uid")

    async def _run() -> None:
        from services.media.audio_pipeline import run_audio_stt_pipeline
        from services.db_service import save_raw_transcript, get_user_uuid
        from services.ai_pipeline import run_ai_summary_pipeline

        stt_result = await run_audio_stt_pipeline(visit_id, firebase_uid)
        user_uuid = await get_user_uuid(firebase_uid)

        transcript_id = await save_raw_transcript(
            visit_id=visit_id,
            user_id=user_uuid,
            transcript=stt_result["transcript"],
            confidence=stt_result["confidence"],
            language=stt_result["language"],
        )

        await run_ai_summary_pipeline(
            visit_id=visit_id,
            transcript_id=transcript_id,
            user_id=user_uuid,
        )

    asyncio.run(_run())

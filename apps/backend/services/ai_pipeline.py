"""
AI Summary Pipeline Orchestrator.

Coordinates the AI summary generation process:
1. Fetch transcript from DB
2. Generate summary using Vertex Gemini
3. Save summary to DB

This orchestrator contains no LLM code, no SQL strings, and no business logic.
"""

import asyncio
import logging
import os
import re
from services.ai.vertex_gemini_service import generate_visit_summary
from services.ai.summary_normalizer_v2 import normalize_v2_summary
from services.cache_service import get, set
from services.db_service import get_transcript_text, insert_ai_summary_log, update_visit_with_structured_data, get_user_language_preferences
from services.subscription_service import enforce_summary_limit, increment_summary_count
from services.tasks_service import generate_reminders_from_actions, generate_tasks_from_summary
from services.alert_service import (
    notify_caregiver_new_visit_symptoms,
    notify_caregivers_new_visit_recorded,
)

logger = logging.getLogger(__name__)


def _log_background_task_error(task: asyncio.Task) -> None:
    """Avoid silent failures when notify coroutines crash after create_task."""

    try:
        exc = task.exception()
        if exc is not None:
            logger.warning(
                "Background caregiver notify task failed: %s", exc, exc_info=exc
            )
    except asyncio.CancelledError:
        pass


def _get_prompt_version() -> str:
    """
    Feature flag for prompt versioning.
    Defaults to v1 for missing/invalid values.
    """
    version = (os.getenv("AI_SUMMARY_PROMPT_VERSION") or "v1").lower().strip()
    return "v2" if version == "v2" else "v1"


async def run_ai_summary_pipeline(visit_id: str, transcript_id: str, user_id: str) -> str:
    """
    Complete AI summary pipeline for a visit transcript with structured data.

    Args:
        visit_id: The visit identifier
        transcript_id: The transcript identifier
        user_id: The user identifier

    Returns:
        Generated summary text (for backward compatibility)

    Raises:
        Exception: If any step in the pipeline fails
    """
    try:
        logger.info(f"Starting AI summary pipeline for visit {visit_id}, transcript {transcript_id}")

        # Subscription enforcement is opt-in while monetization is rolling out.
        # Never let subscription metadata issues break production summary generation.
        if (os.getenv("ENFORCE_SUMMARY_LIMITS") or "").strip().lower() == "true":
            await enforce_summary_limit(user_id)

        # Step A: Fetch user's language preferences
        logger.info(f"🔍 [LANGUAGE] Fetching language preferences for user {user_id}")
        try:
            cache_key = f"language_prefs:{user_id}"
            cached = get(cache_key)
            if cached is not None:
                language_prefs = cached
            else:
                language_prefs = await get_user_language_preferences(user_id)
                if language_prefs is not None:
                    set(cache_key, language_prefs, 1800)
            visit_language = language_prefs.get("visit_language", "en") if language_prefs else "en"
            logger.info(f"🔍 [LANGUAGE] Retrieved preferences: {language_prefs}")
            logger.info(f"🔍 [LANGUAGE] Using visit_language='{visit_language}' for AI processing")
        except Exception as e:
            logger.warning(f"🔍 [LANGUAGE] Failed to fetch language preferences for user {user_id}: {e}. Using default 'en'")
            visit_language = "en"

        # Step B: Fetch raw transcript text from DB
        logger.info(f"Fetching transcript text for transcript_id: {transcript_id}")
        raw_text = await get_transcript_text(transcript_id)

        if not raw_text or not raw_text.strip():
            raise ValueError(f"No transcript text found for transcript_id {transcript_id}")

        logger.info(f"Retrieved transcript text (length: {len(raw_text)} chars)")

        # Step C: Generate structured summary using Vertex Gemini
        logger.info(f"Generating AI structured summary for visit {visit_id} in language {visit_language}")
        structured_result = await generate_visit_summary(raw_text, visit_language)

        # Feature-flagged normalization for V2 outputs
        prompt_version = _get_prompt_version()
        if prompt_version == "v2":
            structured_result = normalize_v2_summary(structured_result, visit_language)

        # Extract summary text for backward compatibility
        summary_text = structured_result.get("summary", "")
        logger.info(f"Generated structured summary (length: {len(summary_text)} chars)")

        # Step C: Save structured summary to database
        logger.info(f"Saving structured summary to database for transcript {transcript_id}")
        summary_id = await insert_ai_summary_log(
            transcript_id,
            visit_id,
            user_id,
            summary_text,
            structured_result,
        )
        try:
            await increment_summary_count(user_id)
        except Exception:
            logger.warning(
                "Summary count increment failed (non-fatal) user_id=%s visit_id=%s",
                user_id,
                visit_id,
                exc_info=True,
            )
        logger.info(f"Structured summary saved successfully for visit {visit_id}")

        doctor_name = structured_result.get("doctor_name")
        if not isinstance(doctor_name, str) or not doctor_name.strip():
            match = re.search(
                r"(?:Dr\.?|Doctor)\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+){0,3})",
                raw_text or "",
                flags=re.IGNORECASE,
            )
            if match:
                doctor_name = match.group(1).strip()

        specialty = structured_result.get("specialty")

        title = structured_result.get("visit_display_title")
        logger.info(
            "Updating visit metadata: visit_id=%s, doctor_name=%s, specialty=%s, title=%s",
            visit_id,
            doctor_name,
            specialty,
            title,
        )
        await update_visit_with_structured_data(
            visit_id=visit_id,
            doctor_name=doctor_name,
            specialty=specialty,
            title=title,
        )

        if summary_id:
            try:
                await generate_tasks_from_summary(
                    user_id=user_id,
                    visit_id=visit_id,
                    summary_id=summary_id,
                    structured_summary=structured_result,
                )
            except Exception:
                logger.exception(
                    "Auxiliary tasks generation failed (non-fatal) visit_id=%s",
                    visit_id,
                )
            try:
                await generate_reminders_from_actions(
                    user_id=user_id,
                    visit_id=visit_id,
                    actions=structured_result.get("actions", []),
                )
            except Exception:
                logger.exception(
                    "Auxiliary reminders generation failed (non-fatal) visit_id=%s",
                    visit_id,
                )
            s_task = asyncio.create_task(
                notify_caregiver_new_visit_symptoms(
                    user_id, visit_id, summary_id, structured_result
                )
            )
            s_task.add_done_callback(_log_background_task_error)

            r_task = asyncio.create_task(
                notify_caregivers_new_visit_recorded(
                    user_id=user_id,
                    visit_id=visit_id,
                )
            )
            r_task.add_done_callback(_log_background_task_error)

        # Step E: Return the summary text (for backward compatibility)
        return summary_text

    except Exception as e:
        logger.error(f"AI summary pipeline failed for visit {visit_id}: {str(e)}")
        raise

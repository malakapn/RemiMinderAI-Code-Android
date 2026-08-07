import os
import json
import time
import logging
from datetime import datetime
from typing import Dict

from services.gemini_client import generate_text, response_text, usage_token_counts

# from .db_service import log_ai_usage  # REMOVED: log_ai_usage was deleted during Supabase cleanup
from .db_reminders import insert_ai_reminders

# Import prompt template
try:
    # Try absolute import first (for direct execution)
    from utils.prompts.medical_summary import MEDICAL_SUMMARY_PROMPT
except ImportError:
    # Fallback to relative import (for package execution)
    from ..utils.prompts.medical_summary import MEDICAL_SUMMARY_PROMPT

logger = logging.getLogger(__name__)


async def generate_ai_summary(data: dict) -> Dict:
    visit_id = data.get('visit_id')
    logger.info(f"AI Service started for visit: {visit_id}")

    # Get required environment variables
    api_key = os.getenv("GEMINI_API_KEY")
    model_name = os.getenv("MODEL_NAME")
    input_cost_per_m = float(os.getenv("GEMINI_INPUT_COST_PER_M"))
    output_cost_per_m = float(os.getenv("GEMINI_OUTPUT_COST_PER_M"))

    if not api_key:
        raise RuntimeError("GEMINI_API_KEY not set")
    if not model_name:
        raise RuntimeError("MODEL_NAME not set")

    transcript = data["transcript"]
    current_datetime = datetime.now().strftime("%A, %B %d, %Y, %I:%M %p %Z")
    prompt = MEDICAL_SUMMARY_PROMPT.format(
        current_datetime=current_datetime,
        transcript=transcript
    )

    try:
        start_time = time.time()
        response = generate_text(
            prompt,
            model_name=model_name,
            api_key=api_key,
        )
        latency = time.time() - start_time

        input_tokens, output_tokens = usage_token_counts(response)

        input_cost = (input_tokens / 1_000_000) * input_cost_per_m
        output_cost = (output_tokens / 1_000_000) * output_cost_per_m
        total_cost = input_cost + output_cost

        # Log AI usage - DISABLED: log_ai_usage was deleted during Supabase cleanup
        # await log_ai_usage({
        #     "visit_id": visit_id,
        #     "user_id": data.get("user_id"),
        #     "transcript_id": data.get("transcript_id"),
        #     "input_tokens": input_tokens,
        #     "output_tokens": output_tokens,
        #     "total_cost": total_cost,
        # })

        # Parse JSON response
        text_output = response_text(response)
        start_json = text_output.find("{")
        end_json = text_output.rfind("}")
        json_string = text_output[start_json:end_json + 1]
        json_output = json.loads(json_string)

        logger.info(f"Summary generated in {latency:.2f}s, cost: ${total_cost:.6f}")
        # Build result
        result = {
            "summary": json_output.get("summary", f"AI Processing error:{transcript}"),
            "action_items": json_output.get("action_items", []),
            "questions_next_visit": json_output.get("questions_next_visit", []),
            "key_diagnoses": json_output.get("key_diagnoses", []),
            "medications": json_output.get("medications", []),
            "reminders": json_output.get("reminders", []),
            "title": json_output.get("title", "Doctor Office Visit"),
        }

        # Insert reminders if we have user and visit IDs
        user_id = data.get("user_id")
        if user_id and visit_id:
            inserted_reminders = await insert_ai_reminders(
                ai_summary_result=result,
                user_id=user_id,
                visit_id=visit_id,
            )
            logger.info(f"Inserted {len(inserted_reminders)} reminders into database")

        return result
        
    except json.JSONDecodeError as e:
        logger.error(f"JSON parsing failed: {str(e)}")
        return {
            "summary": f"Error processing visit summary. Please contact support:{transcript}",
            "action_items": ["Review visit recording"],
            "questions_next_visit": ["Could you clarify the diagnosis?"],
            "key_diagnoses": [],
            "medications": [],
            "reminders": [],
            "title": ""
        }
    except Exception as e:
        logger.error(f"AI Service Failed: {str(e)}")
        raise Exception(f"AI service failed: {str(e)}")

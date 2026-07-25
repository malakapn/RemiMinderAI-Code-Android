import base64
import logging
import os
from typing import Any, Optional

import requests
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from services.auth_gateway import get_current_user_jwt as get_current_user
from services.db_service import get_user_summaries, get_user_uuid
from services.reminder_service import list_patient_reminders
from services.subscription_service import (
    PLAN_PREMIUM,
    enforce_remivox_access,
    increment_remivox_interaction,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/remivox", tags=["RemiVox"])


class RemiVoxBriefingResponse(BaseModel):
    text: str
    audio_base64: Optional[str] = None
    content_type: Optional[str] = None
    audio_unavailable: bool = False


def _items(bucket: Any) -> list[dict]:
    if not isinstance(bucket, list):
        return []
    return [item for item in bucket if isinstance(item, dict)]


def _reminder_title(item: dict) -> str:
    return (
        item.get("title")
        or item.get("message")
        or item.get("medication_name")
        or item.get("reminder_type")
        or "reminder"
    ).strip()


def _build_briefing(reminders: dict, summaries: list[dict]) -> str:
    today = _items(reminders.get("today"))
    upcoming = _items(reminders.get("upcoming"))
    past = _items(reminders.get("past"))
    missed = [
        item for item in past
        if str(item.get("status", "")).strip().lower() == "missed"
        or str(item.get("display_status", "")).strip().lower() == "missed"
    ]

    parts: list[str] = ["Hi, I'm Vox."]
    if today:
        names = ", ".join(_reminder_title(item) for item in today[:2])
        parts.append(f"Today you have {len(today)} reminder{'s' if len(today) != 1 else ''}: {names}.")
    elif upcoming:
        names = ", ".join(_reminder_title(item) for item in upcoming[:2])
        parts.append(f"You have no reminders due today. Next up: {names}.")
    else:
        parts.append("You do not have any reminders scheduled for today.")

    if missed:
        parts.append(f"You have {len(missed)} missed reminder{'s' if len(missed) != 1 else ''} to review.")

    if summaries:
        latest = summaries[0]
        summary = str(latest.get("summary") or latest.get("summary_text") or "").strip()
        title = str(latest.get("title") or "your latest doctor visit").strip()
        if summary:
            short = summary[:220].rstrip()
            parts.append(f"From {title}: {short}")

    parts.append("Please follow your doctor's instructions and ask a clinician if anything feels unclear.")
    return " ".join(parts)


def _synthesize_smallestai(text: str) -> tuple[Optional[str], Optional[str]]:
    api_key = os.getenv("SMALLESTAI_API_KEY", "").strip()
    if not api_key:
        return None, None

    url = os.getenv(
        "SMALLESTAI_TTS_URL",
        "https://api.smallest.ai/waves/v1/lightning-v3.1/get_speech",
    ).strip()
    voice_id = os.getenv("SMALLESTAI_VOICE_ID", "olivia").strip()
    output_format = os.getenv("SMALLESTAI_OUTPUT_FORMAT", "mp3").strip()
    sample_rate = int(os.getenv("SMALLESTAI_SAMPLE_RATE", "24000"))

    response = requests.post(
        url,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        json={
            "text": text,
            "voice_id": voice_id,
            "sample_rate": sample_rate,
            "speed": 0.95,
            "language": "en",
            "output_format": output_format,
        },
        timeout=25,
    )
    if response.status_code >= 400:
        logger.warning("SmallestAI TTS failed: %s %s", response.status_code, response.text[:300])
        raise HTTPException(status_code=502, detail="Vox voice generation failed. Please try again.")

    content_type = response.headers.get("content-type") or f"audio/{output_format}"
    return base64.b64encode(response.content).decode("ascii"), content_type


@router.post("/today", response_model=RemiVoxBriefingResponse)
async def remivox_today(current_user: dict = Depends(get_current_user)):
    firebase_uid = current_user.get("sub")
    if not firebase_uid:
        raise HTTPException(status_code=401, detail="Invalid token")

    status = await enforce_remivox_access(firebase_uid)
    user_uuid = await get_user_uuid(firebase_uid)
    reminders = await list_patient_reminders(user_uuid)
    summaries = await get_user_summaries(user_uuid, firebase_uid=firebase_uid)
    text = _build_briefing(reminders, summaries)

    audio_base64, content_type = _synthesize_smallestai(text)
    if status["plan"] != PLAN_PREMIUM:
        await increment_remivox_interaction(firebase_uid)

    return RemiVoxBriefingResponse(
        text=text,
        audio_base64=audio_base64,
        content_type=content_type,
        audio_unavailable=audio_base64 is None,
    )

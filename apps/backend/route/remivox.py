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


class RemiVoxAskRequest(BaseModel):
    prompt: Optional[str] = None


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


def _latest_summary_text(summaries: list[dict]) -> tuple[str, str]:
    if not summaries:
        return "your latest doctor visit", ""
    latest = summaries[0]
    title = str(latest.get("title") or "your latest doctor visit").strip()
    summary = str(latest.get("summary") or latest.get("summary_text") or "").strip()
    return title, summary


def _filter_items(items: list[dict], *needles: str) -> list[dict]:
    out: list[dict] = []
    for item in items:
      haystack = " ".join(
          str(item.get(key, "")) for key in ("title", "message", "reminder_type", "type")
      ).lower()
      if any(needle in haystack for needle in needles):
          out.append(item)
    return out


def _build_prompt_answer(prompt: str, reminders: dict, summaries: list[dict]) -> str:
    query = (prompt or "").strip().lower()
    today = _items(reminders.get("today"))
    upcoming = _items(reminders.get("upcoming"))
    past = _items(reminders.get("past"))
    missed = [
        item for item in past
        if str(item.get("status", "")).strip().lower() == "missed"
        or str(item.get("display_status", "")).strip().lower() == "missed"
    ]
    title, summary = _latest_summary_text(summaries)

    if any(word in query for word in ("last doctor", "last visit", "summary", "doctor visit", "notes")):
        if summary:
            return (
                f"Your latest visit summary from {title} says: {summary[:500]} "
                "Please follow your doctor's instructions."
            )
        return "I do not see a completed doctor visit summary yet."

    if any(word in query for word in ("appointment", "appt", "next visit", "schedule")):
        appts = _filter_items(today + upcoming, "appointment", "appt", "visit")
        if appts:
            names = ", ".join(_reminder_title(item) for item in appts[:3])
            return f"Here is what I found for appointments or visits: {names}."
        if upcoming:
            names = ", ".join(_reminder_title(item) for item in upcoming[:3])
            return f"I do not see a specific appointment label, but your next upcoming reminders are: {names}."
        return "I do not see an upcoming appointment in your reminders right now."

    if any(word in query for word in ("med", "medicine", "medication", "pill", "take")):
        meds = _filter_items(today + upcoming, "med", "medicine", "medication", "pill")
        if meds:
            names = ", ".join(_reminder_title(item) for item in meds[:3])
            return f"Here are the medication reminders I found: {names}. Please take medicines only as prescribed."
        return "I do not see medication reminders due right now."

    if any(word in query for word in ("missed", "late", "forgot")):
        if missed:
            names = ", ".join(_reminder_title(item) for item in missed[:3])
            return f"You have missed reminders to review: {names}."
        return "I do not see any missed reminders right now."

    if "task" in query or "to do" in query or "todo" in query:
        tasks = _filter_items(today + upcoming, "task", "to do", "todo")
        if tasks:
            names = ", ".join(_reminder_title(item) for item in tasks[:3])
            return f"Here are your tasks: {names}."
        return "I do not see any tasks due right now."

    return _build_briefing(reminders, summaries)


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
    return await _remivox_response(current_user=current_user, prompt=None)


@router.post("/ask", response_model=RemiVoxBriefingResponse)
async def remivox_ask(
    request: RemiVoxAskRequest,
    current_user: dict = Depends(get_current_user),
):
    return await _remivox_response(current_user=current_user, prompt=request.prompt)


async def _remivox_response(current_user: dict, prompt: Optional[str]):
    firebase_uid = current_user.get("sub")
    if not firebase_uid:
        raise HTTPException(status_code=401, detail="Invalid token")

    status = await enforce_remivox_access(firebase_uid)
    user_uuid = await get_user_uuid(firebase_uid)
    reminders = await list_patient_reminders(user_uuid)
    summaries = await get_user_summaries(user_uuid, firebase_uid=firebase_uid)
    text = _build_prompt_answer(prompt or "", reminders, summaries) if prompt else _build_briefing(reminders, summaries)

    audio_base64, content_type = _synthesize_smallestai(text)
    if status["plan"] != PLAN_PREMIUM:
        await increment_remivox_interaction(firebase_uid)

    return RemiVoxBriefingResponse(
        text=text,
        audio_base64=audio_base64,
        content_type=content_type,
        audio_unavailable=audio_base64 is None,
    )

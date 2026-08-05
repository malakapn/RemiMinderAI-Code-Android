"""
RemiVox v2 pipeline orchestrator (Stage A stub).

Target flow:
  Audio → Pulse STT → Language Detection → Intent Router → Action Executor
  → DB/API → Response Builder → Lightning TTS

Stage A does NOT replace route/remivox.py. Callers must continue using the
existing route until Stage B+ is approved and wired.
"""

from __future__ import annotations

from typing import Any, Optional

from services.remivox.intents.models import IntentResult, VoxIntent


async def run_pipeline(
    *,
    user_uuid: str,
    prompt: Optional[str] = None,
    audio_base64: Optional[str] = None,
    content_type: str = "audio/wav",
    reply_language: str = "en",
    timezone_name: str = "UTC",
    auto_detect_language: bool = True,
    session_id: Optional[str] = None,
) -> dict[str, Any]:
    """
    End-to-end v2 pipeline entrypoint.

    Stage A: raises NotImplementedError so production cannot accidentally switch.
    """
    _ = (
        user_uuid,
        prompt,
        audio_base64,
        content_type,
        reply_language,
        timezone_name,
        auto_detect_language,
        session_id,
    )
    raise NotImplementedError(
        "RemiVox v2 pipeline is Stage A scaffold only. "
        "Production path remains route/remivox.py + remivox_intents.handle_prompt."
    )


def empty_intent_placeholder(language: str = "en") -> IntentResult:
    """Helper for tests / scaffolding."""
    return IntentResult(intent=VoxIntent.UNKNOWN, language=language, entities={})

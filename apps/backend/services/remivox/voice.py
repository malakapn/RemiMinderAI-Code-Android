"""
Voice Layer (Stage A stub).

Production Pulse STT + Lightning TTS remain in route/remivox.py until Stage B.
This module documents the v2 Voice API surface without changing runtime behavior.

Keep using:
- SmallestAI Pulse for STT
- SmallestAI Lightning for TTS
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional


@dataclass(frozen=True)
class SttResult:
    transcript: str
    detected_language: str
    provider: str = "pulse"


@dataclass(frozen=True)
class TtsResult:
    audio_base64: Optional[str]
    content_type: Optional[str]
    language: str
    status: str  # ok | unavailable | failed
    provider: str = "lightning"


def transcribe_pulse(
    audio_b64: str,
    *,
    language: str = "multi",
    content_type: str = "audio/wav",
) -> SttResult:
    """
    Transcribe with SmallestAI Pulse.

    Stage A: not wired. Stage B will move _pulse_transcribe here and fix
    auto_detect_language to use language='multi' (not forced 'en').
    """
    raise NotImplementedError(
        "Voice Layer Stage A stub — production STT remains in route/remivox.py"
    )


def synthesize_lightning(
    text: str,
    *,
    language: str = "en",
) -> TtsResult:
    """
    Synthesize with SmallestAI Lightning.

    Stage A: not wired. Stage B will move _synthesize_smallestai here.
    """
    raise NotImplementedError(
        "Voice Layer Stage A stub — production TTS remains in route/remivox.py"
    )

"""Runtime configuration for the RemiVox v3 streaming pipeline."""

from __future__ import annotations

import os


def _env_int(name: str, default: int, *, minimum: int = 1) -> int:
    try:
        value = int((os.getenv(name) or str(default)).strip())
    except (TypeError, ValueError):
        return default
    return value if value >= minimum else default


def _env_float(name: str, default: float, *, minimum: float = 0.0) -> float:
    try:
        value = float((os.getenv(name) or str(default)).strip())
    except (TypeError, ValueError):
        return default
    return value if value >= minimum else default


REMIVOX_PIPELINE = (os.getenv("REMIVOX_PIPELINE") or "legacy").strip().lower()

REMIVOX_STT_MODEL = (os.getenv("REMIVOX_STT_MODEL") or "pulse").strip()
REMIVOX_TTS_MODEL = (
    os.getenv("REMIVOX_TTS_MODEL") or "lightning_v3.1"
).strip()
REMIVOX_TTS_VOICE = (os.getenv("REMIVOX_TTS_VOICE") or "meher").strip()
REMIVOX_TTS_SPEED = _env_float("REMIVOX_TTS_SPEED", 0.85, minimum=0.1)
REMIVOX_EOU_TIMEOUT_MS = _env_int("REMIVOX_EOU_TIMEOUT_MS", 2000)
REMIVOX_KEYWORD_BOOST = _env_float(
    "REMIVOX_KEYWORD_BOOST",
    3.0,
    minimum=0.0,
)

REMIVOX_PING_INTERVAL_S = _env_int("REMIVOX_PING_INTERVAL_S", 30)
REMIVOX_SILENCE_TIMEOUT_S = _env_int("REMIVOX_SILENCE_TIMEOUT_S", 15)
REMIVOX_SESSION_MAX_S = _env_int("REMIVOX_SESSION_MAX_S", 300)

REMIVOX_INPUT_SAMPLE_RATE = 16000
REMIVOX_OUTPUT_SAMPLE_RATE = 24000
REMIVOX_INPUT_NUM_CHANNELS = 1
REMIVOX_AUDIO_BYTES_PER_SAMPLE = 2
REMIVOX_AUDIO_CHUNK_MS = 200


__all__ = [
    "REMIVOX_AUDIO_BYTES_PER_SAMPLE",
    "REMIVOX_AUDIO_CHUNK_MS",
    "REMIVOX_EOU_TIMEOUT_MS",
    "REMIVOX_INPUT_NUM_CHANNELS",
    "REMIVOX_INPUT_SAMPLE_RATE",
    "REMIVOX_KEYWORD_BOOST",
    "REMIVOX_OUTPUT_SAMPLE_RATE",
    "REMIVOX_PING_INTERVAL_S",
    "REMIVOX_PIPELINE",
    "REMIVOX_SILENCE_TIMEOUT_S",
    "REMIVOX_SESSION_MAX_S",
    "REMIVOX_STT_MODEL",
    "REMIVOX_TTS_MODEL",
    "REMIVOX_TTS_SPEED",
    "REMIVOX_TTS_VOICE",
]

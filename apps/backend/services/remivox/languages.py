"""
RemiVox v2 language helpers.

Re-exports remivox_languages (10 locales) and Stage D session language helpers.
Do not remove services/remivox_languages.py.
"""

from __future__ import annotations

from typing import Optional

from services.remivox_languages import (
    LANGUAGE_DISPLAY_NAMES,
    SUPPORTED_LANGUAGE_CODES,
    language_display_name,
    normalize_language_code,
)

# Canonical ordered list for Vox v2 (product order).
SUPPORTED_VOX_LANGUAGE_ORDER: tuple[str, ...] = (
    "en",  # English
    "hi",  # Hindi
    "gu",  # Gujarati
    "ta",  # Tamil
    "pa",  # Punjabi
    "bn",  # Bengali / Bangla
    "fr",  # French
    "pt",  # Portuguese
    "es",  # Spanish
    "de",  # German
)

assert set(SUPPORTED_VOX_LANGUAGE_ORDER) == SUPPORTED_LANGUAGE_CODES


def resolve_session_language(
    *,
    detected_language: Optional[str] = None,
    preferred_language: Optional[str] = None,
    has_audio: bool = False,
) -> str:
    """
    Choose the conversation / reply language.

    Rules:
    - With audio: prefer Pulse-detected language when supported.
    - Without audio: use preferred app language.
    - Never force English unless detected/preferred is English (or unsupported → preferred).
    """
    preferred = normalize_language_code(preferred_language or "en")
    if has_audio and detected_language:
        detected = normalize_language_code(detected_language, default=preferred)
        if detected in SUPPORTED_LANGUAGE_CODES:
            return detected
        return preferred
    return preferred


def ensure_supported_language(code: Optional[str], fallback: str = "en") -> str:
    """Clamp to supported Vox languages without silently rewriting valid non-EN codes."""
    normalized = normalize_language_code(code, default=fallback)
    return normalized if normalized in SUPPORTED_LANGUAGE_CODES else normalize_language_code(fallback)


__all__ = [
    "LANGUAGE_DISPLAY_NAMES",
    "SUPPORTED_LANGUAGE_CODES",
    "SUPPORTED_VOX_LANGUAGE_ORDER",
    "language_display_name",
    "normalize_language_code",
    "resolve_session_language",
    "ensure_supported_language",
]

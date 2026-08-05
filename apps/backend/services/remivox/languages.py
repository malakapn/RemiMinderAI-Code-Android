"""
RemiVox v2 language helpers.

Stage A: re-exports the existing 10-locale helpers from remivox_languages.py
so callers can import from the v2 package without duplicating logic.
Do not remove services/remivox_languages.py in Stage A.
"""

from __future__ import annotations

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

__all__ = [
    "LANGUAGE_DISPLAY_NAMES",
    "SUPPORTED_LANGUAGE_CODES",
    "SUPPORTED_VOX_LANGUAGE_ORDER",
    "language_display_name",
    "normalize_language_code",
]

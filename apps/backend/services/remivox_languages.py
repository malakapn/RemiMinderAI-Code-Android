"""RemiVox language helpers aligned with the mobile app's 10 locales."""

from __future__ import annotations

SUPPORTED_LANGUAGE_CODES = {
    "en",
    "es",
    "hi",
    "fr",
    "pt",
    "de",
    "bn",
    "ta",
    "gu",
    "pa",
}

LANGUAGE_DISPLAY_NAMES = {
    "en": "English",
    "es": "Spanish",
    "hi": "Hindi",
    "fr": "French",
    "pt": "Portuguese",
    "de": "German",
    "bn": "Bangla",
    "ta": "Tamil",
    "gu": "Gujarati",
    "pa": "Punjabi",
}


def normalize_language_code(raw: str | None, default: str = "en") -> str:
    code = (raw or "").strip().lower().replace("_", "-")
    if "-" in code:
        code = code.split("-", 1)[0]
    return code if code in SUPPORTED_LANGUAGE_CODES else default


def language_display_name(code: str | None) -> str:
    normalized = normalize_language_code(code)
    return LANGUAGE_DISPLAY_NAMES.get(normalized, "English")

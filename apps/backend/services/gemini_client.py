"""Thin wrapper around the Google GenAI SDK (replaces deprecated google.generativeai)."""

from __future__ import annotations

import os
from functools import lru_cache
from typing import Any, Optional

from google import genai
from google.genai import types


@lru_cache(maxsize=4)
def get_gemini_client(api_key: str) -> genai.Client:
    return genai.Client(api_key=api_key)


def resolve_gemini_api_key() -> Optional[str]:
    key = (
        os.getenv("GEMINI_API_KEY")
        or os.getenv("GOOGLE_API_KEY")
        or os.getenv("GOOGLE_GENAI_API_KEY")
        or ""
    ).strip()
    return key or None


def generate_text(
    prompt: str,
    *,
    model_name: Optional[str] = None,
    api_key: Optional[str] = None,
    temperature: float = 0.5,
    top_p: float = 0.9,
    top_k: int = 40,
) -> Any:
    """
    Call Gemini generate_content and return the SDK response object.
    Raises if API key is missing or the call fails.
    """
    key = (api_key or resolve_gemini_api_key() or "").strip()
    if not key:
        raise RuntimeError("GEMINI_API_KEY not set")

    model = (model_name or os.getenv("MODEL_NAME") or "gemini-2.5-flash-lite").strip()
    client = get_gemini_client(key)
    return client.models.generate_content(
        model=model,
        contents=prompt,
        config=types.GenerateContentConfig(
            temperature=temperature,
            top_p=top_p,
            top_k=top_k,
        ),
    )


def response_text(response: Any) -> str:
    text = getattr(response, "text", None)
    if isinstance(text, str):
        return text.strip()
    return ""


def usage_token_counts(response: Any) -> tuple[int, int]:
    meta = getattr(response, "usage_metadata", None)
    if meta is None:
        return 0, 0
    prompt = (
        getattr(meta, "prompt_token_count", None)
        or getattr(meta, "input_token_count", None)
        or 0
    )
    candidates = (
        getattr(meta, "candidates_token_count", None)
        or getattr(meta, "output_token_count", None)
        or 0
    )
    return int(prompt), int(candidates)

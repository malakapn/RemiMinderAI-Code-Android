"""
Intent Router (Stage A stub).

Stage B+: map transcript + conversation state → IntentResult.
Must remain deterministic for protected care actions (no Hydra decisions).
"""

from __future__ import annotations

from typing import Any, Optional

from services.remivox.intents.models import IntentResult, VoxIntent


def route_intent(
    *,
    text: str,
    language: str = "en",
    pending_intent: Optional[str] = None,
    pending_entities: Optional[dict[str, Any]] = None,
) -> IntentResult:
    """
    Resolve user text into a structured IntentResult.

    Stage A: returns UNKNOWN — production still uses remivox_intents.handle_prompt.
    """
    _ = (text, pending_intent, pending_entities)
    return IntentResult(
        intent=VoxIntent.UNKNOWN,
        language=language,
        entities={},
        confidence=0.0,
        raw_transcript=text,
        normalized_text=text,
    )

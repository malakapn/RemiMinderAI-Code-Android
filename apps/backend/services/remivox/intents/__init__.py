"""Intent Layer: structured understanding of user requests (no side effects)."""

from services.remivox.intents.models import (
    PROTECTED_ACTIONS,
    IntentResult,
    VoxIntent,
)

__all__ = [
    "PROTECTED_ACTIONS",
    "IntentResult",
    "VoxIntent",
]

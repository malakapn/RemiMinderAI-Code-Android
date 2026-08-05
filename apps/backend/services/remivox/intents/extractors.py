"""
Entity extractors for RemiVox v2 (Stage A stubs).

Stage C will implement:
- frequency phrases (every day, Mon–Sun, 7 days a week, every morning/evening)
- time parsing (8 PM → 20:00, number words)
- medication / title extraction
"""

from __future__ import annotations

from typing import Optional

from services.remivox.intents.models import VoxRecurrence


def extract_frequency(text: str) -> Optional[VoxRecurrence]:
    """Map natural-language frequency phrases to VoxRecurrence. Stage A: None."""
    _ = text
    return None


def extract_time_hhmm(text: str) -> Optional[str]:
    """Extract local time as HH:MM 24-hour. Stage A: None."""
    _ = text
    return None


def extract_medication_or_title(text: str) -> Optional[str]:
    """Extract medication / reminder title. Stage A: None."""
    _ = text
    return None

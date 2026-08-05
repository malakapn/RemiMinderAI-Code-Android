"""
RemiVox v2 frequency / natural-language extraction (Stage C).
"""

from __future__ import annotations

import unittest

from services.remivox.intents.extractors import extract_frequency
from services.remivox.intents.models import VoxRecurrence


class RemiVoxV2FrequencyTests(unittest.TestCase):
    def test_monday_through_sunday_is_daily(self):
        self.assertEqual(
            extract_frequency("Metoprolol at 8 PM Monday through Sunday"),
            VoxRecurrence.DAILY,
        )

    def test_every_day_variants(self):
        for phrase in (
            "every day",
            "daily",
            "all days",
            "7 days a week",
            "every morning",
            "every evening",
        ):
            self.assertEqual(extract_frequency(phrase), VoxRecurrence.DAILY)


if __name__ == "__main__":
    unittest.main()

import unittest
from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch

from services.remivox_intents import (
    _extract_create_title,
    _parse_recurrence,
    _parse_time_today,
    build_briefing,
    build_hydra_instructions,
)
from services.remivox_languages import normalize_language_code


class RemiVoxLanguageTests(unittest.TestCase):
    def test_normalize_bangla(self):
        self.assertEqual(normalize_language_code("bn"), "bn")
        self.assertEqual(normalize_language_code("BN-BD"), "bn")
        self.assertEqual(normalize_language_code("xx"), "en")


class RemiVoxParseTests(unittest.TestCase):
    def test_extract_allegra_title(self):
        title = _extract_create_title(
            "Vox can you setup a reminder for Allegra everyday at 8 pm"
        )
        self.assertIsNotNone(title)
        self.assertIn("Allegra", title)

    def test_recurrence_daily(self):
        self.assertEqual(_parse_recurrence("every day at 8"), "daily")
        self.assertEqual(_parse_recurrence("weekly vitamins"), "weekly")
        self.assertEqual(_parse_recurrence("once tomorrow"), "once")

    def test_parse_time_8pm(self):
        dt = _parse_time_today("set reminder at 8 pm", "UTC")
        self.assertIsNotNone(dt)
        assert dt is not None
        self.assertEqual(dt.astimezone(timezone.utc).hour, 20)

    def test_briefing_contains_disclaimer(self):
        text = build_briefing({"today": [], "upcoming": [], "past": []}, [])
        self.assertIn("Hi, I'm Vox", text)
        self.assertIn("medical", text.lower())

    def test_hydra_translate_instructions(self):
        text = build_hydra_instructions(
            source_language="en",
            target_language="bn",
            mode="translate",
        )
        self.assertIn("Bangla", text)
        self.assertIn("not a doctor", text.lower())


class RemiVoxHandlePromptTests(unittest.IsolatedAsyncioTestCase):
    async def test_create_reminder_calls_service(self):
        from services.remivox_intents import handle_prompt

        fake_created = {"id": "r1", "title": "Allegra"}
        with patch(
            "services.remivox_intents.create_new_reminder",
            new=AsyncMock(return_value=fake_created),
        ) as create_mock:
            result = await handle_prompt(
                prompt="set a reminder for Allegra every day at 8 pm",
                user_uuid="user-1",
                reminders={"today": [], "upcoming": [], "past": []},
                summaries=[],
                timezone_name="UTC",
                reply_language="en",
            )
        self.assertEqual(result["action"], "create_reminder")
        self.assertIn("Allegra", result["text"])
        create_mock.assert_awaited()

    async def test_complete_checkin(self):
        from services.remivox_intents import handle_prompt

        reminders = {
            "today": [
                {
                    "id": "m1",
                    "title": "Metoprolol",
                    "reminder_type": "medication",
                    "status": "pending",
                    "display_status": "Due Now",
                }
            ],
            "upcoming": [],
            "past": [],
        }
        with patch(
            "services.remivox_intents.complete_reminder",
            new=AsyncMock(return_value={"id": "m1"}),
        ) as complete_mock:
            result = await handle_prompt(
                prompt="I took Metoprolol",
                user_uuid="user-1",
                reminders=reminders,
                summaries=[],
            )
        self.assertEqual(result["action"], "complete_reminder")
        complete_mock.assert_awaited()

    async def test_read_summary(self):
        from services.remivox_intents import handle_prompt

        result = await handle_prompt(
            prompt="Vox can you read my last summary",
            user_uuid="user-1",
            reminders={"today": [], "upcoming": [], "past": []},
            summaries=[{"title": "Cardiology", "summary": "Blood pressure improved."}],
        )
        self.assertEqual(result["action"], "read_summary")
        self.assertIn("Blood pressure improved", result["text"])


if __name__ == "__main__":
    unittest.main()

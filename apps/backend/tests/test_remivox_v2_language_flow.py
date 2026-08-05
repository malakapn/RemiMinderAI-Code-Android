"""
Stage D: language flow validation + Hydra executor bypass regression.
"""

from __future__ import annotations

import unittest
from unittest.mock import AsyncMock, patch

from services.remivox.intents.models import VoxIntent
from services.remivox.intents.router import route_intent
from services.remivox.languages import (
    SUPPORTED_VOX_LANGUAGE_ORDER,
    resolve_session_language,
)
from services.remivox.observability import log_interaction
from services.remivox.pipeline import run_care_turn
from services.remivox_intents import execute_hydra_tool, hydra_tool_schemas


class SessionLanguageTests(unittest.TestCase):
    def test_all_supported_languages_preserved_from_detection(self):
        for code in SUPPORTED_VOX_LANGUAGE_ORDER:
            resolved = resolve_session_language(
                detected_language=code,
                preferred_language="en",
                has_audio=True,
            )
            self.assertEqual(resolved, code, f"expected {code}, got {resolved}")

    def test_does_not_force_english_when_hindi_detected(self):
        self.assertEqual(
            resolve_session_language(
                detected_language="hi",
                preferred_language="en",
                has_audio=True,
            ),
            "hi",
        )

    def test_text_only_uses_preferred(self):
        self.assertEqual(
            resolve_session_language(
                detected_language=None,
                preferred_language="gu",
                has_audio=False,
            ),
            "gu",
        )

    def test_unsupported_detection_falls_back_to_preferred(self):
        self.assertEqual(
            resolve_session_language(
                detected_language="xx",
                preferred_language="ta",
                has_audio=True,
            ),
            "ta",
        )


class LanguageFlowPipelineTests(unittest.IsolatedAsyncioTestCase):
    async def test_reply_language_matches_detected_for_each_locale(self):
        for code in SUPPORTED_VOX_LANGUAGE_ORDER:
            with patch(
                "services.remivox.actions.executor.create_new_reminder",
                new_callable=AsyncMock,
            ) as mock_create:
                mock_create.return_value = {"id": "r1", "title": "Metoprolol"}
                out = await run_care_turn(
                    user_uuid=f"user-{code}",
                    text="Set a reminder for Metoprolol at 8 PM every day",
                    language=code,
                    detected_language=code,
                    reminders={"today": [], "upcoming": [], "past": []},
                    summaries=[],
                    session_id=f"sess-{code}",
                )
                self.assertEqual(out["reply_language"], code)
                self.assertEqual(out["intent"], VoxIntent.CREATE_REMINDER.value)


class PhiLoggingTests(unittest.TestCase):
    def test_interaction_log_drops_transcript_and_entities(self):
        record = log_interaction(
            user_id="u1",
            transcript="Take Metoprolol at 8",
            entities={"medication": "Metoprolol"},
            intent="CREATE_REMINDER",
            action="create_reminder",
            success=True,
            detected_language="en",
            response_language="en",
            confidence=1.0,
            missing_slots=[],
            validation_result="ok",
            execution_result="success",
            extra={"medication": "Metoprolol", "message_key": "created"},
        )
        self.assertNotIn("transcript", record)
        self.assertNotIn("entities", record)
        self.assertEqual(record.get("intent"), "CREATE_REMINDER")
        extra = record.get("extra") or {}
        self.assertNotIn("medication", extra)
        self.assertEqual(extra.get("message_key"), "created")


class HydraBypassRegressionTests(unittest.IsolatedAsyncioTestCase):
    def test_protected_tools_absent_from_schemas(self):
        names = {t["name"] for t in hydra_tool_schemas()}
        for protected in (
            "create_reminder",
            "update_reminder",
            "complete_reminder",
            "snooze_reminder",
            "skip_reminder",
            "delete_reminder",
        ):
            self.assertNotIn(protected, names)

    async def test_hydra_cannot_bypass_executor_for_protected_actions(self):
        with patch(
            "services.reminder_service.create_new_reminder",
            new_callable=AsyncMock,
        ) as mock_create:
            out = await execute_hydra_tool(
                name="create_reminder",
                arguments={"title": "Metoprolol", "hour": 20, "recurrence": "daily"},
                user_uuid="user-1",
                reminders={"today": [], "upcoming": [], "past": []},
                summaries=[],
            )
            self.assertIn("Intent Router", out)
            mock_create.assert_not_called()

        for name in (
            "complete_reminder",
            "snooze_reminder",
            "skip_reminder",
            "delete_reminder",
            "update_reminder",
        ):
            out = await execute_hydra_tool(
                name=name,
                arguments={"title_hint": "Metoprolol"},
                user_uuid="user-1",
                reminders={
                    "today": [
                        {
                            "id": "m1",
                            "title": "Metoprolol",
                            "reminder_type": "medication",
                        }
                    ],
                    "upcoming": [],
                    "past": [],
                },
                summaries=[],
            )
            self.assertTrue(
                "Intent Router" in out or "protected" in out.lower() or "Blocked" in out
                or "cannot be executed by Hydra" in out
                or "handled by RemiVox" in out,
                msg=f"unexpected hydra output for {name}: {out}",
            )


class IntentStillDeterministicTests(unittest.TestCase):
    def test_create_still_routes(self):
        result = route_intent(
            text="Set Metoprolol reminder at 8 PM every day",
            language="hi",
        )
        self.assertEqual(result.intent, VoxIntent.CREATE_REMINDER)
        self.assertEqual(result.language, "hi")


if __name__ == "__main__":
    unittest.main()

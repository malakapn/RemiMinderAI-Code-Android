"""
RemiVox v2 Stage C — Intent Router, Action Executor, Hydra gating tests.
"""

from __future__ import annotations

import asyncio
import unittest
from unittest.mock import AsyncMock, patch

from services.remivox.actions.executor import execute_intent
from services.remivox.intents.extractors import extract_frequency, extract_time_hhmm
from services.remivox.intents.models import IntentResult, PROTECTED_ACTIONS, VoxIntent, VoxRecurrence
from services.remivox.intents.router import route_intent
from services.remivox.pipeline import run_care_turn
from services.remivox.response.builder import build_response
from services.remivox.state.conversation import clear_state, get_state
from services.remivox_intents import execute_hydra_tool, hydra_tool_schemas


def _run(coro):
    return asyncio.get_event_loop().run_until_complete(coro)


class ExtractorTests(unittest.TestCase):
    def test_monday_through_sunday_daily(self):
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

    def test_time_8pm(self):
        self.assertEqual(extract_time_hhmm("at 8 PM"), "20:00")


class CreateReminderRoutingTests(unittest.TestCase):
    def test_metoprolol_daily_8pm(self):
        result = route_intent(
            text="Set Metoprolol reminder at 8 PM every day",
            language="en",
        )
        self.assertEqual(result.intent, VoxIntent.CREATE_REMINDER)
        self.assertEqual(result.entities.get("medication"), "Metoprolol")
        self.assertEqual(result.entities.get("time"), "20:00")
        self.assertEqual(result.entities.get("frequency"), "daily")

    def test_missing_time_clarifies(self):
        result = route_intent(
            text="Remind me about Vitamin D",
            language="en",
        )
        self.assertEqual(result.intent, VoxIntent.CLARIFY)
        self.assertIn("time", result.missing_slots)
        pending = result.entities.get("pending_entities") or {}
        self.assertIn("Vitamin D", str(pending.get("medication") or pending.get("title") or ""))

    def test_hindi_language_tag_on_create(self):
        # After translate, English text is routed; language stays session/detected Hindi.
        result = route_intent(
            text="Remind me to take Metoprolol every day at 8 PM",
            language="hi",
        )
        self.assertEqual(result.intent, VoxIntent.CREATE_REMINDER)
        self.assertEqual(result.language, "hi")
        self.assertEqual(result.entities.get("frequency"), "daily")


class UpdateReminderRoutingTests(unittest.TestCase):
    def test_update_routing(self):
        result = route_intent(
            text="Change my Metoprolol reminder to 9 PM",
            language="en",
        )
        self.assertEqual(result.intent, VoxIntent.UPDATE_REMINDER)
        self.assertEqual(result.entities.get("time"), "21:00")


class CancelConfirmTests(unittest.TestCase):
    def test_cancel_action(self):
        result = route_intent(text="No, cancel that.", language="en")
        self.assertEqual(result.intent, VoxIntent.CANCEL_ACTION)

    def test_confirm_action_with_pending_delete(self):
        result = route_intent(
            text="Yes, delete that reminder.",
            language="en",
            pending_intent=VoxIntent.DELETE_REMINDER.value,
            pending_entities={"reminder_id": "abc", "medication": "Metoprolol"},
        )
        self.assertEqual(result.intent, VoxIntent.CONFIRM_ACTION)
        self.assertTrue(result.entities.get("confirmed"))


class CompleteAndReadTests(unittest.TestCase):
    def test_mark_taken(self):
        result = route_intent(text="Mark my Metoprolol as taken", language="en")
        self.assertEqual(result.intent, VoxIntent.COMPLETE_REMINDER)

    def test_read_medications_today(self):
        result = route_intent(text="Read my medications today", language="en")
        self.assertEqual(result.intent, VoxIntent.READ_TODAY_MEDICATIONS)


class AmbiguousUpdateTests(unittest.IsolatedAsyncioTestCase):
    async def test_ambiguous_update_asks_clarification(self):
        reminders = {
            "today": [
                {"id": "1", "title": "Metoprolol morning", "reminder_type": "medication"},
                {"id": "2", "title": "Metoprolol night", "reminder_type": "medication"},
            ],
            "upcoming": [],
            "past": [],
        }
        intent = route_intent(
            text="Update my Metoprolol reminder to 9 PM",
            language="en",
        )
        action = await execute_intent(
            intent_result=intent,
            user_uuid="user-1",
            reminders=reminders,
            summaries=[],
            timezone_name="UTC",
        )
        self.assertEqual(action.message_key, "ambiguous_reminder")
        self.assertEqual(action.pending_intent, VoxIntent.UPDATE_REMINDER.value)


class DeleteConfirmFlowTests(unittest.IsolatedAsyncioTestCase):
    async def test_delete_requires_confirmation(self):
        reminders = {
            "today": [
                {"id": "rid-1", "title": "Metoprolol", "reminder_type": "medication"},
            ],
            "upcoming": [],
            "past": [],
        }
        intent = route_intent(text="Delete my Metoprolol reminder", language="en")
        action = await execute_intent(
            intent_result=intent,
            user_uuid="user-1",
            reminders=reminders,
            summaries=[],
        )
        self.assertEqual(action.message_key, "confirm_delete")
        self.assertEqual(action.pending_intent, VoxIntent.DELETE_REMINDER.value)
        built = build_response(intent_result=intent, action_result=action)
        self.assertIn("delete", built["text"].lower())
        self.assertFalse(built["include_disclaimer"])


class HydraGatingTests(unittest.IsolatedAsyncioTestCase):
    def test_schemas_exclude_protected_tools(self):
        names = {t["name"] for t in hydra_tool_schemas()}
        for protected in (
            "create_reminder",
            "complete_reminder",
            "snooze_reminder",
            "skip_reminder",
            "delete_reminder",
            "update_reminder",
        ):
            self.assertNotIn(protected, names)
        self.assertIn("get_today_briefing", names)

    async def test_execute_blocks_protected_actions(self):
        for name in (
            "create_reminder",
            "complete_reminder",
            "snooze_reminder",
            "skip_reminder",
            "delete_reminder",
        ):
            out = await execute_hydra_tool(
                name=name,
                arguments={"title": "Metoprolol", "hour": 20},
                user_uuid="user-1",
                reminders={"today": [], "upcoming": [], "past": []},
                summaries=[],
            )
            self.assertIn("Intent Router", out)


class PipelineStateTests(unittest.IsolatedAsyncioTestCase):
    async def test_missing_slots_then_cancel(self):
        user = "pipeline-user"
        session = "s1"
        clear_state(user, session)
        with patch(
            "services.remivox.actions.executor.create_new_reminder",
            new_callable=AsyncMock,
        ) as mock_create:
            mock_create.return_value = {"id": "new-1", "title": "Vitamin D"}
            first = await run_care_turn(
                user_uuid=user,
                text="Remind me about Vitamin D",
                language="en",
                reminders={"today": [], "upcoming": [], "past": []},
                summaries=[],
                session_id=session,
            )
            self.assertEqual(first["intent"], "CLARIFY")
            state = get_state(user, session)
            self.assertIsNotNone(state)
            assert state is not None
            self.assertEqual(state.pending_intent, "CREATE_REMINDER")

            cancelled = await run_care_turn(
                user_uuid=user,
                text="No, cancel that.",
                language="en",
                reminders={"today": [], "upcoming": [], "past": []},
                summaries=[],
                session_id=session,
            )
            self.assertEqual(cancelled["intent"], "CANCEL_ACTION")
            self.assertIsNone(get_state(user, session))
            mock_create.assert_not_called()

    async def test_create_executes_via_reminder_service(self):
        user = "pipeline-user-2"
        session = "s2"
        clear_state(user, session)
        with patch(
            "services.remivox.actions.executor.create_new_reminder",
            new_callable=AsyncMock,
        ) as mock_create:
            mock_create.return_value = {"id": "r1", "title": "Metoprolol"}
            out = await run_care_turn(
                user_uuid=user,
                text="Set a reminder for Metoprolol at 8 PM every day",
                language="en",
                reminders={"today": [], "upcoming": [], "past": []},
                summaries=[],
                session_id=session,
                timezone_name="UTC",
            )
            self.assertEqual(out["intent"], "CREATE_REMINDER")
            self.assertTrue(out["success"])
            mock_create.assert_awaited()
            kwargs = mock_create.await_args.args[0]
            self.assertEqual(kwargs.title, "Metoprolol")
            self.assertEqual(kwargs.recurrence, "daily")


class DisclaimerPolicyTests(unittest.IsolatedAsyncioTestCase):
    async def test_disclaimer_on_medical_advice(self):
        intent = route_intent(text="What dose of Metoprolol should I take?", language="en")
        self.assertEqual(intent.intent, VoxIntent.MEDICAL_ADVICE_REFUSAL)
        action = await execute_intent(
            intent_result=intent,
            user_uuid="u",
            reminders={"today": [], "upcoming": [], "past": []},
            summaries=[],
        )
        built = build_response(intent_result=intent, action_result=action)
        self.assertTrue(built["include_disclaimer"])

    def test_no_disclaimer_on_create_response(self):
        intent = IntentResult(
            intent=VoxIntent.CREATE_REMINDER,
            language="en",
            entities={"medication": "Metoprolol", "time": "20:00", "frequency": "daily"},
        )
        from services.remivox.actions.executor import ActionResult

        action = ActionResult(
            success=True,
            action="create_reminder",
            message_key="created",
            payload={"title": "Metoprolol", "time": "20:00", "frequency": "daily"},
        )
        built = build_response(intent_result=intent, action_result=action)
        self.assertFalse(built["include_disclaimer"])
        self.assertNotIn("not medical advice", built["text"].lower())


class ProtectedActionsConstantTests(unittest.TestCase):
    def test_protected_set(self):
        for intent in (
            VoxIntent.CREATE_REMINDER,
            VoxIntent.UPDATE_REMINDER,
            VoxIntent.COMPLETE_REMINDER,
            VoxIntent.SNOOZE_REMINDER,
            VoxIntent.SKIP_REMINDER,
            VoxIntent.DELETE_REMINDER,
        ):
            self.assertIn(intent, PROTECTED_ACTIONS)


if __name__ == "__main__":
    unittest.main()

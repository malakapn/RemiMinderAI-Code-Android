"""
RemiVox v2 — Stage A model tests + Phase 8 skeleton.

Stage A:
  - Pydantic models and policy constants are exercised for real.
  - End-to-end intent/action cases are marked expected failures / skips
    until Stages B–D implement the router and executor.
"""

from __future__ import annotations

import unittest
from unittest import skip

from services.remivox.intents.models import (
    PROTECTED_ACTIONS,
    SUPPORTED_VOX_LANGUAGES,
    CreateReminderEntities,
    IntentResult,
    VoxIntent,
    VoxRecurrence,
)
from services.remivox.languages import (
    SUPPORTED_VOX_LANGUAGE_ORDER,
    normalize_language_code,
)
from services.remivox.response.builder import NO_DISCLAIMER_INTENTS, build_response
from services.remivox.state.conversation import (
    ConversationState,
    clear_state,
    get_state,
    save_state,
)


class RemiVoxV2ModelTests(unittest.TestCase):
    def test_create_reminder_example_contract(self):
        """Phase 2 example: Metoprolol at 8 PM every day."""
        entities = CreateReminderEntities(
            medication="Metoprolol",
            time="20:00",
            frequency=VoxRecurrence.DAILY,
        )
        result = IntentResult(
            intent=VoxIntent.CREATE_REMINDER,
            language="en",
            entities=entities.model_dump(mode="json"),
        )
        self.assertEqual(result.intent, VoxIntent.CREATE_REMINDER)
        self.assertEqual(result.language, "en")
        self.assertEqual(result.entities["medication"], "Metoprolol")
        self.assertEqual(result.entities["time"], "20:00")
        self.assertEqual(result.entities["frequency"], "daily")
        self.assertTrue(result.is_protected())

    def test_supported_languages_match_product_list(self):
        expected = {"en", "hi", "gu", "ta", "pa", "bn", "fr", "pt", "es", "de"}
        self.assertEqual(SUPPORTED_VOX_LANGUAGES, expected)
        self.assertEqual(set(SUPPORTED_VOX_LANGUAGE_ORDER), expected)
        self.assertEqual(normalize_language_code("HI-IN"), "hi")

    def test_protected_actions_exclude_hydra_care_writes(self):
        for intent in (
            VoxIntent.CREATE_REMINDER,
            VoxIntent.UPDATE_REMINDER,
            VoxIntent.COMPLETE_REMINDER,
            VoxIntent.SNOOZE_REMINDER,
            VoxIntent.SKIP_REMINDER,
            VoxIntent.DELETE_REMINDER,
        ):
            self.assertIn(intent, PROTECTED_ACTIONS)

        for intent in (
            VoxIntent.CANCEL_ACTION,
            VoxIntent.CONFIRM_ACTION,
            VoxIntent.READ_TODAY_MEDICATIONS,
            VoxIntent.CAREGIVER_BRIEF,
            VoxIntent.HELP,
        ):
            self.assertNotIn(intent, PROTECTED_ACTIONS)

    def test_cancel_and_confirm_intents_exist(self):
        self.assertEqual(VoxIntent.CANCEL_ACTION.value, "CANCEL_ACTION")
        self.assertEqual(VoxIntent.CONFIRM_ACTION.value, "CONFIRM_ACTION")

    def test_routine_intents_have_no_disclaimer_flag(self):
        for intent in (
            VoxIntent.CREATE_REMINDER,
            VoxIntent.READ_TODAY_MEDICATIONS,
            VoxIntent.READ_APPOINTMENTS,
            VoxIntent.READ_DOCTOR_SUMMARY,
            VoxIntent.CAREGIVER_BRIEF,
        ):
            self.assertIn(intent, NO_DISCLAIMER_INTENTS)

        refusal = IntentResult(
            intent=VoxIntent.MEDICAL_ADVICE_REFUSAL,
            language="en",
            entities={},
        )
        built = build_response(intent_result=refusal, reply_language="en")
        self.assertTrue(built["include_disclaimer"])

    def test_conversation_state_roundtrip_in_memory(self):
        user_id = "user-stage-a"
        session_id = "session-1"
        clear_state(user_id, session_id)
        save_state(
            ConversationState(
                user_id=user_id,
                session_id=session_id,
                language="hi",
                pending_intent=VoxIntent.CREATE_REMINDER.value,
                pending_entities={"medication": "Vitamin D"},
            )
        )
        loaded = get_state(user_id, session_id)
        self.assertIsNotNone(loaded)
        assert loaded is not None
        self.assertEqual(loaded.language, "hi")
        self.assertEqual(loaded.pending_entities["medication"], "Vitamin D")
        clear_state(user_id, session_id)
        self.assertIsNone(get_state(user_id, session_id))


class RemiVoxV2Phase8SkeletonTests(unittest.TestCase):
    """
    Phase 8 acceptance cases — skeleton only until Intent Router ships.

    These tests document expected behavior. They are skipped in Stage A so CI
    stays green; production /ask uses remivox.pipeline.run_care_turn (Stage E).
    """

    @skip("Stage B/C: Intent Router + extractors not wired")
    def test_01_metoprolol_daily_8pm(self):
        """
        'Set Metoprolol reminder at 8 PM every day'
        → CREATE_REMINDER, Metoprolol, 20:00, daily
        """
        self.fail("Not implemented until Stage C")

    @skip("Stage B/E: Hindi STT + reply language")
    def test_02_hindi_morning_medicine_reminder(self):
        """
        'मुझे सुबह 7 बजे दवाई याद दिलाना'
        → CREATE_REMINDER, Hindi response language
        """
        self.fail("Not implemented until Stage B/E")

    @skip("Stage D: conversation state missing time")
    def test_03_vitamin_d_asks_only_for_time(self):
        """
        'Remind me about Vitamin D'
        → CLARIFY / ask only for missing time; pending medication=Vitamin D
        """
        self.fail("Not implemented until Stage D")

    @skip("Stage C: COMPLETE_REMINDER routing")
    def test_04_mark_metoprolol_taken(self):
        """
        'Mark my Metoprolol as taken'
        → COMPLETE_REMINDER
        """
        self.fail("Not implemented until Stage C")

    @skip("Stage C: READ_TODAY_MEDICATIONS routing")
    def test_05_read_medications_today(self):
        """
        'Read my medications today'
        → READ_TODAY_MEDICATIONS
        """
        self.fail("Not implemented until Stage C")


if __name__ == "__main__":
    unittest.main()

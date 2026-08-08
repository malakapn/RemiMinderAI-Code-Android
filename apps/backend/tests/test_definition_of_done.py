import unittest
from unittest.mock import AsyncMock, patch

from pipecat.frames.frames import TextFrame, TranscriptionFrame
from pipecat.processors.frame_processor import FrameDirection

from services.remivox.pipecat_processor import RemiVoxProcessor


class TestDefinitionOfDoneFlows(unittest.IsolatedAsyncioTestCase):
    """Verify the six product flows at the Pipecat processor boundary."""

    async def _run_flow(self, transcript: str, care_result: dict):
        processor = RemiVoxProcessor(
            firebase_uid="definition-of-done-user",
            timezone="UTC",
            session_id="definition-of-done-session",
        )
        pushed_frames = []

        async def capture_push(frame, direction=FrameDirection.DOWNSTREAM):
            pushed_frames.append((frame, direction))

        processor.push_frame = capture_push
        care_turn = AsyncMock(return_value=care_result)
        resolve_user = AsyncMock(return_value="internal-user-uuid")
        load_reminders = AsyncMock(
            return_value={"today": [], "upcoming": [], "past": []}
        )
        load_summaries = AsyncMock(return_value=[])

        # Mock database/action boundaries while retaining the real
        # TranscriptionFrame -> TextFrame processor flow and lookup wiring.
        with (
            patch(
                "services.remivox.pipecat_processor.run_care_turn",
                care_turn,
            ),
            patch(
                "services.remivox.pipecat_processor.get_user_uuid",
                resolve_user,
            ),
            patch(
                "services.remivox.pipecat_processor.list_patient_reminders",
                load_reminders,
            ),
            patch(
                "services.remivox.pipecat_processor.get_user_summaries",
                load_summaries,
            ),
        ):
            await processor.process_frame(
                TranscriptionFrame(
                    text=transcript,
                    user_id="speaker",
                    timestamp="2026-08-08T03:11:00Z",
                    finalized=True,
                ),
                FrameDirection.DOWNSTREAM,
            )

        resolve_user.assert_awaited_once_with("definition-of-done-user")
        load_reminders.assert_awaited_once_with("internal-user-uuid")
        load_summaries.assert_awaited_once_with(
            "internal-user-uuid",
            firebase_uid="definition-of-done-user",
        )
        care_turn.assert_awaited_once()
        kwargs = care_turn.await_args.kwargs
        self.assertEqual(transcript, kwargs["text"])
        self.assertEqual("internal-user-uuid", kwargs["user_uuid"])
        self.assertEqual("definition-of-done-session", kwargs["session_id"])
        self.assertEqual("UTC", kwargs["timezone_name"])

        self.assertEqual(1, len(pushed_frames))
        frame, direction = pushed_frames[0]
        self.assertIsInstance(frame, TextFrame)
        self.assertEqual(care_result["text"], frame.text)
        self.assertEqual(FrameDirection.DOWNSTREAM, direction)
        return care_result

    async def test_01_create_metoprolol_reminder(self):
        entities = {
            "medication": "Metoprolol",
            "title": "Metoprolol",
            "time": "08:00",
            "frequency": "daily",
        }
        result = await self._run_flow(
            "Remind me to take Metoprolol every morning at 8",
            {
                "text": "Done. I will remind you to take Metoprolol every day at 8 AM.",
                "intent": "CREATE_REMINDER",
                "action": "create_reminder",
                "action_payload": {
                    "intent": "CREATE_REMINDER",
                    "entities": entities,
                },
                "success": True,
            },
        )

        self.assertEqual("CREATE_REMINDER", result["intent"])
        self.assertEqual("Metoprolol", result["action_payload"]["entities"]["title"])
        self.assertEqual("08:00", result["action_payload"]["entities"]["time"])
        self.assertEqual("daily", result["action_payload"]["entities"]["frequency"])

    async def test_02_update_reminder_time(self):
        result = await self._run_flow(
            "Actually change that to 9",
            {
                "text": "Updated. I will remind you at 9 AM.",
                "intent": "UPDATE_REMINDER",
                "action": "update_reminder",
                "action_payload": {
                    "intent": "UPDATE_REMINDER",
                    "entities": {"time": "09:00"},
                },
                "success": True,
            },
        )

        self.assertEqual("UPDATE_REMINDER", result["intent"])
        self.assertEqual("09:00", result["action_payload"]["entities"]["time"])

    async def test_03_cancel_pending_action(self):
        result = await self._run_flow(
            "No, cancel that",
            {
                "text": "Okay, I canceled that.",
                "intent": "CANCEL_ACTION",
                "action": "cancel_action",
                "action_payload": {"intent": "CANCEL_ACTION"},
                "success": True,
            },
        )

        self.assertEqual("CANCEL_ACTION", result["intent"])

    async def test_04_read_today_medications(self):
        result = await self._run_flow(
            "What medicines do I have today",
            {
                "text": "Today you have Metoprolol at 8 AM.",
                "intent": "READ_TODAY_MEDICATIONS",
                "action": "read_today_medications",
                "action_payload": {
                    "intent": "READ_TODAY_MEDICATIONS",
                    "names": ["Metoprolol"],
                },
                "success": True,
            },
        )

        self.assertEqual("READ_TODAY_MEDICATIONS", result["intent"])

    async def test_05_lab_results_route_to_hydra(self):
        result = await self._run_flow(
            "Explain my lab results",
            {
                "text": "I can help explain your lab results conversationally.",
                "intent": "UNKNOWN",
                "action": "start_hydra",
                "action_payload": {"route": "hydra"},
                "success": True,
            },
        )

        self.assertEqual("start_hydra", result["action"])
        self.assertEqual("hydra", result["action_payload"]["route"])

    async def test_06_caregiver_brief(self):
        result = await self._run_flow(
            "Tell my daughter what happened at my appointment",
            {
                "text": "Here is a brief summary for your daughter.",
                "intent": "CAREGIVER_BRIEF",
                "action": "caregiver_brief",
                "action_payload": {"intent": "CAREGIVER_BRIEF"},
                "success": True,
            },
        )

        self.assertEqual("CAREGIVER_BRIEF", result["intent"])


if __name__ == "__main__":
    unittest.main()

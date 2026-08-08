import unittest
from unittest.mock import AsyncMock, patch

from pipecat.frames.frames import TextFrame, TranscriptionFrame
from pipecat.processors.frame_processor import FrameDirection

from services.remivox.pipecat_processor import RemiVoxProcessor


class TestRemiVoxProcessorCareIntegration(unittest.IsolatedAsyncioTestCase):
    """Processor frame-flow tests with run_care_turn mocked to avoid DB calls."""

    async def _process_transcript(self, transcript: str, *, care_result=None, care_error=None):
        processor = RemiVoxProcessor(
            firebase_uid="firebase-user-123",
            timezone="America/New_York",
            session_id="test-session",
        )
        pushed_frames = []

        async def capture_push(frame, direction=FrameDirection.DOWNSTREAM):
            pushed_frames.append((frame, direction))

        processor.push_frame = capture_push
        mock_care_turn = AsyncMock()
        if care_error is not None:
            mock_care_turn.side_effect = care_error
        else:
            mock_care_turn.return_value = care_result or {}

        resolve_user = AsyncMock(return_value="internal-user-uuid")
        reminder_context = {
            "today": [{"title": "Metoprolol"}],
            "upcoming": [],
            "past": [],
        }
        summary_context = [{"title": "Cardiology", "summary": "Stable"}]
        load_reminders = AsyncMock(return_value=reminder_context)
        load_summaries = AsyncMock(return_value=summary_context)
        with (
            patch(
                "services.remivox.pipecat_processor.run_care_turn",
                mock_care_turn,
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
                    timestamp="2026-08-07T21:51:00Z",
                    finalized=True,
                ),
                FrameDirection.DOWNSTREAM,
            )

        resolve_user.assert_awaited_once_with("firebase-user-123")
        load_reminders.assert_awaited_once_with("internal-user-uuid")
        load_summaries.assert_awaited_once_with(
            "internal-user-uuid",
            firebase_uid="firebase-user-123",
        )
        self.assertEqual(reminder_context, mock_care_turn.await_args.kwargs["reminders"])
        self.assertEqual(summary_context, mock_care_turn.await_args.kwargs["summaries"])
        return mock_care_turn, pushed_frames

    def _assert_text_frame(self, pushed_frames, expected_text: str):
        self.assertEqual(1, len(pushed_frames))
        frame, direction = pushed_frames[0]
        self.assertIsInstance(frame, TextFrame)
        self.assertEqual(expected_text, frame.text)
        self.assertEqual(FrameDirection.DOWNSTREAM, direction)

    async def test_create_reminder_text_frame(self):
        response_text = "Done - I set a daily Metoprolol reminder for 8 PM."
        mock_care_turn, pushed_frames = await self._process_transcript(
            "Set a reminder for Metoprolol at 8 PM every day",
            care_result={
                "text": response_text,
                "intent": "CREATE_REMINDER",
                "action": "create_reminder",
                "action_payload": {"intent": "CREATE_REMINDER"},
                "success": True,
            },
        )

        mock_care_turn.assert_awaited_once()
        kwargs = mock_care_turn.await_args.kwargs
        self.assertEqual(
            "Set a reminder for Metoprolol at 8 PM every day",
            kwargs["text"],
        )
        self.assertEqual("internal-user-uuid", kwargs["user_uuid"])
        self.assertEqual("America/New_York", kwargs["timezone_name"])
        self.assertEqual("test-session", kwargs["session_id"])
        self._assert_text_frame(pushed_frames, response_text)

    async def test_read_today_medications_text_frame(self):
        response_text = "Today you have Metoprolol at 8 PM and Vitamin D at 9 AM."
        mock_care_turn, pushed_frames = await self._process_transcript(
            "What medicines do I have today",
            care_result={
                "text": response_text,
                "intent": "READ_TODAY_MEDICATIONS",
                "action": "read_today_medications",
                "action_payload": {"intent": "READ_TODAY_MEDICATIONS"},
                "success": True,
            },
        )

        mock_care_turn.assert_awaited_once()
        self.assertEqual("What medicines do I have today", mock_care_turn.await_args.kwargs["text"])
        self._assert_text_frame(pushed_frames, response_text)

    async def test_cancel_action_text_frame(self):
        response_text = "Okay, I canceled that action."
        mock_care_turn, pushed_frames = await self._process_transcript(
            "Cancel that",
            care_result={
                "text": response_text,
                "intent": "CANCEL_ACTION",
                "action": "cancel_action",
                "action_payload": {"intent": "CANCEL_ACTION"},
                "success": True,
            },
        )

        mock_care_turn.assert_awaited_once()
        self.assertEqual("Cancel that", mock_care_turn.await_args.kwargs["text"])
        self._assert_text_frame(pushed_frames, response_text)

    async def test_user_uuid_is_cached_but_context_refreshes_each_turn(self):
        processor = RemiVoxProcessor(
            firebase_uid="firebase-user-123",
            session_id="test-session",
        )

        async def capture_push(frame, direction=FrameDirection.DOWNSTREAM):
            return None

        processor.push_frame = capture_push
        resolve_user = AsyncMock(return_value="internal-user-uuid")
        load_reminders = AsyncMock(
            return_value={"today": [], "upcoming": [], "past": []}
        )
        load_summaries = AsyncMock(return_value=[])
        care_turn = AsyncMock(return_value={"text": "Okay.", "intent": "HELP"})

        with (
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
            patch(
                "services.remivox.pipecat_processor.run_care_turn",
                care_turn,
            ),
        ):
            for text in ("First turn", "Second turn"):
                await processor.process_frame(
                    TranscriptionFrame(
                        text=text,
                        user_id="speaker",
                        timestamp="2026-08-08T03:27:00Z",
                        finalized=True,
                    ),
                    FrameDirection.DOWNSTREAM,
                )

        resolve_user.assert_awaited_once_with("firebase-user-123")
        self.assertEqual(2, load_reminders.await_count)
        self.assertEqual(2, load_summaries.await_count)
        self.assertEqual(2, care_turn.await_count)
        for call in care_turn.await_args_list:
            self.assertEqual("internal-user-uuid", call.kwargs["user_uuid"])

    async def test_gibberish_emits_fallback_text_frame(self):
        mock_care_turn, pushed_frames = await self._process_transcript(
            "zxqv blorf ???",
            care_error=RuntimeError("care engine could not classify transcript"),
        )

        mock_care_turn.assert_awaited_once()
        self._assert_text_frame(pushed_frames, RemiVoxProcessor.FALLBACK_RESPONSE)


if __name__ == "__main__":
    unittest.main()

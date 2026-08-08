from pipecat.frames.frames import TextFrame, TranscriptionFrame
from pipecat.processors.frame_processor import FrameProcessor

from services.remivox.observability import logging
from services.remivox.pipeline import run_care_turn


logger = logging.getLogger("remivox.observability")


class RemiVoxProcessor(FrameProcessor):
    """Bridge finalized Pipecat STT transcripts into the RemiVox care engine."""

    FALLBACK_RESPONSE = "Sorry, I didn't catch that. Could you try again?"

    def __init__(
        self,
        firebase_uid: str,
        timezone: str = "UTC",
        session_id: str | None = None,
        keywords: list[tuple[str, float]] | None = None,
    ):
        super().__init__()
        self.firebase_uid = firebase_uid
        self.timezone = timezone or "UTC"
        self.session_id = session_id
        self.keywords = list(keywords or [])

    async def process_frame(self, frame, direction):
        await super().process_frame(frame, direction)

        if not isinstance(frame, TranscriptionFrame):
            await self.push_frame(frame, direction)
            return

        if not getattr(frame, "finalized", True):
            await self.push_frame(frame, direction)
            return

        transcript = (frame.text or "").strip()
        if not transcript:
            return

        response_text = await self._run_care_turn(transcript, frame)
        await self.push_frame(TextFrame(response_text))

    async def _run_care_turn(self, transcript: str, frame: TranscriptionFrame) -> str:
        try:
            language = getattr(frame, "language", None)
            detected_language = getattr(language, "value", language) if language else None

            result = await run_care_turn(
                user_uuid=self.firebase_uid,
                text=transcript,
                language=detected_language or "en",
                detected_language=detected_language,
                reminders={"today": [], "upcoming": [], "past": []},
                summaries=[],
                timezone_name=self.timezone,
                session_id=self.session_id,
                transcript=transcript,
            )
            response_text = (result.get("text") or "").strip()
            return response_text or self.FALLBACK_RESPONSE
        except Exception:
            logger.exception(
                "remivox_pipecat_processor_error",
                extra={"user_id": self.firebase_uid, "session_id": self.session_id},
            )
            return self.FALLBACK_RESPONSE

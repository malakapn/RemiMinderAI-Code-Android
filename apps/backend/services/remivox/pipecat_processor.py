import json
import time
from datetime import datetime, timezone

from pipecat.frames.frames import TextFrame, TranscriptionFrame
from pipecat.processors.frame_processor import FrameProcessor

from services.remivox.observability import logging
from services.remivox.pipeline import run_care_turn


logger = logging.getLogger("remivox.observability")


def _log_turn_event(event: str, **fields) -> None:
    logger.info(
        json.dumps(
            {
                "event": event,
                "severity": "INFO",
                "timestamp": datetime.now(timezone.utc).isoformat(),
                **fields,
            },
            separators=(",", ":"),
            sort_keys=True,
        )
    )


class RemiVoxProcessor(FrameProcessor):
    """Bridge finalized Pipecat STT transcripts into the RemiVox care engine."""

    FALLBACK_RESPONSE = "Sorry, I didn't catch that. Could you try again?"

    def __init__(
        self,
        firebase_uid: str,
        timezone: str = "UTC",
        session_id: str | None = None,
        keywords: list[tuple[str, float]] | None = None,
        session_stats: dict[str, int] | None = None,
    ):
        super().__init__()
        self.firebase_uid = firebase_uid
        self.timezone = timezone or "UTC"
        self.session_id = session_id
        self.keywords = list(keywords or [])
        self.session_stats = session_stats

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

        turn_started = time.perf_counter()
        frame_language = getattr(frame, "language", None)
        language = getattr(frame_language, "value", frame_language) or "en"
        _log_turn_event(
            "remivox_turn_transcript_received",
            text_length=len(transcript),
            language=str(language),
        )
        if self.session_stats is not None:
            self.session_stats["turns_count"] = (
                int(self.session_stats.get("turns_count", 0)) + 1
            )

        response_text, intent_type = await self._run_care_turn(
            transcript,
            detected_language=str(language),
        )
        _log_turn_event(
            "remivox_turn_intent_detected",
            intent_type=intent_type,
        )
        await self.push_frame(TextFrame(response_text))
        _log_turn_event(
            "remivox_turn_response_sent",
            response_length=len(response_text),
        )
        _log_turn_event(
            "remivox_turn_latency",
            stt_to_response_ms=round(
                (time.perf_counter() - turn_started) * 1000,
                2,
            ),
        )

    async def _run_care_turn(
        self,
        transcript: str,
        *,
        detected_language: str,
    ) -> tuple[str, str]:
        try:
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
            intent_type = str(result.get("intent") or "UNKNOWN")
            return response_text or self.FALLBACK_RESPONSE, intent_type
        except Exception as exc:
            logger.exception(
                json.dumps(
                    {
                        "event": "remivox_pipecat_processor_error",
                        "severity": "ERROR",
                        "timestamp": datetime.now(timezone.utc).isoformat(),
                        "error_type": type(exc).__name__,
                        "error_message": str(exc),
                        "session_id": self.session_id,
                    },
                    separators=(",", ":"),
                    sort_keys=True,
                )
            )
            return self.FALLBACK_RESPONSE, "ERROR"

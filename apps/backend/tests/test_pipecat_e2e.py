import asyncio
import io
import json
import os
import unittest
import urllib.parse
import wave
from unittest.mock import AsyncMock, patch

from fastapi import HTTPException

def _silence_wav(duration_seconds: float = 0.25, sample_rate: int = 16000) -> bytes:
    audio = b"\x00\x00" * int(duration_seconds * sample_rate)
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        wav.writeframes(audio)
    return buffer.getvalue()


def _has_auth_query(ws_url: str) -> bool:
    query = urllib.parse.parse_qs(urllib.parse.urlparse(ws_url).query)
    return bool(query.get("token"))


def _websocket_is_open(websocket) -> bool:
    closed = getattr(websocket, "closed", None)
    if closed is not None:
        return not closed
    state = getattr(websocket, "state", None)
    return getattr(state, "name", "") == "OPEN" or str(state).endswith("OPEN")


class TestPipecatE2E(unittest.IsolatedAsyncioTestCase):
    async def test_stream_auth_verifies_query_token(self):
        from route.remivox import _authenticate_remivox_stream

        class FakeWebSocket:
            async def receive_json(self):
                raise AssertionError("query token should not read an auth message")

        verify = {"sub": "verified-firebase-user"}
        enforce = AsyncMock()
        with (
            patch(
                "route.remivox.verify_firebase_token",
                return_value=verify,
            ) as verifier,
            patch("route.remivox.enforce_remivox_access", enforce),
        ):
            user_id, timezone, session_id = await _authenticate_remivox_stream(
                FakeWebSocket(),
                token="firebase-token",
                timezone_name="UTC",
                session_id="session-1",
            )

        verifier.assert_called_once_with("firebase-token")
        enforce.assert_awaited_once_with("verified-firebase-user")
        self.assertEqual("verified-firebase-user", user_id)
        self.assertEqual("UTC", timezone)
        self.assertEqual("session-1", session_id)

    async def test_stream_auth_verifies_first_message_token(self):
        from route.remivox import _authenticate_remivox_stream

        class FakeWebSocket:
            async def receive_json(self):
                return {
                    "type": "auth",
                    "token": "first-message-token",
                    "timezone": "America/New_York",
                    "session_id": "session-2",
                    "firebase_uid": "untrusted-user-id",
                }

        enforce = AsyncMock()
        with (
            patch(
                "route.remivox.verify_firebase_token",
                return_value={"sub": "verified-user-id"},
            ) as verifier,
            patch("route.remivox.enforce_remivox_access", enforce),
        ):
            user_id, timezone, session_id = await _authenticate_remivox_stream(
                FakeWebSocket(),
                token="",
                timezone_name="UTC",
                session_id=None,
            )

        verifier.assert_called_once_with("first-message-token")
        enforce.assert_awaited_once_with("verified-user-id")
        self.assertEqual("verified-user-id", user_id)
        self.assertEqual("America/New_York", timezone)
        self.assertEqual("session-2", session_id)

    async def test_stream_auth_rejects_invalid_token(self):
        from route.remivox import _authenticate_remivox_stream

        with patch(
            "route.remivox.verify_firebase_token",
            side_effect=HTTPException(status_code=401, detail="Invalid token"),
        ):
            with self.assertRaises(HTTPException):
                await _authenticate_remivox_stream(
                    object(),
                    token="invalid-token",
                    timezone_name="UTC",
                    session_id=None,
                )

    async def test_stream_endpoint_closes_invalid_token_with_1008(self):
        from route.remivox import remivox_stream

        class FakeWebSocket:
            def __init__(self):
                self.close_codes = []
                self.messages = []

            async def accept(self):
                return None

            async def send_json(self, message):
                self.messages.append(message)

            async def close(self, code=None):
                self.close_codes.append(code)

        websocket = FakeWebSocket()
        with (
            patch.dict(
                os.environ,
                {"SMALLESTAI_API_KEY": "test-key"},
                clear=False,
            ),
            patch("route.remivox.REMIVOX_PIPELINE", "pipecat"),
            patch(
                "route.remivox._authenticate_remivox_stream",
                side_effect=HTTPException(
                    status_code=401,
                    detail="Invalid token",
                ),
            ),
        ):
            await remivox_stream(
                websocket,
                token="invalid-token",
                timezone="UTC",
                session_id=None,
                language="en",
            )

        self.assertIn(1008, websocket.close_codes)
        self.assertEqual("Unauthorized", websocket.messages[-1]["error"]["message"])

    async def test_pipecat_stream_task_constructs(self):
        from pipecat.pipeline.runner import PipelineRunner
        from pipecat.pipeline.task import PipelineTask

        from route.remivox import _build_remivox_pipecat_task

        class DummyWebSocket:
            pass

        runner, task = _build_remivox_pipecat_task(
            DummyWebSocket(),
            api_key=os.getenv("SMALLESTAI_API_KEY") or "test-key",
            firebase_uid=os.getenv("REMIVOX_E2E_FIREBASE_UID") or "test-user",
            timezone_name=os.getenv("REMIVOX_E2E_TIMEZONE") or "UTC",
            session_id=os.getenv("REMIVOX_E2E_SESSION_ID") or "test-session",
        )
        self.assertIsInstance(runner, PipelineRunner)
        self.assertIsInstance(task, PipelineTask)
        await task.cancel(reason="pipecat e2e construction smoke test complete")

    @unittest.skipUnless(
        os.getenv("RUN_REMIVOX_PIPECAT_E2E") == "1",
        "Set RUN_REMIVOX_PIPECAT_E2E=1 to run against a live backend WebSocket.",
    )
    async def test_stream_endpoint_accepts_audio_and_stays_open(self):
        import websockets
        from websockets.exceptions import ConnectionClosed

        ws_url = os.getenv("REMIVOX_E2E_WS_URL") or "ws://127.0.0.1:8000/api/remivox/stream"
        stay_open_seconds = float(os.getenv("REMIVOX_E2E_STAY_OPEN_SECONDS") or "0.5")
        token = os.getenv("REMIVOX_E2E_TOKEN")
        if not _has_auth_query(ws_url) and not token:
            self.skipTest("Set REMIVOX_E2E_TOKEN for authenticated live WebSocket E2E.")

        async with websockets.connect(ws_url, open_timeout=5) as websocket:
            if not _has_auth_query(ws_url):
                auth_payload = {
                    "type": "auth",
                    "token": token,
                    "timezone": os.getenv("REMIVOX_E2E_TIMEZONE") or "UTC",
                    "session_id": os.getenv("REMIVOX_E2E_SESSION_ID") or "test-session",
                }
                await websocket.send(json.dumps(auth_payload))

            await websocket.send(_silence_wav())

            try:
                message = await asyncio.wait_for(websocket.recv(), timeout=stay_open_seconds)
            except asyncio.TimeoutError:
                self.assertTrue(_websocket_is_open(websocket))
            except ConnectionClosed as exc:
                self.fail(f"WebSocket closed during Pipecat stream smoke test: {exc}")
            else:
                self.assertTrue(
                    _websocket_is_open(websocket),
                    f"WebSocket closed after message: {message!r}",
                )


if __name__ == "__main__":
    unittest.main()

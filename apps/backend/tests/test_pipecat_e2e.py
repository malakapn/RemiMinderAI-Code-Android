import asyncio
import io
import json
import os
import unittest
import urllib.parse
import wave


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
    return bool(query.get("token") or query.get("firebase_uid"))


def _websocket_is_open(websocket) -> bool:
    closed = getattr(websocket, "closed", None)
    if closed is not None:
        return not closed
    state = getattr(websocket, "state", None)
    return getattr(state, "name", "") == "OPEN" or str(state).endswith("OPEN")


class TestPipecatE2E(unittest.IsolatedAsyncioTestCase):
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

        async with websockets.connect(ws_url, open_timeout=5) as websocket:
            if not _has_auth_query(ws_url):
                auth_payload = {
                    "firebase_uid": os.getenv("REMIVOX_E2E_FIREBASE_UID") or "test-user",
                    "timezone": os.getenv("REMIVOX_E2E_TIMEZONE") or "UTC",
                    "session_id": os.getenv("REMIVOX_E2E_SESSION_ID") or "test-session",
                }
                token = os.getenv("REMIVOX_E2E_TOKEN")
                if token:
                    auth_payload["token"] = token
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

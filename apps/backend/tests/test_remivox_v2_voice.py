"""
RemiVox v2 Voice Layer tests (Stage B).

Mocks SmallestAI HTTP calls — no live Pulse/Lightning required.
"""

from __future__ import annotations

import base64
import json
import os
import unittest
from unittest.mock import MagicMock, patch

from services.remivox.voice import (
    VoiceConfigError,
    VoiceSynthesisError,
    resolve_stt_language,
    synthesize_lightning,
    transcribe_pulse,
)


def _fake_response(
    *,
    status_code: int = 200,
    json_data=None,
    content: bytes = b"",
    text: str = "",
    headers=None,
):
    resp = MagicMock()
    resp.status_code = status_code
    resp.content = content
    resp.text = text or (json.dumps(json_data) if json_data is not None else "")
    resp.headers = headers or {"content-type": "audio/mp3"}
    if json_data is not None:
        resp.json.return_value = json_data
    else:
        resp.json.side_effect = ValueError("no json")
    return resp


class ResolveSttLanguageTests(unittest.TestCase):
    def test_auto_detect_uses_multi_not_en(self):
        self.assertEqual(
            resolve_stt_language(auto_detect_language=True, preferred_language="en"),
            "multi",
        )
        self.assertEqual(
            resolve_stt_language(auto_detect_language=True, preferred_language="hi"),
            "multi",
        )

    def test_explicit_preferred_when_auto_detect_off(self):
        self.assertEqual(
            resolve_stt_language(auto_detect_language=False, preferred_language="gu"),
            "gu",
        )


class PulseSttTests(unittest.TestCase):
    def setUp(self):
        self.audio_b64 = base64.b64encode(b"fake-wav-bytes").decode("ascii")

    @patch.dict(os.environ, {"SMALLESTAI_API_KEY": "test-key"}, clear=False)
    @patch("services.remivox.voice.requests.post")
    def test_english_stt_path(self, mock_post):
        mock_post.return_value = _fake_response(
            json_data={"text": "Set a reminder for Metoprolol", "language": "en"}
        )
        result = transcribe_pulse(self.audio_b64, language="en")
        self.assertEqual(result.transcript, "Set a reminder for Metoprolol")
        self.assertEqual(result.detected_language, "en")
        self.assertEqual(result.provider, "pulse")
        self.assertTrue(result.success)
        # First call URL should request language=en
        called_url = mock_post.call_args_list[0].args[0]
        self.assertIn("language=en", called_url)

    @patch.dict(os.environ, {"SMALLESTAI_API_KEY": "test-key"}, clear=False)
    @patch("services.remivox.voice.requests.post")
    def test_hindi_stt_detection_with_multi(self, mock_post):
        mock_post.return_value = _fake_response(
            json_data={
                "text": "मुझे रात 8 बजे मेटोप्रोलोल याद दिलाना",
                "language": "hi",
            }
        )
        result = transcribe_pulse(self.audio_b64, language="multi")
        self.assertIn("मेटोप्रोलोल", result.transcript)
        self.assertEqual(result.detected_language, "hi")
        self.assertEqual(result.requested_language, "multi")
        called_url = mock_post.call_args_list[0].args[0]
        self.assertIn("language=multi", called_url)

    @patch.dict(os.environ, {"SMALLESTAI_API_KEY": ""}, clear=False)
    def test_stt_missing_api_key(self):
        with self.assertRaises(VoiceConfigError):
            transcribe_pulse(self.audio_b64, language="multi")


class LightningTtsTests(unittest.TestCase):
    @patch.dict(os.environ, {"SMALLESTAI_API_KEY": "test-key"}, clear=False)
    @patch("services.remivox.voice.requests.post")
    def test_non_english_tts_selection_hindi(self, mock_post):
        mock_post.return_value = _fake_response(content=b"hindi-audio-bytes")
        result = synthesize_lightning("ठीक है", language="hi")
        self.assertTrue(result.success)
        self.assertEqual(result.language, "hi")
        self.assertEqual(result.language_used, "hi")
        self.assertEqual(result.fallback_status, "none")
        self.assertIsNotNone(result.audio_base64)
        payload = mock_post.call_args.kwargs["json"]
        self.assertEqual(payload["language"], "hi")
        # Non-English should hit lightning-v2 by default
        self.assertIn("lightning-v2", mock_post.call_args.args[0])

    @patch.dict(os.environ, {"SMALLESTAI_API_KEY": "test-key"}, clear=False)
    @patch("services.remivox.voice.requests.post")
    def test_bengali_and_gujarati_language_passed(self, mock_post):
        mock_post.return_value = _fake_response(content=b"audio")
        for lang in ("bn", "gu"):
            mock_post.reset_mock()
            result = synthesize_lightning("hello", language=lang)
            self.assertEqual(result.language_used, lang)
            self.assertEqual(mock_post.call_args.kwargs["json"]["language"], lang)

    @patch.dict(os.environ, {"SMALLESTAI_API_KEY": "test-key"}, clear=False)
    @patch("services.remivox.voice.requests.post")
    def test_english_fallback_when_locale_tts_fails(self, mock_post):
        fail = _fake_response(status_code=400, text="unsupported language")
        ok = _fake_response(content=b"en-audio")
        mock_post.side_effect = [fail, ok]

        result = synthesize_lightning("ठीक है", language="hi")
        self.assertTrue(result.success)
        self.assertEqual(result.language, "hi")
        self.assertEqual(result.language_used, "en")
        self.assertEqual(result.fallback_status, "english")
        self.assertEqual(mock_post.call_count, 2)
        self.assertEqual(mock_post.call_args_list[1].kwargs["json"]["language"], "en")

    @patch.dict(os.environ, {"SMALLESTAI_API_KEY": "test-key"}, clear=False)
    @patch("services.remivox.voice.requests.post")
    def test_tts_hard_failure_raises(self, mock_post):
        mock_post.return_value = _fake_response(status_code=500, text="boom")
        with self.assertRaises(VoiceSynthesisError):
            synthesize_lightning("hello", language="en")

    def test_tts_unavailable_without_api_key(self):
        with patch.dict(os.environ, {"SMALLESTAI_API_KEY": ""}, clear=False):
            result = synthesize_lightning("hello", language="es")
            self.assertFalse(result.success)
            self.assertEqual(result.status, "unavailable")
            self.assertEqual(result.fallback_status, "unavailable")
            self.assertIsNone(result.audio_base64)


class RouteCompatTests(unittest.TestCase):
    def test_auto_detect_no_longer_forces_english(self):
        """Regression: auto_detect_language=True must not force stt_lang='en'."""
        self.assertEqual(
            resolve_stt_language(auto_detect_language=True, preferred_language="hi"),
            "multi",
        )
        self.assertNotEqual(
            resolve_stt_language(auto_detect_language=True, preferred_language="hi"),
            "en",
        )


if __name__ == "__main__":
    unittest.main()

import importlib
import os
import unittest
from unittest.mock import patch

import services.remivox.config as remivox_config
from services.remivox.languages import (
    DEFAULT_REMIVOX_LANGUAGE,
    HINDI_REMIVOX_LANGUAGE,
    SUPPORTED_LANGUAGES,
)


class RemiVoxConfigTests(unittest.TestCase):
    def test_default_streaming_configuration(self):
        try:
            with patch.dict(os.environ, {}, clear=True):
                config = importlib.reload(remivox_config)
                self.assertEqual("meher", config.REMIVOX_TTS_VOICE)
                self.assertEqual(0.85, config.REMIVOX_TTS_SPEED)
                self.assertEqual(2000, config.REMIVOX_EOU_TIMEOUT_MS)
                self.assertEqual("lightning_v3.1", config.REMIVOX_TTS_MODEL)
                self.assertEqual(3.0, config.REMIVOX_KEYWORD_BOOST)
                self.assertEqual(30, config.REMIVOX_PING_INTERVAL_S)
                self.assertEqual(15, config.REMIVOX_SILENCE_TIMEOUT_S)
                self.assertEqual(300, config.REMIVOX_SESSION_MAX_S)
                self.assertEqual(16000, config.REMIVOX_INPUT_SAMPLE_RATE)
                self.assertEqual(24000, config.REMIVOX_OUTPUT_SAMPLE_RATE)
                self.assertEqual(200, config.REMIVOX_AUDIO_CHUNK_MS)
        finally:
            importlib.reload(remivox_config)

    def test_environment_overrides(self):
        overrides = {
            "REMIVOX_TTS_VOICE": "custom-voice",
            "REMIVOX_TTS_SPEED": "0.9",
            "REMIVOX_EOU_TIMEOUT_MS": "2500",
            "REMIVOX_TTS_MODEL": "custom-model",
            "REMIVOX_KEYWORD_BOOST": "4.5",
            "REMIVOX_PING_INTERVAL_S": "45",
            "REMIVOX_SILENCE_TIMEOUT_S": "20",
            "REMIVOX_SESSION_MAX_S": "420",
        }
        try:
            with patch.dict(os.environ, overrides, clear=False):
                config = importlib.reload(remivox_config)
                self.assertEqual("custom-voice", config.REMIVOX_TTS_VOICE)
                self.assertEqual(0.9, config.REMIVOX_TTS_SPEED)
                self.assertEqual(2500, config.REMIVOX_EOU_TIMEOUT_MS)
                self.assertEqual("custom-model", config.REMIVOX_TTS_MODEL)
                self.assertEqual(4.5, config.REMIVOX_KEYWORD_BOOST)
                self.assertEqual(45, config.REMIVOX_PING_INTERVAL_S)
                self.assertEqual(20, config.REMIVOX_SILENCE_TIMEOUT_S)
                self.assertEqual(420, config.REMIVOX_SESSION_MAX_S)
        finally:
            importlib.reload(remivox_config)

    def test_streaming_languages_are_canonical(self):
        self.assertEqual(
            {DEFAULT_REMIVOX_LANGUAGE, HINDI_REMIVOX_LANGUAGE},
            set(SUPPORTED_LANGUAGES),
        )


if __name__ == "__main__":
    unittest.main()

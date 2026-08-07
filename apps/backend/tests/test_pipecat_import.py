import unittest


class TestPipecatImport(unittest.TestCase):
    def test_smallest_stt_import(self):
        from pipecat.services.smallest.stt import SmallestSTTService

        self.assertIsNotNone(SmallestSTTService)

    def test_smallest_tts_import(self):
        from pipecat.services.smallest.tts import SmallestTTSService

        self.assertIsNotNone(SmallestTTSService)

    def test_silero_vad_import(self):
        from pipecat.audio.vad.silero import SileroVADAnalyzer

        self.assertIsNotNone(SileroVADAnalyzer)


if __name__ == "__main__":
    unittest.main()

"""
Simple synchronous Speech-to-Text pipeline for audio files.
Reads audio from Google Cloud Storage, processes with Google STT, returns transcript.
"""

import logging
import os
import tempfile
import subprocess
from typing import Dict, Any, List, Optional
from urllib.parse import urlparse

from google.cloud import speech

from services.gcs_service import get_backend_storage_client

logger = logging.getLogger(__name__)

# Language mapping for Google STT
LANGUAGE_MAP = {
    "en": "en-US",
    "es": "es-ES",
    "fr": "fr-FR",
    "de": "de-DE",
    "ar": "ar-SA",
    "hi": "hi-IN",
    "zh": "zh-CN"
}


def convert_input_to_stt_wav(input_path: str, output_path: str) -> None:
    """Decode/transcode arbitrary input audio to WAV (LINEAR16, 16 kHz mono) via ffmpeg."""
    command = [
        "ffmpeg",
        "-y",
        "-i",
        input_path,
        "-ac",
        "1",
        "-ar",
        "16000",
        "-acodec",
        "pcm_s16le",
        output_path,
    ]
    subprocess.run(
        command,
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def _blob_name_from_stored_audio_url(audio_url: str, bucket_name: str) -> Optional[str]:
    """Extract object path (e.g. audio/<visit>.m4a) from a GCS HTTPS URL."""
    if not audio_url or not bucket_name:
        return None
    try:
        base = audio_url.split("?", 1)[0].strip()
        path = urlparse(base).path.strip("/")
        if not path:
            return None
        first, _, rest = path.partition("/")
        if first == bucket_name and rest:
            return rest
    except Exception:
        return None
    return None


def _resolve_existing_audio_blob_name(
    bucket, bucket_name: str, visit_id: str, audio_url: Optional[str]
) -> str:
    """Find the uploaded object — prefer parsing DB URL over hard-coded .m4a path."""
    if audio_url:
        hinted = _blob_name_from_stored_audio_url(audio_url, bucket_name)
        if hinted:
            cand = bucket.blob(hinted)
            if cand.exists():
                logger.info("[STT] Resolved audio blob from DB URL hint: %s", hinted)

                return hinted
    for suffix in (".m4a", ".wav", ".aac", ".mp3", ".webm"):
        name = f"audio/{visit_id}{suffix}"
        cand = bucket.blob(name)

        if cand.exists():
            logger.info("[STT] Resolved audio blob by extension probe: %s", name)

            return name


    raise FileNotFoundError(
        f"No GCS audio object for visit_id={visit_id} under prefixes audio/{visit_id}.*"
    )


async def run_audio_stt_pipeline(visit_id: str, firebase_uid: str, language: str = "en") -> Dict[str, Any]:
    try:
        logger.info(f"🔍 [STT] Starting STT pipeline for visit {visit_id} with language='{language}'")

        # Step 1: Resolve user UUID
        from services.db_service import get_user_uuid, get_audio_gcs_url

        user_uuid = await get_user_uuid(firebase_uid)

        # Step 2: Validate audio exists in DB (guard)
        audio_url = await get_audio_gcs_url(visit_id, user_uuid)

        bucket_name = os.getenv("GCS_BUCKET_NAME")
        if not bucket_name:
            raise RuntimeError("GCS_BUCKET_NAME environment variable not set")

        logger.info("Starting STT for visit %s", visit_id)
        logger.debug("Audio URL (DB): %s", audio_url)

        # Step 3: Download audio, normalize to WAV, upload temp object for Speech API URI input
        storage_client = get_backend_storage_client()
        bucket = storage_client.bucket(bucket_name)

        audio_blob_name = _resolve_existing_audio_blob_name(
            bucket, bucket_name, visit_id, audio_url
        )

        _, source_ext = os.path.splitext(audio_blob_name)
        if not source_ext:
            source_ext = ".m4a"

        logger.info("Transcoding %s -> LINEAR16 WAV for STT", audio_blob_name)

        source_temp_path = None
        wav_temp_path = None
        stt_temp_blob_name = f"stt_temp/{visit_id}.wav"

        try:
            src_blob = bucket.blob(audio_blob_name)
            with tempfile.NamedTemporaryFile(
                suffix=source_ext, delete=False, dir="/tmp"
            ) as src_temp:
                src_blob.download_to_file(src_temp)

                source_temp_path = src_temp.name

            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False, dir="/tmp") as wav_temp:
                wav_temp_path = wav_temp.name

            convert_input_to_stt_wav(source_temp_path, wav_temp_path)

            stt_blob = bucket.blob(stt_temp_blob_name)

            stt_blob.upload_from_filename(wav_temp_path)

            logger.info("Uploaded converted WAV to GCS: %s", stt_temp_blob_name)

        except Exception as e:
            if source_temp_path and os.path.exists(source_temp_path):
                os.unlink(source_temp_path)
            if wav_temp_path and os.path.exists(wav_temp_path):
                os.unlink(wav_temp_path)

            try:
                temp_blob = bucket.blob(stt_temp_blob_name)
                if temp_blob.exists():
                    temp_blob.delete()

            except Exception:
                pass
            raise RuntimeError(f"Audio conversion/upload failed: {e}") from e
        finally:
            if source_temp_path and os.path.exists(source_temp_path):
                os.unlink(source_temp_path)
            if wav_temp_path and os.path.exists(wav_temp_path):
                os.unlink(wav_temp_path)

        # Step 4: Configure STT using GCS URI
        speech_client = speech.SpeechClient()
        gcs_wav_uri = f"gs://{bucket_name}/{stt_temp_blob_name}"

        audio_input = speech.RecognitionAudio(uri=gcs_wav_uri)

        language_code = LANGUAGE_MAP.get(language, "en-US")
        logger.info(
            "🔍 [STT] Language mapping: input=%r keys=%s result=%r",
            language,
            list(LANGUAGE_MAP.keys()),
            language_code,
        )
        logger.info(
            "🔍 [STT] Starting Google STT long_running_recognize for visit %s", visit_id
        )

        primary_config = speech.RecognitionConfig(
            encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
            language_code=language_code,
            enable_automatic_punctuation=True,
            use_enhanced=True,

            model="medical_conversation",
        )

        try:
            operation = speech_client.long_running_recognize(
                config=primary_config, audio=audio_input
            )


            response = operation.result(timeout=1800)


        except Exception as exc:


            logger.warning(
                "[STT] Primary model unavailable or rejected (%s); retrying latest_long",

                exc,
            )


            fallback_config = speech.RecognitionConfig(
                encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
                language_code=language_code,

                enable_automatic_punctuation=True,
                use_enhanced=False,
                model="latest_long",
            )
            operation = speech_client.long_running_recognize(
                config=fallback_config, audio=audio_input
            )

            response = operation.result(timeout=1800)


        # Clean up GCS temp file after successful processing
        try:
            temp_blob = bucket.blob(stt_temp_blob_name)
            if temp_blob.exists():
                temp_blob.delete()
                logger.info(f"Cleaned up GCS temp file: {stt_temp_blob_name}")
        except Exception as cleanup_error:
            logger.warning(f"Failed to clean up GCS temp file {stt_temp_blob_name}: {cleanup_error}")
            # Don't fail the whole process for cleanup issues

        logger.info("STT job completed")

        if not response.results:
            raise ValueError("No speech detected in audio file")

        # Step 6: Aggregate results
        transcript_parts: List[str] = []
        confidence_values: List[float] = []

        for result in response.results:
            if result.alternatives:
                alt = result.alternatives[0]
                transcript_parts.append(alt.transcript)
                confidence_values.append(alt.confidence)

        transcript = " ".join(transcript_parts)
        confidence = (
            sum(confidence_values) / len(confidence_values)
            if confidence_values
            else None
        )

        logger.info(
            f"🔍 [STT] STT completed for visit {visit_id}: "
            f"{len(transcript)} chars, avg confidence={confidence}"
        )
        logger.info(f"🔍 [STT] Sample transcript text: '{transcript[:200]}...'")

        return {
            "transcript": transcript,
            "confidence": confidence,
            "language": language_code,
        }

    except Exception:
        logger.exception(f"STT pipeline failed for visit {visit_id}")
        raise

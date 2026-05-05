"""
Google Vision API service for OCR processing.
Processes images from Google Cloud Storage.
"""

import base64
import json
import logging
import os
from google.cloud import vision
from google.oauth2 import service_account

logger = logging.getLogger(__name__)


def _get_vision_client() -> vision.ImageAnnotatorClient:
    """Build a Vision client using FIREBASE_SERVICE_ACCOUNT if ADC not available."""
    sa_b64 = os.getenv("FIREBASE_SERVICE_ACCOUNT", "").strip()
    if sa_b64:
        try:
            sa_info = json.loads(base64.b64decode(sa_b64).decode("utf-8"))
            creds = service_account.Credentials.from_service_account_info(
                sa_info,
                scopes=["https://www.googleapis.com/auth/cloud-platform"],
            )
            return vision.ImageAnnotatorClient(credentials=creds)
        except Exception as e:
            logger.warning("Failed to build Vision client from FIREBASE_SERVICE_ACCOUNT: %s", e)
    return vision.ImageAnnotatorClient()


async def extract_text_from_gcs_uri(gcs_uri: str) -> dict:
    """
    Perform OCR on an image stored in Google Cloud Storage using Google Vision API.

    Args:
        gcs_uri: GCS URI in format gs://bucket/path

    Returns:
        Dict containing:
        - text: Full extracted text
        - confidence: Overall confidence score
        - pages: Number of pages detected
        - language: Detected language code
    """
    try:
        # Initialize Vision client
        client = _get_vision_client()

        # Create image source from GCS URI
        image = vision.Image()
        image.source.image_uri = gcs_uri

        # Configure for document text detection
        features = [vision.Feature(type_=vision.Feature.Type.DOCUMENT_TEXT_DETECTION)]

        # Perform OCR
        response = client.annotate_image({'image': image, 'features': features})

        # Extract full text
        if response.full_text_annotation and response.full_text_annotation.text:
            full_text = response.full_text_annotation.text.strip()

            # Calculate average confidence from pages
            pages = response.full_text_annotation.pages
            confidence_scores = []

            for page in pages:
                if hasattr(page, 'confidence') and page.confidence > 0:
                    confidence_scores.append(page.confidence)

            avg_confidence = (
                sum(confidence_scores) / len(confidence_scores)
                if confidence_scores
                else None
            )

            # Detect language (use first page's language if available)
            detected_language = None
            if pages and pages[0].property.detected_languages:
                detected_language = pages[0].property.detected_languages[0].language_code

            logger.info(f"OCR completed: {len(full_text)} chars, {len(pages)} pages, confidence={avg_confidence}")

            return {
                "text": full_text,
                "confidence": avg_confidence,
                "pages": len(pages),
                "language": detected_language or "en"  # Default to English
            }
        else:
            raise ValueError("No text detected in image")

    except Exception as e:
        logger.error(f"OCR failed for {gcs_uri}: {str(e)}")
        raise

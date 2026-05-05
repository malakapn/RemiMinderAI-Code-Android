import base64
import json
import os
import traceback
import urllib.request
import uuid
import logging
from datetime import timedelta
from google.cloud import storage
from google.oauth2 import service_account
from fastapi import UploadFile

logger = logging.getLogger(__name__)


def _get_service_account_info() -> dict | None:
    """Decode FIREBASE_SERVICE_ACCOUNT env var into a dict, or None if unavailable."""
    sa_b64 = os.getenv("FIREBASE_SERVICE_ACCOUNT", "").strip()
    if not sa_b64:
        return None
    try:
        return json.loads(base64.b64decode(sa_b64).decode("utf-8"))
    except Exception as e:
        logger.warning("Failed to decode FIREBASE_SERVICE_ACCOUNT: %s", e)
        return None


def _get_storage_client() -> storage.Client:
    """Build a GCS client using FIREBASE_SERVICE_ACCOUNT if available, else ADC."""
    sa_info = _get_service_account_info()
    if sa_info:
        try:
            creds = service_account.Credentials.from_service_account_info(
                sa_info,
                scopes=[
                    "https://www.googleapis.com/auth/devstorage.full_control",
                    "https://www.googleapis.com/auth/cloud-platform",
                ],
            )
            return storage.Client(credentials=creds, project=sa_info.get("project_id"))
        except Exception as e:
            logger.warning("Failed to build GCS client from service account: %s", e)
    return storage.Client()


def get_backend_storage_client() -> storage.Client:
    """Same credential routing as uploads (Firebase SA JSON or ADC); use from workers/STT."""
    return _get_storage_client()


def _compute_metadata_default_sa_email() -> str | None:
    """Cloud Run/GCE runtime default service account email (IAM signBlob)."""
    try:
        req = urllib.request.Request(
            "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email",
            headers={"Metadata-Flavor": "Google"},
        )
        with urllib.request.urlopen(req, timeout=3) as resp:
            email = resp.read().decode("utf-8").strip()
            return email if email else None
    except Exception:
        return None


def _credential_signing_service_account_email(creds) -> str | None:
    """Resolve service account email for IAM v4 URLs when ADC omits `.service_account_email`."""
    for attr in ("service_account_email", "signer_email"):
        val = getattr(creds, attr, None)
        if isinstance(val, str) and ".gserviceaccount.com" in val:
            return val
    signer = getattr(creds, "_service_account_email", None)
    if isinstance(signer, str) and ".gserviceaccount.com" in signer:
        return signer
    return None


def _get_signing_credentials():
    """Return service_account.Credentials with signing scope, or None."""
    sa_info = _get_service_account_info()
    if not sa_info:
        return None
    try:
        return service_account.Credentials.from_service_account_info(
            sa_info,
            scopes=["https://www.googleapis.com/auth/cloud-platform"],
        )
    except Exception as e:
        logger.warning("Failed to build signing credentials: %s", e)
        return None


def _generate_signed_url(blob, expiration_hours: int = 24) -> str:
    """
    Generate a GCS signed URL that works both locally and on Cloud Run.

    - If FIREBASE_SERVICE_ACCOUNT is available: use its private key directly.
    - Otherwise (Cloud Run ADC): use the IAM Credentials API via access_token +
      service_account_email, which avoids needing a private key in the env.
    """
    expiration = timedelta(hours=expiration_hours)

    # Try explicit service account key first
    signing_creds = _get_signing_credentials()
    if signing_creds:
        try:
            return blob.generate_signed_url(
                version="v4",
                expiration=expiration,
                method="GET",
                credentials=signing_creds,
            )
        except Exception as e:
            logger.warning("Signed URL with SA key failed, trying IAM fallback: %s", e)

    # IAM Credentials API fallback — works on Cloud Run without a private key.
    # Requires the Cloud Run service account to have iam.serviceAccounts.signBlob.
    try:
        import google.auth
        from google.auth.transport.requests import Request as GoogleAuthRequest

        creds, _ = google.auth.default(
            scopes=["https://www.googleapis.com/auth/cloud-platform"]
        )
        creds.refresh(GoogleAuthRequest())
        sa_email = _credential_signing_service_account_email(creds)
        if not sa_email:
            sa_email = _compute_metadata_default_sa_email()
        access_token = getattr(creds, "token", None)
        if sa_email and access_token:
            return blob.generate_signed_url(
                version="v4",
                expiration=expiration,
                method="GET",
                service_account_email=sa_email,
                access_token=access_token,
            )
    except Exception as e:
        logger.warning("IAM signed URL fallback failed: %s", e)

    # Last resort: return the GCS public URI (won't be viewable without auth)
    return f"https://storage.googleapis.com/{blob.bucket.name}/{blob.name}"

async def upload_audio(file: UploadFile, visit_id: str) -> str:
    """
    Upload audio file to Google Cloud Storage with UBLA compatibility.
    Returns a signed URL for temporary access.

    Args:
        file: The uploaded audio file
        visit_id: Unique identifier for the visit

    Returns:
        str: Signed URL for accessing the uploaded audio file
    """
    try:
        # Get GCS configuration from environment
        bucket_name = os.getenv("GCS_BUCKET_NAME")
        if not bucket_name:
            raise ValueError("GCS_BUCKET_NAME environment variable not set")

        # HARDENING: Verify exact bucket name for HIPAA compliance
        if not bucket_name:
            raise RuntimeError("GCS_BUCKET_NAME is not configured")

        # Initialize GCS client
        storage_client = _get_storage_client()
        bucket = storage_client.bucket(bucket_name)

        # Create unique filename using visit_id
        file_extension = os.path.splitext(file.filename)[1] if file.filename else ".wav"
        blob_name = f"audio/{visit_id}{file_extension}"
        content_type = file.content_type or "audio/wav"

        # LOG: Pre-upload details
        logger.info(f"GCS_AUDIO_UPLOAD_START - visit_id={visit_id}, bucket={bucket_name}, blob={blob_name}, content_type={content_type}")

        # Create blob
        blob = bucket.blob(blob_name)

        # Upload file directly from the file object (UBLA-compatible)
        # Reset file pointer to beginning in case it was read before
        await file.seek(0)
        blob.upload_from_file(
            file.file,  # Use the underlying file object
            content_type=content_type
        )

        # HARDENING: Verify upload succeeded
        if not blob.exists():
            raise RuntimeError("GCS upload failed: blob does not exist after upload")

        signed_url = _generate_signed_url(blob)

        # LOG: Post-upload verification
        logger.info(f"GCS_AUDIO_UPLOAD_SUCCESS - visit_id={visit_id}, blob={blob_name}, size={blob.size}, signed_url_generated=True")

        return signed_url

    except Exception as e:
        # LOG: Upload failure
        logger.error(f"GCS_AUDIO_UPLOAD_FAILED - visit_id={visit_id}, error={str(e)}")

        # Log full traceback for debugging
        error_details = traceback.format_exc()
        print(f"GCS upload error for visit {visit_id}: {str(e)}")
        print(f"Full traceback: {error_details}")
        raise Exception(f"GCS upload failed: {str(e)}")


async def upload_image(file: UploadFile, visit_id: str) -> dict:
    """
    Upload image file to Google Cloud Storage with UBLA compatibility.
    Returns signed URL and metadata for temporary access.

    Args:
        file: The uploaded image file
        visit_id: Unique identifier for the visit

    Returns:
        dict: Contains signed URL, file path, and content type
    """
    try:
        # Get GCS configuration from environment
        bucket_name = os.getenv("GCS_BUCKET_NAME")
        if not bucket_name:
            raise ValueError("GCS_BUCKET_NAME environment variable not set")

        # HARDENING: Verify exact bucket name for HIPAA compliance
        if not bucket_name:
            raise RuntimeError("GCS_BUCKET_NAME is not configured")

        # Initialize GCS client
        storage_client = _get_storage_client()
        bucket = storage_client.bucket(bucket_name)

        # Generate unique filename within visit directory
        file_uuid = str(uuid.uuid4())
        file_extension = os.path.splitext(file.filename)[1] if file.filename else ".jpg"
        blob_name = f"images/{visit_id}/{file_uuid}{file_extension}"

        # Determine content type for images
        content_type = file.content_type
        if not content_type or not content_type.startswith('image/'):
            # Fallback to common image types based on extension
            if file_extension.lower() in ['.jpg', '.jpeg']:
                content_type = "image/jpeg"
            elif file_extension.lower() == '.png':
                content_type = "image/png"
            elif file_extension.lower() == '.heic':
                content_type = "image/heic"
            elif file_extension.lower() == '.webp':
                content_type = "image/webp"
            else:
                content_type = "image/jpeg"  # Default fallback

        # LOG: Pre-upload details
        logger.info(f"GCS_IMAGE_UPLOAD_START - visit_id={visit_id}, bucket={bucket_name}, blob={blob_name}, content_type={content_type}")

        # Create blob
        blob = bucket.blob(blob_name)

        # Upload file directly from the file object (UBLA-compatible)
        # Reset file pointer to beginning in case it was read before
        await file.seek(0)
        blob.upload_from_file(
            file.file,  # Use the underlying file object
            content_type=content_type
        )

        # HARDENING: Verify upload succeeded
        if not blob.exists():
            raise RuntimeError("GCS upload failed: blob does not exist after upload")

        signed_url = _generate_signed_url(blob)

        # LOG: Post-upload verification
        logger.info(f"GCS_IMAGE_UPLOAD_SUCCESS - visit_id={visit_id}, blob={blob_name}, size={blob.size}, signed_url_generated=True")

        return {
            "signed_url": signed_url,
            "blob_name": blob_name,
            "content_type": content_type,
            "file_size": blob.size
        }

    except Exception as e:
        # LOG: Upload failure
        logger.error(f"GCS_IMAGE_UPLOAD_FAILED - visit_id={visit_id}, error={str(e)}")

        # Log full traceback for debugging
        error_details = traceback.format_exc()
        print(f"GCS image upload error for visit {visit_id}: {str(e)}")
        print(f"Full traceback: {error_details}")
        raise Exception(f"GCS image upload failed: {str(e)}")

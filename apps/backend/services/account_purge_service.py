"""
Helpers to permanently purge a user's stored media from GCS.
"""

from __future__ import annotations

import logging
import os
import re
from typing import Iterable, Optional
from urllib.parse import unquote, urlparse

from services.gcs_service import get_backend_storage_client

logger = logging.getLogger(__name__)

_GCS_URI_RE = re.compile(r"^gs://([^/]+)/(.+)$")
_STORAGE_HOST_RE = re.compile(
    r"^https?://storage\.googleapis\.com/([^/]+)/(.+)$", re.IGNORECASE
)


def _blob_ref_from_url(url: Optional[str]) -> Optional[tuple[str, str]]:
    """Return (bucket, blob_name) parsed from a signed URL, https URI, or gs:// URI."""
    if not url or not str(url).strip():
        return None
    raw = str(url).strip()

    m = _GCS_URI_RE.match(raw)
    if m:
        return m.group(1), m.group(2)

    m = _STORAGE_HOST_RE.match(raw.split("?", 1)[0])
    if m:
        return m.group(1), unquote(m.group(2))

    try:
        parsed = urlparse(raw)
        # Signed URL style: https://bucket.storage.googleapis.com/object?...
        if parsed.netloc.endswith(".storage.googleapis.com"):
            bucket = parsed.netloc.split(".storage.googleapis.com", 1)[0]
            blob = unquote(parsed.path.lstrip("/"))
            if bucket and blob:
                return bucket, blob
    except Exception:
        return None

    return None


def delete_gcs_urls(urls: Iterable[Optional[str]]) -> int:
    """Best-effort delete of GCS objects referenced by URLs. Returns deleted count."""
    bucket_name_env = (os.getenv("GCS_BUCKET_NAME") or "").strip()
    deleted = 0
    seen: set[tuple[str, str]] = set()

    try:
        client = get_backend_storage_client()
    except Exception as e:
        logger.warning("GCS client unavailable for account purge: %s", e)
        return 0

    for url in urls:
        ref = _blob_ref_from_url(url)
        if not ref:
            continue
        bucket_name, blob_name = ref
        if bucket_name_env and bucket_name != bucket_name_env:
            # Prefer configured bucket for safety; still allow exact match from URL.
            pass
        key = (bucket_name, blob_name)
        if key in seen:
            continue
        seen.add(key)
        try:
            bucket = client.bucket(bucket_name)
            blob = bucket.blob(blob_name)
            if blob.exists():
                blob.delete()
                deleted += 1
                logger.info("Deleted GCS object gs://%s/%s", bucket_name, blob_name)
        except Exception as e:
            logger.warning(
                "Failed to delete GCS object gs://%s/%s: %s",
                bucket_name,
                blob_name,
                e,
            )

    return deleted


def delete_visit_media_prefixes(visit_ids: Iterable[str]) -> int:
    """Delete audio/{visit_id}* and images/{visit_id}/ prefixes from the app bucket."""
    bucket_name = (os.getenv("GCS_BUCKET_NAME") or "").strip()
    if not bucket_name:
        logger.warning("GCS_BUCKET_NAME not set; skipping prefix purge")
        return 0

    try:
        client = get_backend_storage_client()
        bucket = client.bucket(bucket_name)
    except Exception as e:
        logger.warning("GCS client unavailable for prefix purge: %s", e)
        return 0

    deleted = 0
    for visit_id in visit_ids:
        if not visit_id:
            continue
        prefixes = [f"audio/{visit_id}", f"images/{visit_id}/"]
        for prefix in prefixes:
            try:
                blobs = list(client.list_blobs(bucket_name, prefix=prefix))
                for blob in blobs:
                    try:
                        blob.delete()
                        deleted += 1
                    except Exception as e:
                        logger.warning("Failed deleting %s: %s", blob.name, e)
            except Exception as e:
                logger.warning("Failed listing prefix %s: %s", prefix, e)
    return deleted

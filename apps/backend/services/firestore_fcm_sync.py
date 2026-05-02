"""
Optional mirror of FCM registration token to Firestore (patient profile).

Enable with environment variable:
  FIRESTORE_FCM_SYNC=true

Requires Firebase Admin SDK initialization (same as FCM) and Firestore API
enabled on the Firebase project.
"""

import logging
import os
from datetime import datetime, timezone

logger = logging.getLogger(__name__)


def sync_patient_fcm_token(firebase_uid: str, fcm_token: str, device_type: str) -> None:
    """
    Best-effort write to Firestore. Does not raise — callers already persisted SQL.
    """
    if os.getenv("FIRESTORE_FCM_SYNC", "").strip().lower() not in ("1", "true", "yes"):
        return

    try:
        from services.fcm_service import init_fcm

        if not init_fcm():
            logger.warning("Firestore FCM sync skipped: FCM not initialized")
            return

        from firebase_admin import firestore

        db = firestore.client()
        doc_ref = db.collection("patients").document(firebase_uid)
        doc_ref.set(
            {
                "fcm_token": fcm_token,
                "fcm_device_type": device_type,
                "fcm_updated_at": datetime.now(timezone.utc).isoformat(),
            },
            merge=True,
        )
        logger.info("Firestore FCM sync ok for patient uid=%s", firebase_uid)
    except Exception as e:
        logger.warning("Firestore FCM sync failed (non-fatal): %s", e)

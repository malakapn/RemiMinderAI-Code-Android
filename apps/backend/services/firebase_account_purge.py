"""
Best-effort Firebase Auth + Firestore cleanup for account deletion.
"""

from __future__ import annotations

import logging
from typing import Iterable, Optional

logger = logging.getLogger(__name__)

# Subcollections used under users/{uid} by the Android/iOS clients.
_USER_SUBCOLLECTIONS = (
    "reminders",
    "visits",
    "scanned_docs",
    "connectedPatients",
    "careTeam",
)


def _ensure_firebase_app() -> bool:
    try:
        from services.fcm_service import init_fcm

        return bool(init_fcm())
    except Exception as e:
        logger.warning("Firebase app init failed during account purge: %s", e)
        return False


def delete_firestore_user_data(firebase_uid: str) -> None:
    """Delete users/{uid} doc + known subcollections, plus related consent/patient docs."""
    if not firebase_uid or not _ensure_firebase_app():
        return

    try:
        from firebase_admin import firestore

        db = firestore.client()
        user_ref = db.collection("users").document(firebase_uid)

        for sub in _USER_SUBCOLLECTIONS:
            _delete_collection(user_ref.collection(sub))

        # Consent session docs keyed by Firebase UID.
        consents_ref = db.collection("consents").document(firebase_uid)
        _delete_collection(consents_ref.collection("recording_sessions"))
        _delete_collection(consents_ref.collection("scan_sessions"))
        try:
            consents_ref.delete()
        except Exception:
            pass

        try:
            db.collection("patients").document(firebase_uid).delete()
        except Exception:
            pass

        # Invitations created by / for this user (best-effort query).
        try:
            for snap in (
                db.collection("invitations")
                .where("fromUserId", "==", firebase_uid)
                .stream()
            ):
                snap.reference.delete()
            for snap in (
                db.collection("invitations")
                .where("patientId", "==", firebase_uid)
                .stream()
            ):
                snap.reference.delete()
        except Exception as e:
            logger.warning("Invitation purge query failed for %s: %s", firebase_uid, e)

        user_ref.delete()
        logger.info("Deleted Firestore user data for uid=%s", firebase_uid)
    except Exception as e:
        logger.warning("Firestore user purge failed for %s: %s", firebase_uid, e)


def _delete_collection(col_ref, batch_size: int = 200) -> int:
    deleted = 0
    try:
        docs = list(col_ref.limit(batch_size).stream())
        while docs:
            for doc in docs:
                doc.reference.delete()
                deleted += 1
            docs = list(col_ref.limit(batch_size).stream())
    except Exception as e:
        logger.warning("Failed deleting collection %s: %s", getattr(col_ref, "id", col_ref), e)
    return deleted


def delete_firebase_auth_user(firebase_uid: str) -> bool:
    """Delete the Firebase Authentication user. Returns True on success."""
    if not firebase_uid or not _ensure_firebase_app():
        return False
    try:
        from firebase_admin import auth

        auth.delete_user(firebase_uid)
        logger.info("Deleted Firebase Auth user uid=%s", firebase_uid)
        return True
    except Exception as e:
        # User-not-found is fine (already deleted / client deleted first).
        logger.warning("Firebase Auth delete for %s: %s", firebase_uid, e)
        return False


def delete_caregiver_links_for_user(firebase_uid: str, connected_patient_ids: Optional[Iterable[str]] = None) -> None:
    """Remove this user from other users' connectedPatients / careTeam mirrors."""
    if not firebase_uid or not _ensure_firebase_app():
        return
    try:
        from firebase_admin import firestore

        db = firestore.client()
        for patient_id in connected_patient_ids or []:
            if not patient_id:
                continue
            try:
                db.collection("users").document(patient_id).collection("careTeam").document(
                    firebase_uid
                ).delete()
            except Exception:
                pass
            try:
                db.collection("users").document(firebase_uid).collection(
                    "connectedPatients"
                ).document(patient_id).delete()
            except Exception:
                pass
    except Exception as e:
        logger.warning("Caregiver link purge failed for %s: %s", firebase_uid, e)

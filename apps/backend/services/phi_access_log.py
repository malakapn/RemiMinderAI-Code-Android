import logging
from typing import Optional

from sqlalchemy import text

from services.cloud_sql_engine import get_cloud_sql_engine

logger = logging.getLogger(__name__)


async def log_phi_access(
    actor_firebase_uid: str,
    patient_id: Optional[str],
    resource: str,
    route: Optional[str] = None,
    ip_address: Optional[str] = None,
) -> None:
    """Append-only PHI access log (caregiver reads patient-linked data)."""
    if not actor_firebase_uid:
        return
    try:
        engine = get_cloud_sql_engine()
        with engine.begin() as conn:
            conn.execute(
                text("""
                    INSERT INTO public.phi_access_log
                    (actor_firebase_uid, patient_id, resource, route, ip_address)
                    VALUES (:actor, :patient_id, :resource, :route, :ip)
                """),
                {
                    "actor": actor_firebase_uid,
                    "patient_id": patient_id,
                    "resource": resource,
                    "route": route,
                    "ip": ip_address,
                },
            )
    except Exception as e:
        logger.warning("phi_access_log insert failed: %s", e)

import logging
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import HTTPException
from sqlalchemy import text

from services.cloud_sql_engine import get_cloud_sql_engine
from services.cache_service import get, set, invalidate

logger = logging.getLogger(__name__)

PLAN_TRIAL = "TRIAL"
PLAN_FREE = "FREE"
PLAN_PREMIUM = "PREMIUM"
PLAN_EXPIRED = "EXPIRED"

TRIAL_DAYS = 14
TRIAL_SUMMARY_LIMIT = 3
FREE_SUMMARY_LIMIT = 2
TRIAL_REMIVOX_LIMIT = 2
FREE_CAREGIVER_LIMIT = 1
TRIAL_CAREGIVER_LIMIT = 1
PREMIUM_CAREGIVER_LIMIT = 5


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _normalize_plan(raw: Optional[str]) -> str:
    value = (raw or PLAN_TRIAL).strip().upper()
    return value if value in {PLAN_TRIAL, PLAN_FREE, PLAN_PREMIUM, PLAN_EXPIRED} else PLAN_FREE


def _serialize_status(row) -> dict:
    plan = _normalize_plan(row.plan)
    now = _utcnow()
    trial_end = row.trial_end_date
    if trial_end and trial_end.tzinfo is None:
        trial_end = trial_end.replace(tzinfo=timezone.utc)
    trial_active = plan == PLAN_TRIAL and trial_end is not None and trial_end > now
    days_remaining = 0
    if trial_active:
        days_remaining = max(0, (trial_end.date() - now.date()).days)
    return {
        "plan": plan,
        "trial_active": trial_active,
        "trial_start_date": row.trial_start_date.isoformat() if row.trial_start_date else None,
        "trial_end_date": trial_end.isoformat() if trial_end else None,
        "trial_days_remaining": days_remaining,
        "summary_count": int(row.summary_count or 0),
        "remivox_interaction_count": int(row.remivox_interaction_count or 0),
        "subscription_source": row.subscription_source,
        "revenuecat_entitlement_active": bool(row.revenuecat_entitlement_active),
    }


def _expire_trial_if_needed(conn, user_id: str, plan: str, trial_end) -> str:
    if plan != PLAN_TRIAL:
        return plan
    if trial_end is None:
        trial_start = _utcnow()
        trial_end = trial_start + timedelta(days=TRIAL_DAYS)
        conn.execute(
            text("""
                UPDATE users
                SET trial_start_date = COALESCE(trial_start_date, :trial_start),
                    trial_end_date = COALESCE(trial_end_date, :trial_end)
                WHERE id = CAST(:user_id AS uuid)
            """),
            {"user_id": user_id, "trial_start": trial_start, "trial_end": trial_end},
        )
        return PLAN_TRIAL
    if trial_end.tzinfo is None:
        trial_end = trial_end.replace(tzinfo=timezone.utc)
    if trial_end <= _utcnow():
        conn.execute(
            text("""
                UPDATE users
                SET plan = :plan,
                    subscription_updated_at = now()
                WHERE id = CAST(:user_id AS uuid)
            """),
            {"user_id": user_id, "plan": PLAN_FREE},
        )
        return PLAN_FREE
    return PLAN_TRIAL


def _fetch_user_subscription_row(conn, *, firebase_uid: Optional[str] = None, user_id: Optional[str] = None):
    if firebase_uid:
        result = conn.execute(
            text("""
                SELECT id, firebase_uid, plan, trial_start_date, trial_end_date, summary_count,
                       remivox_interaction_count, subscription_source,
                       revenuecat_entitlement_active
                FROM users
                WHERE firebase_uid = :firebase_uid
                LIMIT 1
            """),
            {"firebase_uid": firebase_uid},
        )
    else:
        result = conn.execute(
            text("""
                SELECT id, firebase_uid, plan, trial_start_date, trial_end_date, summary_count,
                       remivox_interaction_count, subscription_source,
                       revenuecat_entitlement_active
                FROM users
                WHERE id = CAST(:user_id AS uuid)
                LIMIT 1
            """),
            {"user_id": user_id},
        )
    return result.fetchone()


async def get_subscription_status(firebase_uid: str) -> dict:
    cache_key = f"subscription_status:{firebase_uid}"
    cached = get(cache_key)
    if cached is not None:
        return cached

    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        row = _fetch_user_subscription_row(conn, firebase_uid=firebase_uid)
        if not row:
            raise HTTPException(status_code=404, detail="User not found")
        plan = _expire_trial_if_needed(conn, str(row.id), _normalize_plan(row.plan), row.trial_end_date)
        if plan != _normalize_plan(row.plan):
            row = _fetch_user_subscription_row(conn, user_id=str(row.id))
        status = _serialize_status(row)
    set(cache_key, status, 60)
    return status


async def sync_revenuecat_status(
    firebase_uid: str,
    *,
    premium: bool,
    app_user_id: Optional[str],
    product_id: Optional[str],
    source: Optional[str],
) -> dict:
    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        row = _fetch_user_subscription_row(conn, firebase_uid=firebase_uid)
        if not row:
            raise HTTPException(status_code=404, detail="User not found")
        current_plan = _normalize_plan(row.plan)
        next_plan = PLAN_PREMIUM if premium else (PLAN_EXPIRED if current_plan == PLAN_PREMIUM else current_plan)
        if next_plan == PLAN_TRIAL:
            next_plan = _expire_trial_if_needed(conn, str(row.id), next_plan, row.trial_end_date)

        conn.execute(
            text("""
                UPDATE users
                SET plan = :plan,
                    revenuecat_app_user_id = COALESCE(:app_user_id, revenuecat_app_user_id),
                    revenuecat_entitlement_active = :premium,
                    subscription_source = COALESCE(:source, subscription_source),
                    subscription_updated_at = now()
                WHERE id = CAST(:user_id AS uuid)
            """),
            {
                "plan": next_plan,
                "app_user_id": app_user_id,
                "premium": premium,
                "source": source or ("play_store" if product_id else None),
                "user_id": str(row.id),
            },
        )
    invalidate(f"subscription_status:{firebase_uid}")
    invalidate(f"user_profile:{firebase_uid}")
    return await get_subscription_status(firebase_uid)


async def can_generate_summary(user_id: str) -> dict:
    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        row = _fetch_user_subscription_row(conn, user_id=user_id)
        if not row:
            raise HTTPException(status_code=404, detail="User not found")
        plan = _expire_trial_if_needed(conn, str(row.id), _normalize_plan(row.plan), row.trial_end_date)
        summary_count = int(row.summary_count or 0)
        allowed = (
            plan == PLAN_PREMIUM
            or (plan == PLAN_TRIAL and summary_count < TRIAL_SUMMARY_LIMIT)
            or (plan in {PLAN_FREE, PLAN_EXPIRED} and summary_count < FREE_SUMMARY_LIMIT)
        )
        limit = None if plan == PLAN_PREMIUM else (TRIAL_SUMMARY_LIMIT if plan == PLAN_TRIAL else FREE_SUMMARY_LIMIT)
        return {"allowed": allowed, "plan": plan, "summary_count": summary_count, "limit": limit}


async def enforce_summary_limit(user_id: str) -> None:
    status = await can_generate_summary(user_id)
    if status["allowed"]:
        return
    raise HTTPException(
        status_code=402,
        detail={
            "code": "premium_required",
            "feature": "summary_generation",
            "plan": status["plan"],
            "summary_count": status["summary_count"],
            "limit": status["limit"],
            "message": "Upgrade to RemiMinderAI Premium to generate more doctor visit summaries.",
        },
    )


async def increment_summary_count(user_id: str) -> None:
    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        row = _fetch_user_subscription_row(conn, user_id=user_id)
        if not row:
            return
        conn.execute(
            text("UPDATE users SET summary_count = summary_count + 1 WHERE id = CAST(:user_id AS uuid)"),
            {"user_id": user_id},
        )
        if row.firebase_uid:
            invalidate(f"subscription_status:{row.firebase_uid}")
            invalidate(f"user_profile:{row.firebase_uid}")


async def increment_remivox_interaction(firebase_uid: str) -> None:
    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        conn.execute(
            text("""
                UPDATE users
                SET remivox_interaction_count = remivox_interaction_count + 1
                WHERE firebase_uid = :firebase_uid
            """),
            {"firebase_uid": firebase_uid},
        )
    invalidate(f"subscription_status:{firebase_uid}")
    invalidate(f"user_profile:{firebase_uid}")


async def enforce_remivox_access(firebase_uid: str) -> dict:
    status = await get_subscription_status(firebase_uid)
    plan = status["plan"]
    allowed = plan == PLAN_PREMIUM or (
        plan == PLAN_TRIAL
        and status["trial_active"]
        and int(status["remivox_interaction_count"] or 0) < TRIAL_REMIVOX_LIMIT
    )
    if allowed:
        return status
    raise HTTPException(
        status_code=402,
        detail={
            "code": "premium_required",
            "feature": "remivox",
            "plan": plan,
            "limit": TRIAL_REMIVOX_LIMIT if plan == PLAN_TRIAL else 0,
            "message": "Upgrade to RemiMinderAI Premium to use Vox.",
        },
    )


async def enforce_caregiver_invite_limit(patient_id: str) -> None:
    engine = get_cloud_sql_engine()
    with engine.begin() as conn:
        row = _fetch_user_subscription_row(conn, user_id=patient_id)
        if not row:
            raise HTTPException(status_code=404, detail="User not found")
        plan = _expire_trial_if_needed(conn, str(row.id), _normalize_plan(row.plan), row.trial_end_date)
        count_row = conn.execute(
            text("""
                SELECT
                  (SELECT COUNT(*) FROM care_team_members
                   WHERE patient_id = CAST(:patient_id AS uuid)
                     AND status IN ('active', 'accepted')) +
                  (SELECT COUNT(*) FROM care_team_invitations
                   WHERE patient_id = CAST(:patient_id AS uuid)
                     AND status = 'pending') AS total
            """),
            {"patient_id": patient_id},
        ).fetchone()
        total = int(count_row.total or 0)
        limit = PREMIUM_CAREGIVER_LIMIT if plan == PLAN_PREMIUM else (
            TRIAL_CAREGIVER_LIMIT if plan == PLAN_TRIAL else FREE_CAREGIVER_LIMIT
        )
        if total < limit:
            return
    raise HTTPException(
        status_code=402,
        detail={
            "code": "premium_required",
            "feature": "caregiver_invite",
            "plan": plan,
            "caregiver_count": total,
            "limit": limit,
            "message": "Upgrade to RemiMinderAI Premium to add more caregivers.",
        },
    )

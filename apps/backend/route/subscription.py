import logging
from typing import Optional

from fastapi import APIRouter, Body, Depends
from pydantic import BaseModel

from services.auth_gateway import get_current_user_jwt as get_current_user
from services.subscription_service import (
    get_subscription_status,
    increment_remivox_interaction,
    sync_revenuecat_status,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/subscription", tags=["subscription"])


class SubscriptionSyncRequest(BaseModel):
    premium: bool
    app_user_id: Optional[str] = None
    product_id: Optional[str] = None
    source: Optional[str] = None


@router.get("/status")
async def subscription_status(current_user: dict = Depends(get_current_user)):
    firebase_uid = current_user.get("sub")
    return await get_subscription_status(firebase_uid)


@router.post("/sync")
async def subscription_sync(
    request: SubscriptionSyncRequest,
    current_user: dict = Depends(get_current_user),
):
    firebase_uid = current_user.get("sub")
    return await sync_revenuecat_status(
        firebase_uid,
        premium=request.premium,
        app_user_id=request.app_user_id,
        product_id=request.product_id,
        source=request.source,
    )


@router.post("/events")
async def subscription_event(
    body: dict = Body(...),
    current_user: dict = Depends(get_current_user),
):
    firebase_uid = current_user.get("sub")
    logger.info(
        "subscription_event firebase_uid=%s event=%s payload=%s",
        firebase_uid,
        body.get("event"),
        body,
    )
    if body.get("event") == "vox_interaction":
        await increment_remivox_interaction(firebase_uid)
    return {"status": "ok"}

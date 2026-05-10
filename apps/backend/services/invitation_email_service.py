import logging
import os
import threading
from typing import Any, Optional

logger = logging.getLogger(__name__)

_brevo_lock = threading.Lock()
_brevo_api_instance: Any = None

SENDER_EMAIL = os.getenv("BREVO_SENDER_EMAIL", "team@remiminderai.com")
SENDER_NAME = os.getenv("BREVO_SENDER_NAME", "RemiMinderAI")


def _resolve_public_api_base_url() -> str:
    """
    Base URL of this API as reachable from the public internet (email links).

    Ops often set MOBILE_API_BASE_URL or API_BASE_URL but omit BACKEND_URL;
    without a public base URL we cannot build /api/invitations/accept links.
    """
    keys = (
        "BACKEND_URL",
        "PUBLIC_BACKEND_URL",
        "API_PUBLIC_URL",
        "MOBILE_API_BASE_URL",
        "API_BASE_URL",
    )
    for key in keys:
        raw = os.getenv(key)
        if not raw or not str(raw).strip():
            continue
        base = str(raw).strip().rstrip("/")
        if base.endswith("/api"):
            base = base[:-4].rstrip("/")
        if base.startswith("http://") or base.startswith("https://"):
            logger.debug("invite email: using %s from env %s", base, key)
            return base
    return ""


def _get_brevo_api() -> Optional[Any]:
    """Lazy-init Brevo client; returns None if API key is not configured."""
    global _brevo_api_instance
    api_key = os.getenv("BREVO_API_KEY")
    if not api_key or not api_key.strip():
        return None
    with _brevo_lock:
        if _brevo_api_instance is None:
            import sib_api_v3_sdk

            configuration = sib_api_v3_sdk.Configuration()
            configuration.api_key["api-key"] = api_key
            _brevo_api_instance = sib_api_v3_sdk.TransactionalEmailsApi(
                sib_api_v3_sdk.ApiClient(configuration)
            )
    return _brevo_api_instance


def send_invite_email(
    to_email: str,
    invite_token: str,
    patient_name: Optional[str] = None,
) -> bool:
    """
    Send caregiver invitation email via Brevo.

    patient_name is shown in the subject/body when provided.

    Returns False if Brevo is not configured, no public API base URL can be
    resolved, or the provider returns an error.
    """
    display_name = (patient_name or "").strip() or "A patient"

    backend_url = _resolve_public_api_base_url()
    if not backend_url:
        logger.error(
            "invite email skipped: set one of BACKEND_URL, PUBLIC_BACKEND_URL, "
            "API_PUBLIC_URL, MOBILE_API_BASE_URL, or API_BASE_URL so invitation "
            "links can point to this API"
        )
        return False

    api = _get_brevo_api()
    if api is None:
        logger.error(
            "invite email skipped: BREVO_API_KEY is not set or empty"
        )
        return False

    # GET care_team.invitations_router /accept — expects query param `token`
    invite_link = f"{backend_url}/api/invitations/accept?token={invite_token}"

    plain_content = f"""Hi,

{display_name} has invited you to join their care team on RemiMinderAI.

Open this link on your phone or computer to continue. Then open the RemiMinderAI app (or create an account in the app), choose Caregiver, and sign in with this same email address ({to_email.strip()}) — you will be connected to your patient automatically after you sign in.

Invitation link:
{invite_link}

If you didn't expect this, you can safely ignore this email.
"""

    html_content = f"""<html>
        <body style="font-family: Arial, sans-serif; line-height:1.6;">
            <h2 style="color: #333;">Care team invitation</h2>
            <p><strong>{display_name}</strong> invited you to join their care team on <strong>RemiMinderAI</strong>.</p>
            <p>
            <a href="{invite_link}"
                style="
                display:inline-block;
                background-color:#1a4d4d;
                color:white;
                padding:12px 24px;
                text-decoration:none;
                border-radius:8px;
                font-weight:bold;
                ">
                Accept invitation
            </a>
            </p>
            <p style="font-size:0.95em; color:#444;">
            If the button does not work, copy and paste this link into your browser:<br/>
            <span style="word-break:break-all;">{invite_link}</span>
            </p>
            <p style="font-size:0.95em; color:#333;">
            <strong>Using the app:</strong> After you open the link, install or open <strong>RemiMinderAI</strong>,
            select <strong>Caregiver</strong>, and sign in with <strong>Google or email using this same address</strong>
            ({to_email.strip()}). Your account will link to your patient once you are signed in.
            </p>
            <hr style="border:none; border-top:1px solid #eee;" />
            <p style="font-size:0.9em; color:#555;">
            If you didn't expect this invitation, you can safely ignore this email.
            </p>
        </body>
        </html>
    """

    try:
        import sib_api_v3_sdk
        from sib_api_v3_sdk.rest import ApiException

        subject = f"{display_name[:80]} invited you to RemiMinderAI"
        send_smtp_email = sib_api_v3_sdk.SendSmtpEmail(
            sender={"name": SENDER_NAME, "email": SENDER_EMAIL},
            to=[{"email": to_email}],
            subject=subject,
            html_content=html_content,
            text_content=plain_content,
        )
        api.send_transac_email(send_smtp_email)
        logger.info("Care team invite email sent to %s", to_email)
        return True
    except ApiException as e:
        logger.error("Brevo ApiException sending invite to %s: %s", to_email, e)
        return False
    except Exception as e:
        logger.error("Failed sending invite email to %s: %s", to_email, e, exc_info=True)
        return False

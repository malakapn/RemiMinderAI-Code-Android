import logging
import os
import threading
from typing import Any, Optional

logger = logging.getLogger(__name__)

_brevo_lock = threading.Lock()
_brevo_api_instance: Any = None

SENDER_EMAIL = os.getenv("BREVO_SENDER_EMAIL", "team@remiminderai.com")
SENDER_NAME = os.getenv("BREVO_SENDER_NAME", "RemiMinderAI")


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

    patient_name is accepted for API compatibility; message body stays generic.

    Returns False if Brevo is not configured, BACKEND_URL is missing/invalid,
    or the provider returns an error.
    """
    _ = patient_name  # intentionally unused (privacy)

    backend_url = (os.getenv("BACKEND_URL") or "").strip().rstrip("/")
    if not backend_url:
        logger.error(
            "invite email skipped: BACKEND_URL is not set; cannot build invitation link"
        )
        return False

    api = _get_brevo_api()
    if api is None:
        logger.error(
            "invite email skipped: BREVO_API_KEY is not set or empty"
        )
        return False

    invite_link = f"{backend_url}/api/invitations/accept?token={invite_token}"

    plain_content = f"""Hi,

You have been invited to join as a caregiver on RemiMinderAI.

Click the link below to accept:
{invite_link}

If you didn't expect this, you can safely ignore this email.
"""

    html_content = f"""<html>
        <body style="font-family: Arial, sans-serif; line-height:1.6;">
            <h2 style="color: #333;">You're invited!</h2>
            <p>You have been invited to join as a caregiver on <strong>RemiMinderAI</strong>.</p>
            <p>
            <a href="{invite_link}"
                style="
                display:inline-block;
                background-color:#4CAF50;
                color:white;
                padding:10px 20px;
                text-decoration:none;
                border-radius:6px;
                font-weight:bold;
                ">
                Accept Invitation
            </a>
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

        send_smtp_email = sib_api_v3_sdk.SendSmtpEmail(
            sender={"name": SENDER_NAME, "email": SENDER_EMAIL},
            to=[{"email": to_email}],
            subject="Invite to join RemiMinderAI",
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

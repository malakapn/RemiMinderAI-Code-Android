import logging
import os
from html import escape
from urllib.parse import quote

import requests

logger = logging.getLogger(__name__)

BREVO_TRANSACTIONAL_URL = "https://api.brevo.com/v3/smtp/email"


def _build_invite_link(base_url: str, invite_token: str) -> str:
    """Append token query param; use ? or & depending on whether base URL already has a query string."""
    base = base_url.strip().rstrip("/")
    if not base:
        return ""
    separator = "&" if "?" in base else "?"
    return f"{base}{separator}token={quote(invite_token, safe='')}"


def _invite_html(patient_name: str, accept_url: str) -> str:
    safe_name = escape(patient_name, quote=True)
    safe_url = escape(accept_url, quote=True)
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Care team invitation</title>
</head>
<body style="margin:0;padding:0;background-color:#f5f0e8;font-family:Georgia,'Times New Roman',serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:#f5f0e8;padding:32px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" style="max-width:560px;background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.06);">
          <tr>
            <td style="padding:32px 40px 24px 40px;">
              <p style="margin:0 0 8px 0;font-size:13px;letter-spacing:0.12em;text-transform:uppercase;color:#1a4d4d;font-family:system-ui,-apple-system,sans-serif;">
                RemiMinderAI
              </p>
              <h1 style="margin:0 0 20px 0;font-size:24px;line-height:1.25;color:#0d1f1f;font-weight:600;font-family:system-ui,-apple-system,sans-serif;">
                Care team invitation
              </h1>
              <p style="margin:0 0 16px 0;font-size:16px;line-height:1.6;color:#333333;font-family:system-ui,-apple-system,sans-serif;">
                <strong>{safe_name}</strong> has invited you to join their care team on <strong>RemiMinderAI</strong>—a healthcare companion that helps patients and caregivers stay on top of medications, visits, and daily care in one place.
              </p>
              <p style="margin:0 0 28px 0;font-size:16px;line-height:1.6;color:#333333;font-family:system-ui,-apple-system,sans-serif;">
                Accept this invitation to create your account (or sign in) and connect with their care circle. The link below is unique to you and should not be shared.
              </p>
              <table role="presentation" cellspacing="0" cellpadding="0" style="margin:0 0 28px 0;">
                <tr>
                  <td style="border-radius:8px;background-color:#1a4d4d;">
                    <a href="{safe_url}" target="_blank" rel="noopener noreferrer"
                       style="display:inline-block;padding:14px 32px;font-size:16px;font-weight:600;color:#ffffff;text-decoration:none;font-family:system-ui,-apple-system,sans-serif;">
                      Accept Invitation
                    </a>
                  </td>
                </tr>
              </table>
              <p style="margin:0;font-size:13px;line-height:1.5;color:#666666;font-family:system-ui,-apple-system,sans-serif;">
                If the button does not work, copy and paste this link into your browser:<br>
                <span style="word-break:break-all;color:#1a4d4d;">{safe_url}</span>
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:20px 40px 32px 40px;border-top:1px solid #eeeeee;">
              <p style="margin:0;font-size:12px;line-height:1.5;color:#999999;font-family:system-ui,-apple-system,sans-serif;">
                You received this email because someone entered your address as a caregiver on RemiMinderAI. If you were not expecting this, you can ignore this message.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
"""


def send_invite_email(to_email: str, invite_token: str, patient_name: str) -> bool:
    """
    Send a care team invite via Brevo transactional email.

    Requires BREVO_API_KEY, CARE_TEAM_INVITE_SIGNUP_URL, and BREVO_SENDER_EMAIL
    (a sender verified in Brevo).
    """
    api_key = (os.getenv("BREVO_API_KEY") or "").strip()
    base_url = (os.getenv("CARE_TEAM_INVITE_SIGNUP_URL") or "").strip()
    sender_email = (os.getenv("BREVO_SENDER_EMAIL") or "").strip()
    sender_name = (os.getenv("BREVO_SENDER_NAME") or "RemiMinderAI").strip()

    if not api_key:
        logger.error("BREVO_API_KEY is not set; cannot send care team invite email")
        return False
    if not base_url:
        logger.error(
            "CARE_TEAM_INVITE_SIGNUP_URL is not set; cannot send care team invite email"
        )
        return False
    if not sender_email:
        logger.error(
            "BREVO_SENDER_EMAIL is not set; cannot send care team invite email "
            "(use a sender identity verified in Brevo)"
        )
        return False

    accept_url = _build_invite_link(base_url, invite_token)
    if not accept_url:
        logger.error("CARE_TEAM_INVITE_SIGNUP_URL is empty after trim")
        return False

    safe_subject_name = " ".join((patient_name or "Someone").split())[:120]
    subject = f"{safe_subject_name} invited you to RemiMinderAI"
    html = _invite_html(patient_name, accept_url)
    text_body = (
        f"{patient_name} has invited you to join their care team on RemiMinderAI.\n\n"
        f"RemiMinderAI helps patients and caregivers stay on top of medications, visits, and daily care.\n\n"
        f"Accept your invitation here:\n{accept_url}\n\n"
        f"If you did not expect this email, you can ignore it."
    )

    payload = {
        "sender": {"name": sender_name, "email": sender_email},
        "to": [{"email": to_email.strip()}],
        "subject": subject,
        "htmlContent": html,
        "textContent": text_body,
    }

    try:
        response = requests.post(
            BREVO_TRANSACTIONAL_URL,
            json=payload,
            headers={
                "accept": "application/json",
                "content-type": "application/json",
                "api-key": api_key,
            },
            timeout=30,
        )
        if response.status_code not in (200, 201):
            logger.error(
                "Brevo invite email failed: status=%s body=%s",
                response.status_code,
                response.text[:500],
            )
            return False
        logger.info("Care team invite email sent via Brevo to %s", to_email)
        return True
    except requests.RequestException as e:
        logger.error("Brevo invite email request failed: %s", e)
        return False

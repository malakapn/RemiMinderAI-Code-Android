"""
RemiVox production configuration audit (Stage E).

Ensures REMIVOX_TEST_MODE cannot be accidentally left on in production.
"""

from __future__ import annotations

import logging
import os
from typing import Any

logger = logging.getLogger(__name__)


def _truthy(name: str, default: str = "false") -> bool:
    return os.getenv(name, default).strip().lower() in {"1", "true", "yes"}


def audit_remivox_production_config() -> dict[str, Any]:
    """
    Inspect RemiVox env flags and emit loud warnings when misconfigured.

    Safe to call on every API startup. Does not raise (warn-only).
    """
    app_env = (
        os.getenv("APP_ENV")
        or os.getenv("ENVIRONMENT")
        or os.getenv("ENV")
        or ""
    ).strip().lower()
    test_mode = _truthy("REMIVOX_TEST_MODE", "false")
    allow_in_prod = _truthy("REMIVOX_TEST_MODE_ALLOW_IN_PROD", "false")
    is_prod = app_env in {"prod", "production"}

    report = {
        "app_env": app_env or "(unset)",
        "remivox_test_mode": test_mode,
        "remivox_test_mode_allow_in_prod": allow_in_prod,
        "is_production": is_prod,
        "ok": True,
        "warnings": [],
    }

    if test_mode and is_prod and not allow_in_prod:
        msg = (
            "REMIVOX_TEST_MODE=true is set in production but will be IGNORED "
            "(REMIVOX_TEST_MODE_ALLOW_IN_PROD is not enabled). Set REMIVOX_TEST_MODE=false."
        )
        report["warnings"].append(msg)
        report["ok"] = False
        logger.error("RemiVox config audit: %s", msg)
    elif test_mode and is_prod and allow_in_prod:
        msg = (
            "DANGER: REMIVOX_TEST_MODE=true with REMIVOX_TEST_MODE_ALLOW_IN_PROD=true "
            "in production — trial/subscription bypass is ACTIVE. Disable for real users."
        )
        report["warnings"].append(msg)
        report["ok"] = False
        logger.error("RemiVox config audit: %s", msg)
    elif test_mode:
        msg = (
            "REMIVOX_TEST_MODE=true (non-production). Trial gate bypass may be active "
            "for allowlisted/all UIDs. Ensure this is intentional for QA only."
        )
        report["warnings"].append(msg)
        logger.warning("RemiVox config audit: %s", msg)
    elif allow_in_prod:
        msg = (
            "REMIVOX_TEST_MODE_ALLOW_IN_PROD=true while REMIVOX_TEST_MODE is off. "
            "Prefer leaving ALLOW_IN_PROD=false in production."
        )
        report["warnings"].append(msg)
        logger.warning("RemiVox config audit: %s", msg)
    else:
        logger.info(
            "RemiVox config audit OK: REMIVOX_TEST_MODE=false, "
            "REMIVOX_TEST_MODE_ALLOW_IN_PROD=false (env=%s)",
            report["app_env"],
        )

    return report

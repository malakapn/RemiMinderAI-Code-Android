"""
Stage D: REMIVOX_TEST_MODE and subscription enforcement hardening.
"""

from __future__ import annotations

import os
import unittest
from unittest.mock import AsyncMock, patch

from fastapi import HTTPException

from services.subscription_service import (
    enforce_remivox_access,
    remivox_test_mode_enabled,
)


class RemiVoxTestModeFlagTests(unittest.TestCase):
    def test_default_off(self):
        with patch.dict(os.environ, {"REMIVOX_TEST_MODE": "false", "APP_ENV": "development"}, clear=False):
            self.assertFalse(remivox_test_mode_enabled(firebase_uid="u1"))

    def test_empty_default_off(self):
        with patch.dict(os.environ, {"REMIVOX_TEST_MODE": ""}, clear=False):
            self.assertFalse(remivox_test_mode_enabled(firebase_uid="u1"))

    def test_enabled_in_non_prod(self):
        with patch.dict(
            os.environ,
            {
                "REMIVOX_TEST_MODE": "true",
                "APP_ENV": "development",
                "REMIVOX_TEST_MODE_ALLOW_IN_PROD": "false",
            },
            clear=False,
        ):
            os.environ.pop("REMIVOX_TEST_MODE_UIDS", None)
            self.assertTrue(remivox_test_mode_enabled(firebase_uid="tester-1"))

    def test_ignored_in_production_without_override(self):
        with patch.dict(
            os.environ,
            {
                "REMIVOX_TEST_MODE": "true",
                "APP_ENV": "production",
                "REMIVOX_TEST_MODE_ALLOW_IN_PROD": "false",
            },
            clear=False,
        ):
            self.assertFalse(remivox_test_mode_enabled(firebase_uid="tester-1"))

    def test_allowlist_restricts_uids(self):
        with patch.dict(
            os.environ,
            {
                "REMIVOX_TEST_MODE": "true",
                "APP_ENV": "staging",
                "REMIVOX_TEST_MODE_UIDS": "approved-1,approved-2",
            },
            clear=False,
        ):
            self.assertTrue(remivox_test_mode_enabled(firebase_uid="approved-1"))
            self.assertFalse(remivox_test_mode_enabled(firebase_uid="other-user"))


class RemiVoxAccessEnforcementTests(unittest.IsolatedAsyncioTestCase):
    async def test_production_config_enforces_trial_limits(self):
        status = {
            "plan": "FREE",
            "trial_active": False,
        }
        with patch.dict(
            os.environ,
            {"REMIVOX_TEST_MODE": "false", "APP_ENV": "production"},
            clear=False,
        ):
            with patch(
                "services.subscription_service.get_subscription_status",
                new=AsyncMock(return_value=status),
            ):
                with self.assertRaises(HTTPException) as ctx:
                    await enforce_remivox_access("uid-expired")
                self.assertEqual(ctx.exception.status_code, 402)

    async def test_test_mode_bypass_for_approved_tester(self):
        with patch.dict(
            os.environ,
            {
                "REMIVOX_TEST_MODE": "true",
                "APP_ENV": "development",
                "REMIVOX_TEST_MODE_UIDS": "approved-tester",
            },
            clear=False,
        ):
            with patch(
                "services.subscription_service.get_subscription_status",
                new=AsyncMock(return_value={"plan": "FREE", "trial_active": False}),
            ) as mock_status:
                out = await enforce_remivox_access("approved-tester")
                self.assertEqual(out["plan"], "PREMIUM")
                self.assertEqual(out["subscription_source"], "remivox_test_mode")
                mock_status.assert_not_awaited()

    async def test_test_mode_does_not_bypass_unapproved_uid(self):
        status = {
            "plan": "FREE",
            "trial_active": False,
        }
        with patch.dict(
            os.environ,
            {
                "REMIVOX_TEST_MODE": "true",
                "APP_ENV": "development",
                "REMIVOX_TEST_MODE_UIDS": "approved-tester",
            },
            clear=False,
        ):
            with patch(
                "services.subscription_service.get_subscription_status",
                new=AsyncMock(return_value=status),
            ):
                with self.assertRaises(HTTPException):
                    await enforce_remivox_access("random-user")


if __name__ == "__main__":
    unittest.main()

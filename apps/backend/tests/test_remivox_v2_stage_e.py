"""
Stage E: legacy retirement, route contract, Hydra safety, config audit.
"""

from __future__ import annotations

import ast
import os
import unittest
from pathlib import Path
from unittest.mock import AsyncMock, patch

from route.remivox import RemiVoxAskRequest
from services.remivox.config_audit import audit_remivox_production_config
from services.remivox.intents.models import PROTECTED_ACTIONS
from services.remivox_intents import execute_hydra_tool, hydra_tool_schemas


class ProductionRouteContractTests(unittest.TestCase):
    def test_ask_request_supports_existing_client_fields(self):
        req = RemiVoxAskRequest(
            audio_base64="AAAA",
            prompt="set a reminder",
            timezone="America/New_York",
            auto_detect_language=True,
            session_id="sess-1",
        )
        self.assertEqual(req.audio_base64, "AAAA")
        self.assertEqual(req.prompt, "set a reminder")
        self.assertEqual(req.timezone, "America/New_York")
        self.assertTrue(req.auto_detect_language)
        self.assertEqual(req.session_id, "sess-1")

    def test_ask_request_fields_optional_compat(self):
        req = RemiVoxAskRequest()
        self.assertIsNone(req.prompt)
        self.assertIsNone(req.audio_base64)
        self.assertTrue(req.auto_detect_language)
        self.assertEqual(req.timezone, "UTC")

    def test_route_module_does_not_call_handle_prompt(self):
        route_path = Path(__file__).resolve().parents[1] / "route" / "remivox.py"
        source = route_path.read_text(encoding="utf-8")
        tree = ast.parse(source)
        called_names: set[str] = set()
        for node in ast.walk(tree):
            if isinstance(node, ast.Call):
                func = node.func
                if isinstance(func, ast.Name):
                    called_names.add(func.id)
                elif isinstance(func, ast.Attribute):
                    called_names.add(func.attr)
        self.assertIn("run_care_turn", called_names)
        self.assertNotIn("handle_prompt", called_names)
        self.assertNotIn("handle_prompt", source)

    def test_route_imports_run_care_turn_not_legacy_handler(self):
        route_path = Path(__file__).resolve().parents[1] / "route" / "remivox.py"
        source = route_path.read_text(encoding="utf-8")
        self.assertIn("from services.remivox.pipeline import run_care_turn", source)
        self.assertNotIn("from services.remivox.legacy", source)
        self.assertNotIn("handle_prompt", source)


class HydraFinalSafetyTests(unittest.IsolatedAsyncioTestCase):
    def test_schemas_exclude_all_protected_mutations(self):
        names = {t["name"] for t in hydra_tool_schemas()}
        for forbidden in (
            "create_reminder",
            "update_reminder",
            "complete_reminder",
            "snooze_reminder",
            "skip_reminder",
            "delete_reminder",
        ):
            self.assertNotIn(forbidden, names)
        self.assertEqual(
            names,
            {"get_today_briefing", "get_caregiver_brief", "get_last_summary"},
        )

    async def test_execute_blocks_every_protected_action(self):
        for tool in (
            "create_reminder",
            "update_reminder",
            "complete_reminder",
            "snooze_reminder",
            "skip_reminder",
            "delete_reminder",
        ):
            with patch(
                "services.reminder_service.create_new_reminder",
                new=AsyncMock(),
            ) as create_mock:
                out = await execute_hydra_tool(
                    name=tool,
                    arguments={"title": "Metoprolol"},
                    user_uuid="u1",
                    reminders={"today": [], "upcoming": [], "past": []},
                    summaries=[],
                )
            self.assertIn("Intent Router", out)
            create_mock.assert_not_awaited()

    def test_protected_actions_constant_matches_product(self):
        expected = {
            "CREATE_REMINDER",
            "UPDATE_REMINDER",
            "COMPLETE_REMINDER",
            "SNOOZE_REMINDER",
            "SKIP_REMINDER",
            "DELETE_REMINDER",
        }
        self.assertEqual({i.value for i in PROTECTED_ACTIONS}, expected)


class ConfigAuditTests(unittest.TestCase):
    def test_production_clean_config_ok(self):
        with patch.dict(
            os.environ,
            {
                "APP_ENV": "production",
                "REMIVOX_TEST_MODE": "false",
                "REMIVOX_TEST_MODE_ALLOW_IN_PROD": "false",
            },
            clear=False,
        ):
            report = audit_remivox_production_config()
        self.assertTrue(report["ok"])
        self.assertFalse(report["remivox_test_mode"])
        self.assertFalse(report["remivox_test_mode_allow_in_prod"])

    def test_production_test_mode_without_allow_warns(self):
        with patch.dict(
            os.environ,
            {
                "APP_ENV": "production",
                "REMIVOX_TEST_MODE": "true",
                "REMIVOX_TEST_MODE_ALLOW_IN_PROD": "false",
            },
            clear=False,
        ):
            report = audit_remivox_production_config()
        self.assertFalse(report["ok"])
        self.assertTrue(any("IGNORED" in w for w in report["warnings"]))

    def test_production_allow_in_prod_danger_warns(self):
        with patch.dict(
            os.environ,
            {
                "APP_ENV": "production",
                "REMIVOX_TEST_MODE": "true",
                "REMIVOX_TEST_MODE_ALLOW_IN_PROD": "true",
            },
            clear=False,
        ):
            report = audit_remivox_production_config()
        self.assertFalse(report["ok"])
        self.assertTrue(any("DANGER" in w for w in report["warnings"]))


class LegacyRelocationTests(unittest.TestCase):
    def test_legacy_package_exports_handle_prompt(self):
        from services.remivox.legacy import handle_prompt

        self.assertTrue(callable(handle_prompt))

    def test_legacy_module_path_exists(self):
        root = Path(__file__).resolve().parents[1] / "services" / "remivox" / "legacy"
        self.assertTrue((root / "handle_prompt.py").is_file())
        self.assertTrue((root / "__init__.py").is_file())


class LegacyHandlePromptRegressionTests(unittest.IsolatedAsyncioTestCase):
    """Legacy path retained for rollback; not used by production routes."""

    async def test_create_reminder_still_works_in_legacy(self):
        from services.remivox.legacy import handle_prompt

        fake_created = {"id": "r1", "title": "Allegra"}
        with patch(
            "services.remivox.legacy.handle_prompt.create_new_reminder",
            new=AsyncMock(return_value=fake_created),
        ) as create_mock:
            result = await handle_prompt(
                prompt="set a reminder for Allegra every day at 8 pm",
                user_uuid="user-1",
                reminders={"today": [], "upcoming": [], "past": []},
                summaries=[],
                timezone_name="UTC",
                reply_language="en",
            )
        self.assertEqual(result["action"], "create_reminder")
        create_mock.assert_awaited()


if __name__ == "__main__":
    unittest.main()

"""
Stage D: RemiVox conversation state via cache_service.
"""

from __future__ import annotations

import unittest
from datetime import datetime, timedelta, timezone
from unittest.mock import patch

from services.cache_service import invalidate, set as cache_set
from services.remivox.state.conversation import (
    DEFAULT_STATE_TTL_SECONDS,
    ConversationState,
    clear_state,
    get_state,
    save_state,
    state_key,
    upsert_pending,
)


class RemiVoxStateCacheTests(unittest.TestCase):
    def setUp(self):
        clear_state("user-a", "session-1")
        clear_state("user-a", "session-2")
        clear_state("user-b", "session-1")

    def tearDown(self):
        clear_state("user-a", "session-1")
        clear_state("user-a", "session-2")
        clear_state("user-b", "session-1")

    def test_state_key_format(self):
        self.assertEqual(
            state_key("uid-1", "sid-9"),
            "remivox:state:uid-1:sid-9",
        )

    def test_roundtrip_via_cache_service(self):
        upsert_pending(
            user_id="user-a",
            session_id="session-1",
            language="hi",
            detected_language="hi",
            pending_intent="CREATE_REMINDER",
            pending_entities={"medication": "Vitamin D"},
            missing_slots=["time"],
        )
        loaded = get_state("user-a", "session-1")
        self.assertIsNotNone(loaded)
        assert loaded is not None
        self.assertEqual(loaded.pending_intent, "CREATE_REMINDER")
        self.assertEqual(loaded.detected_language, "hi")
        self.assertEqual(loaded.missing_slots, ["time"])
        self.assertEqual(loaded.pending_entities.get("medication"), "Vitamin D")

    def test_missing_session_returns_none(self):
        self.assertIsNone(get_state("user-a", "missing-session"))

    def test_expired_state_cleared(self):
        state = ConversationState(
            user_id="user-a",
            session_id="session-1",
            language="en",
            pending_intent="CREATE_REMINDER",
            pending_entities={"medication": "X"},
            updated_at=datetime.now(timezone.utc) - timedelta(minutes=10),
        )
        # Write directly with TTL still valid in cache, but state.updated_at expired.
        cache_set(state_key("user-a", "session-1"), state.to_cache_dict(), DEFAULT_STATE_TTL_SECONDS)
        self.assertIsNone(get_state("user-a", "session-1"))

    def test_concurrent_session_isolation(self):
        upsert_pending(
            user_id="user-a",
            session_id="session-1",
            language="en",
            detected_language="en",
            pending_intent="CREATE_REMINDER",
            pending_entities={"medication": "A"},
            missing_slots=["time"],
        )
        upsert_pending(
            user_id="user-a",
            session_id="session-2",
            language="es",
            detected_language="es",
            pending_intent="DELETE_REMINDER",
            pending_entities={"reminder_id": "r2"},
            missing_slots=["confirmation"],
        )
        s1 = get_state("user-a", "session-1")
        s2 = get_state("user-a", "session-2")
        self.assertIsNotNone(s1)
        self.assertIsNotNone(s2)
        assert s1 and s2
        self.assertEqual(s1.pending_intent, "CREATE_REMINDER")
        self.assertEqual(s2.pending_intent, "DELETE_REMINDER")
        self.assertEqual(s1.language, "en")
        self.assertEqual(s2.language, "es")

    def test_corrupt_cache_handled_gracefully(self):
        cache_set(state_key("user-a", "session-1"), "not-a-dict", 60)
        self.assertIsNone(get_state("user-a", "session-1"))

    def test_cache_get_failure_graceful(self):
        with patch(
            "services.remivox.state.conversation.cache_get",
            side_effect=RuntimeError("boom"),
        ):
            self.assertIsNone(get_state("user-a", "session-1"))


if __name__ == "__main__":
    unittest.main()

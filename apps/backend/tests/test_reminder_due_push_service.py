import unittest
from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch

from services.reminder_due_push_service import process_reminder_due_push_notifications


class ReminderDuePushServiceTests(unittest.IsolatedAsyncioTestCase):
    async def test_creates_caregiver_in_app_alert_for_due_reminder(self):
        due_row = {
            "id": "r-1",
            "user_id": "p-1",
            "title": "Take medication",
            "message": "Dose now",
            "scheduled_time": datetime.now(timezone.utc),
        }

        with patch("services.reminder_due_push_service.get_reminders_due_in_window", new=AsyncMock(return_value=[due_row])), \
            patch("services.reminder_due_push_service.try_claim_reminder_due_push", new=AsyncMock(return_value=True)), \
            patch("services.reminder_due_push_service.get_patient_fcm_token", new=AsyncMock(side_effect=["ptok", "cgtok"])), \
            patch("services.reminder_due_push_service.send_fcm_notification", new=AsyncMock(return_value=True)), \
            patch("services.reminder_due_push_service.list_patient_caregivers_for_alerts", new=AsyncMock(return_value=[{"caregiver_id": "cg-1", "email": "cg@example.com"}])), \
            patch("services.reminder_due_push_service.caregiver_alert_exists_for_context", new=AsyncMock(return_value=False)), \
            patch("services.reminder_due_push_service.create_caregiver_alert", new=AsyncMock(return_value={"id": "a1"})) as create_alert, \
            patch("services.reminder_due_push_service.get_patient_info", new=AsyncMock(return_value={"full_name": "Alex"})), \
            patch("services.reminder_due_push_service.send_caregiver_alert_email", new=AsyncMock()) as send_email:
            stats = await process_reminder_due_push_notifications()

        self.assertEqual(stats["reminders_examined"], 1)
        create_alert.assert_awaited_once()
        send_email.assert_awaited_once()


if __name__ == "__main__":
    unittest.main()

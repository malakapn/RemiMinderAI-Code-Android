import unittest
from unittest.mock import AsyncMock, patch

from services.alert_service import notify_caregivers_new_visit_recorded


class NotifyCaregiversNewVisitRecordedTests(unittest.IsolatedAsyncioTestCase):
    async def test_creates_alert_when_not_previously_sent(self):
        with patch("services.alert_service.get_patient_info", new=AsyncMock(return_value={"full_name": "Alex"})), \
            patch("services.alert_service.list_patient_caregivers_for_alerts", new=AsyncMock(return_value=[{"caregiver_id": "cg-1", "email": "cg@example.com"}])), \
            patch("services.alert_service.caregiver_alert_exists_for_context", new=AsyncMock(return_value=False)), \
            patch("services.alert_service.create_caregiver_alert", new=AsyncMock(return_value={"id": "a1"})) as create_alert, \
            patch("services.alert_service._push_fcm_to_caregiver", new=AsyncMock()) as push_alert, \
            patch("services.alert_service.send_caregiver_alert_email", new=AsyncMock()) as send_email:
            await notify_caregivers_new_visit_recorded(user_id="p-1", visit_id="v-1")

        create_alert.assert_awaited_once()
        push_alert.assert_awaited_once()
        send_email.assert_awaited_once()

    async def test_skips_when_context_already_sent(self):
        with patch("services.alert_service.get_patient_info", new=AsyncMock(return_value={"full_name": "Alex"})), \
            patch("services.alert_service.list_patient_caregivers_for_alerts", new=AsyncMock(return_value=[{"caregiver_id": "cg-1", "email": "cg@example.com"}])), \
            patch("services.alert_service.caregiver_alert_exists_for_context", new=AsyncMock(return_value=True)), \
            patch("services.alert_service.create_caregiver_alert", new=AsyncMock()) as create_alert, \
            patch("services.alert_service._push_fcm_to_caregiver", new=AsyncMock()) as push_alert, \
            patch("services.alert_service.send_caregiver_alert_email", new=AsyncMock()) as send_email:
            await notify_caregivers_new_visit_recorded(user_id="p-1", visit_id="v-1")

        create_alert.assert_not_called()
        push_alert.assert_not_called()
        send_email.assert_not_called()


if __name__ == "__main__":
    unittest.main()

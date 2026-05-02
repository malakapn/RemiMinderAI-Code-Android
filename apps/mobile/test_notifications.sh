#!/bin/bash
# Test push notifications
# Usage: ./test_notifications.sh <JWT_TOKEN> <FCM_TOKEN>

BASE_URL="http://localhost:8000"
JWT="${1:-YOUR_JWT_TOKEN}"
FCM="${2:-YOUR_FCM_TOKEN}"

echo "=== Testing Push Notifications ==="

# 1. Register FCM token
echo "1. Registering FCM token..."
curl -X POST "$BASE_URL/api/fcm/token" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d "{\"fcm_token\": \"$FCM\", \"device_type\": \"android\"}"
echo ""

# 2. Create a test reminder
echo "2. Creating test reminder..."
REMINDER=$(curl -s -X POST "$BASE_URL/api/reminders" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "reminder_type": "medication",
    "title": "Test Medication",
    "scheduled_time": "2026-04-22T18:00:00",
    "timezone": "America/New_York",
    "recurrence": "once"
  }')
echo "$REMINDER"

# Extract reminder ID
REMINDER_ID=$(echo "$REMINDER" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "Reminder ID: $REMINDER_ID"

# 3. Send push notification for the reminder
echo "3. Sending FCM push notification..."
curl -X POST "$BASE_URL/api/reminders/$REMINDER_ID/notify" \
  -H "Authorization: Bearer $JWT"
echo ""

echo "=== Done ==="
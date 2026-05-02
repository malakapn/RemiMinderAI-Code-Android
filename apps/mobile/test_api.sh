#!/bin/bash
# Test script for PatientApiService endpoints
# Usage: ./test_api.sh <JWT_TOKEN>

BASE_URL="http://10.0.2.2:8001"
TOKEN="${1:-YOUR_JWT_TOKEN_HERE}"

echo "=== Testing Patient API Endpoints ==="
echo ""

# Test headers
H="-H 'Authorization: Bearer $TOKEN' -H 'Content-Type: application/json'"

# Medications
echo "1. Get Medications..."
eval curl -s $H "$BASE_URL/api/patient/medications"
echo ""

# Reminders
echo "2. Get Reminders..."
eval curl -s $H "$BASE_URL/api/reminders"
echo ""

# Appointments
echo "3. Get Appointments..."
eval curl -s $H "$BASE_URL/api/patient/appointments"
echo ""

# Visits
echo "4. Get Visits..."
eval curl -s $H "$BASE_URL/api/visits"
echo ""

# Visit Summaries
echo "5. Get Summaries..."
eval curl -s $H "$BASE_URL/api/summaries"
echo ""

# Caregivers
echo "6. Get Caregivers..."
eval curl -s $H "$BASE_URL/api/patient/caregivers"
echo ""

# Language Preferences
echo "7. Get Language Preferences..."
eval curl -s $H "$BASE_URL/api/users/language-preferences"
echo ""

echo "=== Done ==="
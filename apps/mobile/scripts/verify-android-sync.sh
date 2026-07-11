#!/usr/bin/env bash
# Run on your Mac from the repo root to confirm you have the latest Android UI fixes.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MOBILE_DIR="$REPO_ROOT/apps/mobile"

echo "== RemiMinder Android build verification =="
echo "Repo: $REPO_ROOT"
echo

cd "$REPO_ROOT"
echo "-- Git remote --"
git remote -v | head -2
echo

echo "-- Latest commits on main --"
git fetch origin main 2>/dev/null || true
git log --oneline -5 origin/main 2>/dev/null || git log --oneline -5
echo

EXPECTED_COMMIT="ae63d80"
if git merge-base --is-ancestor "$EXPECTED_COMMIT" HEAD 2>/dev/null; then
  echo "OK: This checkout includes caregiver UX commit $EXPECTED_COMMIT"
else
  echo "MISSING: Run: git pull origin main"
  echo "       Expected ancestor commit: $EXPECTED_COMMIT"
fi
echo

echo "-- Key file markers (should all match) --"
check_marker() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -q "$pattern" "$MOBILE_DIR/$file" 2>/dev/null; then
    echo "OK  $label"
  else
    echo "FAIL $label ($file)"
  fi
}

check_marker "lib/core/config/app_build_info.dart" "1.3.2" "Build label v1.3.2"
check_marker "lib/features/caregiver/presentation/screens/caregiver_home_screen.dart" "_buildHeader" "Caregiver gradient header"
check_marker "lib/features/caregiver/presentation/screens/alert_list_screen.dart" "RemiShellUi.screenHeader" "Caregiver alerts RemiShellUi"
check_marker "lib/features/auth/presentation/screens/role_selection_screen.dart" "crossAxisAlignment: CrossAxisAlignment.start" "Role card column layout"
check_marker "lib/features/patient/presentation/screens/language_settings_screen.dart" "languagesAvailableCount" "10-language header"
echo

echo "-- Flutter / device --"
if command -v flutter >/dev/null 2>&1; then
  (cd "$MOBILE_DIR" && flutter --version | head -1)
else
  echo "WARN: flutter not in PATH"
fi

if command -v adb >/dev/null 2>&1; then
  echo "ADB devices:"
  adb devices -l
else
  echo "WARN: adb not in PATH — add Android SDK platform-tools"
fi
echo

echo "If markers pass, rebuild on Samsung:"
echo "  cd $MOBILE_DIR"
echo "  flutter clean && flutter pub get"
echo "  flutter run -d RFGYC218FBD"
echo
echo "On device: Profile tab should show footer: RemiMinder v1.3.2 (build 62) · ae63d80"

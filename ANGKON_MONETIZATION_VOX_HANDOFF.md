# Monetization, Vox, and Summary Pipeline Handoff for Angkon

Production traffic was routed back to the July 7 stable revision after summary generation regressions were observed. This document captures the changes that were added on `main`, what they were intended to do, what broke, and how to rework safely.

Do not include live API keys, database passwords, or service account values in this document.

## Recent commits after the stable pre-monetization point

```text
f6eb3a9 Migrate brand colors to navy palette
590ad97 Add floating Vox button to patient shell
1281d94 Add RevenueCat premium monetization framework
8354346 Fix RevenueCat purchase API compile errors
8be7292 Match account usage summary wording
f340bae Implement RemiVox daily briefing
313c8a9 Add premium test allowlist
ee981f2 Fix premium screen navigation
3e7a7d1 Let backend gate Vox access
abdf661 Make Vox respond in place
eed1eef Use summaries list for account usage count
9c314eb Fix Vox button widget syntax
91a65d0 Improve Vox error and auth sync timing
9da48be Make summary limit enforcement opt in
ed987fa Restore scheduled STT job endpoint
4a14d3a Fix visit metadata lookup for legacy ownership
1822aaa Fix summary lookup for Firebase UID rows
```

## 1. Navy brand color migration

### Purpose

Replace teal/green brand colors with the navy design system.

### Main files changed

```text
apps/mobile/lib/core/config/theme.dart
apps/mobile/lib/core/widgets/remi_shell_ui.dart
apps/mobile/lib/features/auth/presentation/screens/login_screen.dart
apps/mobile/lib/features/auth/presentation/screens/forgot_password_screen.dart
apps/mobile/lib/features/auth/presentation/screens/role_selection_screen.dart
apps/mobile/lib/features/patient/presentation/screens/patient_home_screen.dart
apps/mobile/lib/features/caregiver/presentation/screens/caregiver_home_screen.dart
apps/mobile/lib/features/shared/widgets/custom_time_picker_sheet.dart
apps/mobile/lib/features/shared/presentation/screens/loading_screen.dart
apps/mobile/lib/shared/widgets/loading_shimmer.dart
```

### New design colors

```text
Navy Primary: #1A3A5C
Navy Mid:     #2A5478
Navy Light:   #4A7FB5
Navy Tint:    #E6F0FA
Bottle Green: #2D6A4F
Charcoal:     #2D2D2D
Gold:         #C9A84C
Cream:        #F8F4E8
```

### Risk

Low. Mostly visual.

### Recommendation

Keep this change, but re-run visual QA on Android and iOS.

## 2. Floating Vox button

### Purpose

Add a floating Vox button near the bottom nav.

### Main file

```text
apps/mobile/lib/features/patient/presentation/widgets/patient_app_shell.dart
```

### Behavior added

The button displays:

```text
Vox
Today's
Visit
```

It was later changed from opening a Vox screen to a Siri-style in-place interaction.

### Risk

Medium.

The current implementation puts speech recognition, backend calls, audio playback, and loading state inside `PatientAppShell`. This is too much logic for the shell.

### Recommendation

Move Vox logic into a dedicated feature module:

```text
apps/mobile/lib/features/vox/application/vox_controller.dart
apps/mobile/lib/features/vox/data/vox_api_service.dart
apps/mobile/lib/features/vox/widgets/vox_floating_button.dart
```

Keep `PatientAppShell` layout-only.

## 3. RevenueCat monetization framework

### Purpose

Add Free Trial, Free Tier, Premium subscriptions, and RevenueCat entitlement checks.

### Dependencies added

```yaml
purchases_flutter
firebase_analytics
```

### New mobile files

```text
apps/mobile/lib/core/models/monetization_status.dart
apps/mobile/lib/core/services/revenuecat_service.dart
apps/mobile/lib/core/services/subscription_api_service.dart
apps/mobile/lib/core/services/analytics_service.dart
apps/mobile/lib/core/widgets/upgrade_prompt_sheet.dart
```

### Modified mobile files

```text
apps/mobile/lib/features/auth/data/models/auth_state.dart
apps/mobile/lib/features/auth/presentation/providers/auth_provider.dart
apps/mobile/lib/core/models/user.dart
apps/mobile/lib/features/patient/presentation/screens/profile_screen.dart
apps/mobile/lib/features/patient/presentation/screens/upgrade_screen.dart
apps/mobile/lib/router/app_router.dart
apps/mobile/pubspec.yaml
```

### New backend files

```text
apps/backend/route/subscription.py
apps/backend/services/subscription_service.py
apps/backend/schemas/migrations/22_add_subscription_fields.sql
```

### Intended RevenueCat setup

```text
Entitlement: premium
Products:
- remi_premium_monthly
- remi_premium_annual
```

### User fields added

```text
plan
trial_start_date
trial_end_date
summary_count
remivox_interaction_count
subscription_source
revenuecat_app_user_id
revenuecat_entitlement_active
subscription_updated_at
```

### Risk

High.

This touches auth, profile loading, backend user schema, RevenueCat sync, and feature gating. RevenueCat sync was originally awaited during login and slowed email login. It was later changed to run in the background.

### Recommendation

Reintroduce RevenueCat in isolation after summary generation is stable. Do not let subscription sync block login.

## 4. Premium feature gates

### Intended gates

```text
Vox
AI summaries
Caregiver invites
```

### Files touched

```text
apps/mobile/lib/features/patient/presentation/screens/visit_recording_screen.dart
apps/mobile/lib/features/patient/presentation/screens/care_team_screen.dart
apps/mobile/lib/features/care_team/data/services/care_team_api_service.dart
apps/backend/route/care_team.py
apps/backend/services/ai_pipeline.py
apps/backend/services/subscription_service.py
```

### Caregiver counting rule

Approved rule:

```text
Free/trial: accepted + pending caregivers count toward limit 1
Premium: up to 5 caregivers
```

### Risk

High.

Care team currently mixes Firestore direct writes with backend SQL routes. The mobile app was changed to call backend first, then create a Firestore mirror. This can create consistency issues.

### Recommendation

Move all care-team invite creation to backend. Backend should write SQL and any Firestore mirror if needed. Mobile should not directly create top-level invitation documents.

## 5. RemiVox backend

### Purpose

Add Vox voice assistant using SmallestAI.

### New backend route

```text
apps/backend/route/remivox.py
```

### Endpoints added

```text
POST /api/remivox/today
POST /api/remivox/ask
```

### Backend context used

```text
today reminders
upcoming reminders
missed reminders
latest visit summary
```

### Expected backend env var names

```text
SMALLESTAI_API_KEY
SMALLESTAI_VOICE_ID
SMALLESTAI_OUTPUT_FORMAT
SMALLESTAI_SAMPLE_RATE
SMALLESTAI_TTS_URL
```

Do not use these incorrect names:

```text
SMALLEST_API_KEY
SMALLEST_VOICE_ID
```

Also watch for accidental leading spaces in env var names.

### Risk

Medium/high.

This sends health context to an external TTS provider. Privacy policy and review language must clearly state what data is sent and why.

### Recommendation

Vox should be positioned as a reading/accessibility companion, not medical advice.

## 6. RemiVox mobile behavior

### Files touched

```text
apps/mobile/lib/features/patient/presentation/widgets/patient_app_shell.dart
apps/mobile/lib/core/services/backend_api_service.dart
apps/mobile/lib/features/patient/presentation/screens/vox_screen.dart
apps/mobile/lib/router/app_router.dart
apps/mobile/pubspec.yaml
```

### Dependency added

```yaml
audioplayers
```

### Current intended behavior

User requested Siri-style behavior:

```text
Tap Vox
App listens briefly
User asks a question
Backend answers from summaries/reminders/meds/missed items
App plays audio without opening a new screen
```

### Risk

High.

Speech recognition, playback, and backend call are currently embedded in `PatientAppShell`. This should be reworked into a dedicated Vox feature.

## 7. Production summary generation issues

This is the most critical area.

### A. Monetization enforcement in AI pipeline

File:

```text
apps/backend/services/ai_pipeline.py
```

Hard summary-limit enforcement was added before Gemini generation. This was risky and likely contributed to production failures.

Hotfix:

```text
9da48be Make summary limit enforcement opt in
```

Now hard enforcement only runs if:

```text
ENFORCE_SUMMARY_LIMITS=true
```

Recommendation: leave this unset until the monetization system is production-ready.

### B. Missing Cloud Scheduler STT endpoint

Cloud Scheduler was calling:

```text
/api/internal/process-pending-stt-jobs
```

That endpoint was missing.

Hotfix:

```text
ed987fa Restore scheduled STT job endpoint
```

File:

```text
apps/backend/route/internal_cron.py
```

### C. Visit metadata lookup mismatch

`GET /api/visits/{visit_id}` only matched internal UUID ownership. Some production rows use Firebase UID or are recoverable through `summaries_log`.

Hotfix:

```text
4a14d3a Fix visit metadata lookup for legacy ownership
```

File:

```text
apps/backend/route/visit_summary.py
```

### D. Summary lookup mismatch

Production `summaries_log.user_id` sometimes stores Firebase UID, while lookup used internal UUID.

Hotfix:

```text
1822aaa Fix summary lookup for Firebase UID rows
```

Files:

```text
apps/backend/services/db_service.py
apps/backend/route/visit_summary.py
```

## 8. Production DB finding for visit 2f0f630f

Visit:

```text
2f0f630f-7c67-4a8b-82b6-7fa83473657a
```

State found:

```text
visits row exists
visit_transcripts row exists
audio_url exists
transcript_text exists, length 2009
original STT_JOB completed
summaries_log row exists
structured_data_json exists
```

Conclusion: this visit did not need an STT reset. The summary existed; the route lookup was using the wrong user id shape.

## 9. Test Premium allowlist

### Purpose

Allow testing Premium without buying a subscription.

### Env var

```text
REMIMINDER_TEST_PREMIUM_UIDS=<comma-separated Firebase UIDs>
```

### Risk

Low if used only for staging/testing. Do not keep production tester UIDs enabled long-term.

## 10. Account Details usage count

### Issue

Account Details showed:

```text
0 summaries generated
```

even when Overview showed summaries.

### Fix

File:

```text
apps/mobile/lib/features/patient/presentation/screens/account_details_screen.dart
```

Now it fetches `/api/summaries` and uses that list count.

Commit:

```text
eed1eef Use summaries list for account usage count
```

## 11. Files added

```text
apps/backend/route/remivox.py
apps/backend/route/subscription.py
apps/backend/services/subscription_service.py
apps/backend/schemas/migrations/22_add_subscription_fields.sql
apps/mobile/lib/core/models/monetization_status.dart
apps/mobile/lib/core/services/analytics_service.dart
apps/mobile/lib/core/services/revenuecat_service.dart
apps/mobile/lib/core/services/subscription_api_service.dart
apps/mobile/lib/core/widgets/upgrade_prompt_sheet.dart
apps/mobile/lib/features/patient/presentation/screens/vox_screen.dart
```

## 12. Dependencies added

```yaml
purchases_flutter
firebase_analytics
audioplayers
```

Verify exact versions and compatibility with current Flutter before reintroducing.

## 13. Recommended rework order

### Phase 1: Stabilize production summaries

Start from July 7 stable revision and cherry-pick only summary-safe backend fixes:

```text
ed987fa Restore scheduled STT job endpoint
4a14d3a Fix visit metadata lookup for legacy ownership
1822aaa Fix summary lookup for Firebase UID rows
9da48be Make summary limit enforcement opt in
```

Verify:

```text
new audio visit generates summary
existing generated summaries display
Cloud Scheduler succeeds
no ENFORCE_SUMMARY_LIMITS=true
```

### Phase 2: Reapply navy color migration

Color migration is low risk and can be reintroduced after summaries are stable.

### Phase 3: RevenueCat only

Add RevenueCat without touching:

```text
ai_pipeline.py
internal_cron.py
summary lookup helpers
```

### Phase 4: Feature gates

Add client-side gates first. Backend hard enforcement should be added only after subscription state is proven reliable.

### Phase 5: Vox

Add Vox as an isolated feature module. Do not place speech/audio/backend logic in `PatientAppShell`.

## 14. Strong recommendation

Do not deploy the full current `main` directly to production.

Instead:

1. Keep production on stable July 7.
2. Cherry-pick only backend summary fixes first.
3. Validate summaries.
4. Reintroduce color changes.
5. Reintroduce RevenueCat.
6. Reintroduce Vox last.

Highest-risk files:

```text
apps/backend/services/ai_pipeline.py
apps/backend/route/internal_cron.py
apps/backend/services/db_service.py
apps/backend/route/visit_summary.py
apps/mobile/lib/features/auth/presentation/providers/auth_provider.dart
apps/mobile/lib/features/patient/presentation/widgets/patient_app_shell.dart
```

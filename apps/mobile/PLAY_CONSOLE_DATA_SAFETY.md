# Google Play Console — Data Safety & Declarations

Use this checklist when submitting **RemiMinder** (`com.remiminderai.app`). Align answers with the live app and [privacy-policy.html](../../privacy-policy.html).

## Store listing

| Field | Value |
|-------|--------|
| Privacy policy URL | `https://remiminderai.com/privacy` |
| Category | Health & Fitness |
| Target audience | Adults (not designed for children under 13) |
| Medical disclaimer in description | Yes — not a substitute for professional medical advice |

## Data safety form

### Data collected

| Data type | Collected | Shared | Required / optional | Purpose |
|-----------|-----------|--------|---------------------|---------|
| Name | Yes | No* | Required (account) | Account management |
| Email address | Yes | No* | Required (account) | Account management, support |
| Phone number | Optional | No* | Optional | Account profile |
| Health info (meds, visits, summaries) | Yes | Yes** | Core feature | App functionality |
| Photos (prescriptions, labs) | Yes | No* | Optional (user-initiated scan) | App functionality |
| Audio (visit recordings) | Yes | Yes*** | Optional (user-initiated) | Transcription / summaries |
| Device or other IDs (FCM token) | Yes | Firebase only | Required for push | Push notifications |
| App interactions / crash logs | No | — | — | Not collected in mobile app |
| Precise location | No | — | — | Not collected |

\* Shared only with infrastructure processors (Firebase/GCP/Google AI) as described in the privacy policy, not sold to third parties.

\** Shared with caregivers the user explicitly invites, per permission level (view / full access).

\*** Processed by Google Speech-to-Text and Gemini via RemiMinder backend; not used for ads.

### Security practices

- Data encrypted in transit: **Yes** (HTTPS)
- Users can request data deletion: **Yes** (in-app account deletion + email to privacy@remiminder.ai)
- Committed to Play Families policy: **N/A** (not targeting children)

### Data usage

- Not used for advertising or marketing from third-party ad networks
- FCM token used **only** for push notifications (medication reminders, care alerts)

## Permission declarations (Android)

| Permission | Declare? | Justification |
|------------|----------|---------------|
| `CAMERA` | Yes | Scan prescriptions and lab documents with user consent |
| `RECORD_AUDIO` | Yes | Record healthcare visits with inline consent |
| `POST_NOTIFICATIONS` | Yes | Medication and care reminders |
| `SCHEDULE_EXACT_ALARM` | Yes | Timely medication reminders when app is closed |
| `INTERNET` | Yes | Sync with RemiMinder API and Firebase |

**Removed from manifest (do not declare):** `USE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, `READ/WRITE_EXTERNAL_STORAGE`.

## Exact alarms declaration

- Feature: medication reminders at user-scheduled times
- User benefit: reliable alerts for time-sensitive medications
- Runtime permission requested when enabling reminders / on first launch (consider moving to contextual prompt in a future release)

## Health apps

- App provides health-related features but is **not** a regulated medical device
- In-app AI disclaimer localized via `aiSummaryDisclaimer` string
- No claims of diagnosis, cure, or FDA clearance in store listing

## Account deletion

- Path: **Profile → Delete Account** or **Privacy Settings → Delete my account**
- Backend: `DELETE /api/users/me` (permanent deletion)
- Export / partial record deletion: email `privacy@remiminder.ai` (mailto from Privacy Settings)

## Payments

- Current Android build: upgrade flow opens external pricing page; no in-app digital goods purchase in the shipped router
- If enabling in-app subscriptions later, comply with [Payments policy](https://support.google.com/googleplay/android-developer/answer/9858738)

## Before upload

1. Production `google-services.json` for `com.remiminderai.app` in `android/app/`
2. Release keystore configured via `android/key.properties` (see [ANDROID_RELEASE.md](ANDROID_RELEASE.md))
3. Privacy policy live at `https://remiminderai.com/privacy` matches this document
4. Run `flutter build appbundle --release` and verify merged manifest has no legacy storage permissions

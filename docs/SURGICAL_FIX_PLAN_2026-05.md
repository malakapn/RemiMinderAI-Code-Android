# Surgical fix plan — three regressions (Phase A only)

**Branch:** `fix/three-regressions` on `RemiMinderAI-Code-Review`  
**Phase:** **A = analysis (this document). Phase B = execution — do not start until the user explicitly approves Phase A.**  
**Constraints honored here:** No code changes beyond this doc in Phase A; no push to `main`; no `feature/ios-support`; no secrets.

---

## Executive summary

1. **Fix 1 (splash + welcome):** Restore native API 31+ XML from Code-Review **`a33113b`**; layer Cromwell **brand + welcome UX** from Mobile `new-frontend-changes` (see Cromwell inventory — exclude `patient_home` / nav shell changes that collide with **My Tasks** by default).
2. **Fix 2 (caregiver invite):** **Mohammad = asad6202.** His commits are **not** on Mobile `main`, `fix/login`, `feature/stt-ocr-nav-updates`, or `new-frontend-changes` (ancestor check). On Code-Review they exist only on **remote topic branches** (e.g. `origin/feature/FCM-notification-api-Integration`), **not** on `origin/main`. **Hybrid recommendation:** keep **DB insert + token** flow in `care_team.py`; **replace** email send + HTTP contract with logic that checks `send_invite_email` return value and surfaces failure — align body of send with **`fix/login` @ `f85fe33`** / current Brevo service as needed after diff review in Phase B.
3. **Fix 3 (summary pipeline):** Prefer **file-scoped checkouts** from Mobile `feature/stt-ocr-nav-updates` @ **`501997c`** (and parents in that branch for missing pieces), **not** a wholesale diff against Mobile `main` (Mobile `main` includes unrelated mega-changes). Subset listed in §5.
4. **Cromwell on `new-frontend-changes`:** Only **one** commit is **not** already in `fix/login`: **`3baa518`**. Other Cromwell commits are **shared history** with `fix/login` when using `main..new-frontend-changes`; they still **touch caregiver nav / home / reminders** — treat as **approval-gated**.
5. **Contamination:** No asad6202 SHA is an ancestor of Mobile’s four scope branches or Code-Review **`origin/main`**; asad commits **are** present on Code-Review **FCM topic remotes** — do not merge those branches wholesale into `fix/three-regressions`.

---

## 1. Cromwell-authored inventory (`RemiMinderAI-Mobile`)

### 1.1 “Cromwell-only” relative to Sri’s `fix/login`

```bash
git fetch origin fix/login new-frontend-changes
git log origin/fix/login..origin/new-frontend-changes --format="%h %an %s"
```

**Result:** exactly **`3baa518`** — Cromwell De Guzman — `bugfix 1, 7, 14`.

**Files (`git show 3baa518 --name-status`):**

| Path | Action |
|------|--------|
| `apps/mobile/android/local.properties` | M |
| `apps/mobile/lib/features/auth/presentation/screens/role_selection_screen.dart` | M |
| `apps/mobile/lib/features/patient/presentation/screens/account_details_screen.dart` | M |
| `apps/mobile/lib/features/patient/presentation/screens/visit_recording_screen.dart` | M |
| `apps/mobile/pubspec.yaml` | M |

**Classification:**

| File | Class | Default for Phase B |
|------|-------|---------------------|
| `role_selection_screen.dart` | **SPLASH/WELCOME** (auth entry flow adjacent to welcome) | Include in Fix 1 after review |
| `local.properties` | **OUT OF SCOPE** (machine-specific) | **Exclude** |
| `account_details_screen.dart` | **OTHER UX POLISH** | **Approval required** |
| `visit_recording_screen.dart` | **OTHER UX POLISH** (touches recording; overlaps Fix 3 STT entry) | **Exclude by default**; only include if Fix 3 requires matching behavior — gate separately |
| `pubspec.yaml` | **Shared** | Version bump on Code-Review is **canonical** (`1.3.1+56` per user); do **not** blindly copy Mobile `pubspec` from Cromwell |

### 1.2 Other Cromwell commits on `origin/main..origin/new-frontend-changes` (shared with `fix/login` — still Cromwell-authored)

| SHA | Message | Files touched (summary) | Classification / default |
|-----|---------|-------------------------|---------------------------|
| `55d7777` | liquid glass attempt 3 | `theme.dart`, `rounded_navigation_bar.dart`, `MainActivity.kt`, `AndroidManifest.xml`, `build.gradle.kts` | **SPLASH/WELCOME-adjacent** (theme/nav/native) **but** nav touches **shell** — **MEDIUM risk** to caregiver/patient nav; **approval** if rounded bar changes desired |
| `f9d2368` | updated logos and icons | Launcher mipmaps, **`welcome_screen.dart`**, **`login_screen.dart`**, **`loading_screen.dart`**, asset PNGs, iOS icons | **SPLASH/WELCOME + brand** — **primary** Cromwell layer for Fix 1 (**Android assets only** if iOS branch forbidden) |
| `7f2f331` | updated reminders screen colors | **`patient_home_screen.dart`**, **`reminders_screen.dart`** | **OUT OF SCOPE** — **My Tasks** lives in `patient_home_screen.dart` (`title: 'My Tasks'` on Code-Review); **exclude** |
| `7f97311` | updated upgrade screen | `upgrade_screen.dart` | **OTHER UX POLISH** — **approval** |
| `6b3c5d4` | fixed page routing and colors | **`app/router/app_router.dart`**, **`patient_app_shell.dart`**, **`rounded_navigation_bar.dart`**, `alert_list_screen.dart` (caregiver), `google-services.json` | **OUT OF SCOPE by default** — conflicts **caregiver dashboard** + global nav |
| `f22552e` | commit | `main.py`, `gcs_service.py`, `app.dart`, `build.gradle.kts` | **OUT OF SCOPE** — backend + broad app entry |
| `18b4fd0` | updated remember me, broke sign in | auth, `users.py`, `db_service` | **OUT OF SCOPE** — explicit regression risk in message |
| `e2ed3bf` | signin changes | `users.py`, `db_service`, auth services | **OUT OF SCOPE** unless Fix 2 absolutely requires (unlikely) |

**Primary “OTHER UX POLISH” list for user approval:**  
`account_details_screen.dart` (`3baa518`), `upgrade_screen.dart` (`7f97311`), optional `visit_recording_screen.dart` (`3baa518`), optional `55d7777` nav/theme (high coupling).

---

## 2. Mohammad (asad6202) — caregiver invite evaluation

**Branch:** `origin/feature/FCM-notification-api-Integration` on Mobile (same commits mirrored on Code-Review FCM remotes — **not** on `origin/main`).

### 2.1 All commits (`git log --all --author="asad6202"`)

| SHA | Date | Message |
|-----|------|---------|
| `e4fe779` | 2026-04-22 | FCM notification and api integration is completed |
| `19039e7` | 2026-04-27 | feat: Phase 1 — FCM notifications, caregiver alerts, notes, reminder fixes |
| `a6915f2` | 2026-04-27 | chore: point mobile to production backend + latest fixes |
| `f0b0050` | 2026-04-28 | fix: resolve stuck loading screen — GoRouter + Riverpod 3 router notifier… |
| `39d6dd4` | 2026-04-28 | fix: schedule local notification immediately on reminder creation |
| `dcae762` | 2026-04-28 | fix: refresh Firebase token on app restart instead of logging user out |
| `c3ea331` | 2026-04-28 | feat: complete caregiver-patient workflow fixes for reminders, alerts, docs, and dashboard tasks |
| `41b9259` | 2026-04-28 | fix: add POST /api/caregivers/alerts endpoint for manual alert creation |
| `991b98b` | 2026-04-29 | fix: GCS signed URL signing on Cloud Run, history screen doc view, auth improvements |
| `a0f7393` | 2026-04-29 | fix: GCS signed URL using IAM fallback for Cloud Run — no private key needed |
| `662ea15` | 2026-04-29 | feedback fixes |
| `34cd0f2` | 2026-04-29 | logo and audio fix |
| `0d29db3` | 2026-04-30 | audio and login fixed |

### 2.2 Invite-related file hits (authoritative paths from `git show` filters)

- **`19039e7`:** `apps/backend/route/care_team.py`, `care_team_invitation.dart`, `care_team_api_service.dart`, migration `18_caregiver_alert_email_pref.sql`
- **`c3ea331`:** `apps/mobile/.../care_team_api_service.dart` (among many other files — **mega commit**)

**Keep vs replace (verdict for Phase B):**

| Concern | Likely “keep” (concepts) | Likely “replace” / fix |
|---------|-------------------------|------------------------|
| Invite **record** + token | `create_care_team_invitation` / DB row / invalidate caches — **stable** | — |
| **Deep link** construction | Token passed to client; signup URL env — verify against current Brevo template | If Mohammad’s branch altered URL shape, **standardize** on Code-Review `CARE_TEAM_INVITE_SIGNUP_URL` + query param |
| **Email send** | — | Whatever path fails in prod — **do not** trust monolithic FCM commits; use **Brevo** implementation + **check return bool** |
| **Silent success** | — | **`care_team.py`** today returns `{"status":"sent"}` even if `send_invite_email` returns `False` — **must fix** in Phase B (minimal: branch on return value + 503/502 or structured failure) |
| **Mobile UX** | Care team API client shapes from **`f85fe33`** may be closer to Sri’s tested flow | Merge **selectively** — avoid `c3ea331` wholesale (touches dashboard/tasks) |

**Hybrid feasibility:** **HIGH** — server-side separation is clear: **DB + token** vs **`send_invite_email`**. **LOW feasibility** if Phase B discovers `care_team.py` on FCM branch diverged structurally from Code-Review (large conflict) — then **fallback: `f85fe33` full invite stack** (document in Phase B commit message).

---

## 3. Sri STT / OCR / summary — file scope (`feature/stt-ocr-nav-updates`)

**Tip:** `501997c` — `STT-OCR code updations` (2026-02-06).  
**Note:** `git diff --name-only origin/main origin/feature/stt-ocr-nav-updates` on Mobile is **huge** because Mobile **`main`** includes Paramita mega-integrations; Phase B must **not** apply that wholesale diff to Code-Review.

### 3.1 Commit `501997c` — files (directly from Mobile git)

Include: `ARCHITECTURE.md`, experiments, `list_tables.py`, `main.py`, `patient_tasks.py`, `reminders_ocr.py`, `users.py`, `visit_summary.py`, migrations `14_add_patient_tasks.sql`, `15_convert_user_id_to_text.sql`, schemas, **`summary_normalizer_v2.py`**, **`vertex_gemini_service.py`**, **`ai_pipeline.py`**, `db_service.py`, `tasks_service.py`, mobile: icons, **`theme.dart`**, **`visit_details_screen.dart`**, **`overview_screen.dart`**, **`patient_home_screen.dart`**, **`rounded_navigation_bar.dart`**, `patient_task.dart`, `patient_tasks_api_service.dart`, assets, `pubspec.yaml`, etc. (81 files in stat).

### 3.2 **Minimal recommended set for Code-Review Fix 3** (narrow)

**Backend (summary + STT + OCR support):**

- `apps/backend/route/visit_summary.py`
- `apps/backend/services/ai_pipeline.py`
- `apps/backend/services/ai/vertex_gemini_service.py`
- `apps/backend/services/ai/summary_normalizer_v2.py` (if present on branch vs main)
- `apps/backend/utils/prompts/medical_summary_v2.py`
- `apps/backend/utils/prompts/medical_summary.py` — include if Sri branch differs from Code-Review contract
- `apps/backend/workers/stt_worker.py`
- `apps/backend/jobs/stt_job.py`
- `apps/backend/services/media/audio_pipeline.py` — **only if** diff vs Code-Review main is non-empty for pipeline
- `apps/backend/route/reminders_ocr.py`, `apps/backend/services/ocr_service.py`, `apps/backend/services/db_reminders_ocr.py` — **if** OCR is part of “summary generation” dependency chain in staging

**Migrations (apply only with DBA sign-off):**

- `apps/backend/schemas/migrations/14_add_patient_tasks.sql`
- `apps/backend/schemas/migrations/15_convert_user_id_to_text.sql`

**Flutter (summary UI + API client):**

- `apps/mobile/lib/features/patient/presentation/screens/visit_details_screen.dart`
- `apps/mobile/lib/features/patient/data/services/patient_api_service.dart` — **only if** summary endpoints / parsing differ
- `apps/mobile/lib/features/patient/data/services/visit_summary_gemini_prompt.dart` — if exists on Code-Review / branch

**Explicitly EXCLUDE from Fix 3 unless Phase B proves required:**

- `patient_home_screen.dart` (**My Tasks**)
- `care_team_tab`, `my_patients` — caregiver dashboard
- `apps/mobile/lib/router/app_router.dart` — unless a **single-line** route to visit details is missing

**Reference UI gap:** Code-Review today may show **“Next Steps”** instead of **“Questions for Your Next Visit”** for the actions/questions list — Phase B may need a **label-only** change in `visit_details_screen.dart` if JSON uses `actions` or `questions_next_visit` from v1 prompt; align with normalized v2 keys (`actions` → display string).

---

## 4. Contamination trace (non-negotiable)

### 4.1 `git log --all --author="asad6202"` (Mobile + Code-Review)

Listed in §2.1 (13 commits).

### 4.2 Ancestor check vs four Mobile branches

For each SHA in §2.1:

```bash
git merge-base --is-ancestor <sha> origin/main   # etc.
```

**Result:** **none** of the 13 SHAs are ancestors of `origin/main`, `origin/fix/login`, `origin/new-frontend-changes`, or `origin/feature/stt-ocr-nav-updates` (all checks non-zero / empty branch membership).

### 4.3 Message grep (duplicate cherry-picks)

```bash
git log --all --grep="FCM notification and api integration" --oneline
git log --all --grep="Phase 1 — FCM" --oneline
git log --all --grep="resolve stuck loading screen" --oneline
git log --all --grep="GCS signed URL using IAM" --oneline
```

Hits return **only** the original SHAs (no duplicate subjects on `main`).

### 4.4 Code-Review `origin/main`

```bash
git merge-base --is-ancestor e4fe779 origin/main  # exit 1 → not contained
```

**asad6202 commits on Code-Review** appear under refs like **`origin/feature/FCM-notification-api-Integration`**, **`remotes/mohammed-fcm`**, **`remotes/remiminder-mobile-fcm`** — **not** merged into **`origin/main`**.

**Conclusion:** No asad6202 contamination of **`origin/main`** or the four Mobile **scope** branches. **Do not** merge FCM topic branches whole; **cherry-pick or re-implement** only invite/email fixes.

**Optional follow-up (Phase B):** `git cherry` Mobile vs Code-Review for Equivalence — only if a specific SHA is suspected duplicated.

---

## 5. Conflict analysis (cross-fix and out-of-scope)

| Area | Risk | Mitigation |
|------|------|------------|
| **My Tasks** | `patient_home_screen.dart` appears in Sri `501997c` and Cromwell `7f2f331` | **Exclude** those files from Fix 3 and Cromwell polish; **never** take Mobile mega-diff |
| **Caregiver dashboard** | `6b3c5d4` touches `alert_list_screen.dart`, shell, router | **Exclude** Cromwell shell/router commits from Fix 1 |
| **iOS** | Cromwell `f9d2368` includes iOS asset tree | Phase B: **`git checkout` only `android/` + `assets/` + selected Dart**, skip `ios/` |
| **Fix 1 vs Fix 3** | `visit_recording_screen.dart` in `3baa518`; summary pipeline touches recording flow | Default **exclude** `3baa518` recording from Fix 1; revisit after Fix 3 |
| **Fix 2 vs Fix 3** | `care_team.py` vs `visit_summary.py` — typically **disjoint** | Low risk |
| **Shared backend** | `main.py`, `db_service.py` touched by many branches | **Minimal diff**: only include router registrations / helpers strictly required for chosen routes |

---

## 6. Phase B preview (commands — **do not run until approved**)

### 6.0 CI + version (first commit on `fix/three-regressions`)

Edit `.github/workflows/build.yml`:

```yaml
on:
  push:
    branches:
      - main
      - 'fix/**'
  pull_request:
    branches:
      - main
  workflow_dispatch:
```

`apps/mobile/pubspec.yaml`: `version: 1.3.1+56`  
Confirm `apps/mobile/android/app/build.gradle.kts` uses Flutter `local.properties` / `flutter.versionCode` — adjust only if project overrides.

Suggested message: `ci(android): build workflow on fix/* branches; bump 1.3.1+56`

### 6.1 Fix 1 — native + brand (second commit)

```bash
git remote add mobile https://github.com/malakapn/RemiMinderAI-Mobile.git  # if missing
git fetch mobile new-frontend-changes

# Native API 31+ from Code-Review history
git checkout a33113b -- apps/mobile/android/app/src/main/res/values-v31 \
  apps/mobile/android/app/src/main/res/values-night-v31
# Merge carefully: restore LaunchTheme items in values/styles.xml if a33113b differs from main
git show a33113b:apps/mobile/android/app/src/main/res/values/styles.xml > /tmp/styles_a33113b.xml
# (Compare with HEAD and apply minimal patch — Phase B detail)

# Cromwell brand + welcome (Android-only extract)
git checkout mobile/new-frontend-changes -- apps/mobile/android/app/src/main/res/mipmap-hdpi/launcher_icon.png  # … all mipmap densities …
git checkout mobile/new-frontend-changes -- apps/mobile/assets/images/RemiMinder_logo_2a.png  # etc.
git checkout mobile/new-frontend-changes -- apps/mobile/lib/features/auth/presentation/screens/welcome_screen.dart
git checkout mobile/new-frontend-changes -- apps/mobile/lib/features/auth/presentation/screens/login_screen.dart
git checkout mobile/new-frontend-changes -- apps/mobile/lib/features/shared/presentation/screens/loading_screen.dart
# Optional: role_selection_screen from 3baa518 after diff review
```

### 6.2 Fix 2 — invite (third commit)

- Patch `apps/backend/route/care_team.py` to **fail** or return explicit status when `send_invite_email` is `False`.
- Diff `apps/backend/route/care_team.py` and `invitation_email_service.py`: **Mobile `f85fe33`** vs **HEAD**; choose minimal union.
- Mobile: only `care_team_screen` / `care_team_api_service` / `auth_provider` if error handling requires UI.

### 6.3 Fix 3 — summary (fourth commit)

```bash
git fetch mobile feature/stt-ocr-nav-updates
# For each path in §3.2 minimal set:
git checkout mobile/feature/stt-ocr-nav-updates -- apps/backend/route/visit_summary.py
# … etc. — skip patient_home_screen.dart
```

### 6.4 PR (after Phase B)

- **Title:** `Surgical fixes: splash + welcome, caregiver invite, summary generation (1.3.1+56)`
- **Do not merge** to `main`.

**PR body — verification checklist:**

- [ ] AAB built successfully from `fix/three-regressions` via GitHub Actions (versionCode **56**)
- [ ] Uploaded to Play Console internal testing track
- [ ] Splash: cold-launch on Android 12+ device, no white flash, brand splash renders, welcome screen follows
- [ ] Caregiver invite: patient sends invite to a real test email, recipient receives email, link works, caregiver can complete signup; if email fails, patient app shows an error (no silent success)
- [ ] Summary generation: record a doctor-patient conversation, summary renders matching reference UI (paragraph card + Medications list + Questions for Your Next Visit)
- [ ] Regression check: My Tasks still works
- [ ] Regression check: caregiver dashboard still pulls real patient data
- [ ] Regression check: login still works
- [ ] Regression check: navigation still works
- [ ] Regression check: any other previously-working features still work

---

## 7. Phase A gate — user approval checklist

Before Phase B:

- [ ] **Cromwell “OTHER UX POLISH”:** approve or reject `account_details_screen.dart`, `upgrade_screen.dart`, optional `visit_recording_screen.dart`, optional `55d7777` theme/nav.
- [ ] **Fix 3 scope:** confirm **minimal file set** in §3.2 vs broader `501997c` (if staging requires `patient_tasks` migrations).
- [ ] **Fix 2:** confirm hybrid (DB + token + fixed email + error propagation) vs **full Sri `f85fe33`** takeover if Phase B finds `care_team.py` irreconcilable.

---

## 8. Rollback

Delete or reset branch `fix/three-regressions` to `origin/main`; `main` untouched.

---

*Phase A complete — awaiting explicit user approval to execute Phase B.*

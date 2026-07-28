# RemiMinder Backend Architecture & India Android Login Analysis

**Date:** 2026-07-27  
**Scope:** Phase 2 production stack (Flutter Android + FastAPI on GCP)  
**Question:** Are Indian Android login failures caused by a US East Coast server location?

---

## Short answer

**Mostly no.** Latency from India to the US can make login *flaky*, but it is **not** the primary root cause.

| Fact | Detail |
|------|--------|
| API region | **`us-central1` (Iowa)** — Midwest, **not** US East Coast |
| Email alerts | AWS SES defaults to **`us-east-2` (Ohio)** — unrelated to login |
| Vertex AI | **`us-west4`** — post-login AI only |
| Primary login failure modes in code | Miswired Google Sign-In, SHA/`google-services.json`, identity-conflict bug, tight client timeouts |

Firebase Auth itself is a **global Google service**. The India→US hop that matters for “login feels broken” is the **post-auth bootstrap** call to Cloud Run in `us-central1`.

---

## Complete backend architecture (Phase 2)

```
┌──────────────────────── Android / iOS (Flutter) ─────────────────────────┐
│  Firebase Auth (email / Google / Apple)                                   │
│  SecureStorage (ID token) │ Firestore client │ FCM │ RevenueCat          │
│  HTTPS → Cloud Run API                                                    │
└──────────────┬──────────────────────┬───────────────────┬────────────────┘
               │ Bearer ID token      │ profile write     │ push token
               ▼                      ▼                   ▼
    ┌──────────────────┐     ┌──────────────┐    ┌─────────────┐
    │ Firebase Auth    │     │ Cloud        │    │ FCM         │
    │ (Google IdP)     │     │ Firestore    │    │             │
    └────────┬─────────┘     └──────────────┘    └─────────────┘
             │ verify JWKS
             ▼
    ┌──────────────────────────────────────────────────────────────────────┐
    │ Cloud Run API — us-central1                                          │
    │ remiminder-backend-575820802106.us-central1.run.app                  │
    │ • auth_gateway (Firebase JWT → Cloud SQL user)                       │
    │ • users / visits / reminders / FCM / RemiVox / cron hooks            │
    │ • GCS uploads │ Brevo invites │ SES email │ Vertex Gemini calls      │
    └───────────────┬───────────────────────────────┬──────────────────────┘
                    │ STT job rows                  │ LLM / speech
                    ▼                               ▼
         ┌─────────────────────┐         ┌──────────────────────┐
         │ Cloud Run worker    │         │ Vertex AI Gemini     │
         │ remiminder-stt-     │         │ us-west4             │
         │ worker (us-central1)│         │ gemini-2.5-flash     │
         └─────────────────────┘         └──────────────────────┘
                    │
                    ▼
         ┌─────────────────────┐
         │ Cloud SQL           │
         │ PostgreSQL          │
         │ (same GCP project)  │
         └─────────────────────┘
```

### Component inventory

| Layer | Technology | Region / notes |
|-------|------------|----------------|
| Mobile | Flutter + Riverpod | Android package `com.remiminderai.app` |
| Auth | Firebase Auth (email, Google, Apple) | Global; project `stunning-ripsaw-480402-i4` |
| API | FastAPI on Cloud Run | **`us-central1`** |
| DB | Cloud SQL PostgreSQL | GCP project above; no Asia replica in repo |
| Profile mirror | Cloud Firestore | Client writes `users/{uid}` |
| Object storage | GCS (`*.firebasestorage.app`) | Audio / media |
| Push | FCM | Via backend `/api/fcm/token` |
| Email | Brevo (invites) + AWS SES (alerts) | SES **`us-east-2`** default |
| AI | Vertex Gemini `gemini-2.5-flash` | **`us-west4`** |
| TTS (RemiVox) | SmallestAI HTTP | External |
| Billing | RevenueCat (+ Stripe checkout URLs) | Client-side |
| Jobs | SQL job table + Cloud Run STT worker | Poll loop, not Redis |
| Cache | In-process TTL only | No Redis / Memorystore |
| CDN | Mentioned in old `ARCHITECTURE.md` | **Not configured in repo** |
| Phase 1 (archived) | Vercel + Supabase + FastAPI | Not production mobile path |

**GCP project:** `stunning-ripsaw-480402-i4` (number `575820802106`)

There is **no** `ap-south1` / Mumbai / Asia Cloud Run or Cloud SQL config in this repository.

---

## Android login data flow

### Supported methods
- Email / password (Firebase)
- Google Sign-In → Firebase credential
- Apple Sign-In (primarily iOS)
- **No** phone OTP / SMS login

### Happy path

1. App loads `.env` → `AUTH_PROVIDER=firebase`, API = Cloud Run `us-central1`
2. `bootstrapFirebase()` (8s timeout)
3. User signs in → Firebase issues ID token → stored in secure storage
4. Client `POST /api/users/bootstrap` with `Authorization: Bearer <ID token>`
5. Backend verifies JWT via Google JWKS; upserts Cloud SQL `users` row
6. Client mirrors profile to Firestore
7. Client `GET /api/users/me`
8. FCM token registered; RevenueCat `logIn(firebaseUid)`

### Timeouts that matter for India

| Step | Timeout | Risk |
|------|---------|------|
| Firebase init | 8s | Slow Google reachability → app without Firebase |
| Auth status restore | 10s → force logged out | Session appears lost |
| Many mobile HTTP calls | **often no client timeout** | Hang on slow India→US path |
| Backend JWKS fetch | 10s | 503 if Google JWKS unreachable (rare) |

---

## Root causes ranked (India Android)

### 1. Google Sign-In miswired (high confidence) — *not regional*

- `GoogleSignIn()` was constructed **without `serverClientId`**
- `GOOGLE_WEB_CLIENT_ID` exists in `.env` / CI but was not applied to `GoogleSignIn`
- `resolveGoogleWebClientId()` existed but was unused
- `MainActivity` had no MethodChannel for native `default_web_client_id`

Symptom: `sign_in_failed` / `Missing Google ID token`

### 2. SHA fingerprints / `google-services.json` (high confidence)

- `google-services.json` is gitignored; wrong/missing file breaks Firebase Google Sign-In
- Release builds need **debug + upload + Play App Signing** SHA-1/256 in Firebase Console

### 3. Auth gateway identity-conflict bug (medium–high for returning users)

In `auth_gateway.py`, the `else` that raises HTTP 409 was attached to `if row:` instead of the “different firebase_uid” branch. Email match with a different UID could fall through incorrectly.

### 4. Google path treats backend failure as fatal (medium)

- Email sign-in: bootstrap/`/me` failure is **non-fatal** (user still authenticated)
- Google sign-in: same failure surfaces as Sign-In error

Combined with India→`us-central1` RTT, this makes Google login look “broken” when Firebase Auth already succeeded.

### 5. US hosting latency (contributing amplifier)

| Path | Typical RTT India → US |
|------|------------------------|
| India → `us-central1` Cloud Run | ~200–350ms+ per hop; worse on mobile networks |
| Multiple sequential calls (bootstrap + Firestore + `/me` + FCM) | Multiplies perceived delay |
| Cold-start Cloud Run | Extra 1–5s on scale-to-zero |

**Conclusion:** Region amplifies timeouts and Google-path fatality; it does not explain missing ID tokens or SHA misconfiguration.

---

## Recommended solution (priority order)

### P0 — Fix auth bugs (do first; low cost)

1. Wire `GoogleSignIn(serverClientId: …)` from `GOOGLE_WEB_CLIENT_ID` / Environment default
2. Implement Android MethodChannel for `default_web_client_id` (optional hardening)
3. Fix identity-conflict `else` nesting in `auth_gateway.py`
4. Make Google Sign-In backend bootstrap failure **non-fatal** (match email path)
5. Verify Firebase Console SHA-1/256 for debug, upload, and Play App Signing keys
6. Add explicit HTTP timeouts (15–20s) on bootstrap/`/me` with one retry

### P1 — Resilience without moving regions (cheap)

1. Raise Firebase bootstrap / auth restore timeouts slightly for production (12–15s)
2. Keep Cloud Run in `us-central1` but set a small `min-instances=1` **only if** cold starts dominate India complaints (costs money — measure first)
3. Log `X-Cloud-Trace-Context` / client region / latency on `/bootstrap` to confirm whether failures are timeout vs 4xx/5xx
4. Ensure Cloud Run concurrency and CPU boost are tuned; avoid always-on replicas until metrics justify them

### P2 — Regional improvement only if India is a primary market

| Option | Effect | Cost impact |
|--------|--------|-------------|
| **A. Single-region move to `asia-south1` (Mumbai)** | Best latency for India; worse for US users | Cloud SQL migrate + Cloud Run redeploy; Vertex may still be US |
| **B. Dual Cloud Run (`us-central1` + `asia-south1`) + global HTTPS LB** | Route users by geography | Higher: LB + 2 services; Cloud SQL stays one region (cross-region DB latency remains) |
| **C. Keep US API; rely on Firebase (global) + resilient bootstrap** | Fixes most “login” UX | **Lowest cost** — preferred unless India is majority traffic |

**Recommendation:** Ship P0+P1 first. Only pursue Mumbai multi-region if post-fix metrics still show India login failure correlated with API latency (not Google/SHA errors).

---

## How to save money (without hurting India login)

### Keep (already cost-efficient)

- Cloud Run scale-to-zero (don’t force min instances until proven)
- In-memory cache instead of Memorystore/Redis
- Gemini Flash / Flash-Lite (not Pro) for routine generation
- SQL job table + STT worker instead of always-on Pub/Sub consumers
- Single primary DB region

### Do these to cut spend

1. **Do not multi-region prematurely** — dual Cloud Run + LB + cross-region SQL is the expensive path; fix auth bugs first
2. **Right-size Cloud SQL** — use the smallest instance that holds p95 query latency; enable automatic storage increase; turn off unused HA if not required yet
3. **STT worker** — ensure it scales to zero when idle; avoid always-allocated CPU unless queue depth requires it
4. **Consolidate email** — pick Brevo *or* SES for transactional mail long-term (two vendors = two minimum footprints)
5. **Vertex region** — keep one AI region; don’t duplicate Gemini in Mumbai “just because” (token cost dominates over RTT for AI)
6. **Remove unused Phase 1 / Vercel / Supabase** spend if any staging still bills
7. **Log-based sampling** — avoid verbose production logging on every AI call beyond cost counters you already have
8. **CDN only for static assets** (privacy policy, web) — not a substitute for API region; cheap when limited to static hosting

### Spend only if metrics demand it

| Spend | When justified |
|-------|----------------|
| `min-instances=1` on API | Cold starts > ~5% of India login attempts |
| `asia-south1` Cloud Run | India is majority DAU **and** P0/P1 done |
| Cloud SQL read replica | Read-heavy caregiver dashboards, not login |
| Memorystore | High QPS caching need — login does not need it |

---

## Verification checklist (ops)

1. Reproduce login from an India VPN / device on email **and** Google
2. Capture failure class: Firebase error vs HTTP timeout vs 409/500 bootstrap
3. Confirm Play App Signing SHA in Firebase
4. Confirm release APK/AAB embeds correct `google-services.json` and `.env` API URL
5. After P0 fixes, compare India login success rate before/after (Crashlytics / Analytics / backend 4xx on `/bootstrap`)

---

## Key code / config references

| Area | Path |
|------|------|
| API URL / Google client ID | `apps/mobile/.env`, `apps/mobile/lib/core/config/environment.dart` |
| Google Sign-In | `apps/mobile/lib/core/services/firebase_auth_service.dart` |
| Auth state / bootstrap | `apps/mobile/lib/features/auth/presentation/providers/auth_provider.dart` |
| Backend JWT + identity | `apps/backend/services/auth_gateway.py` |
| STT worker region | `apps/backend/cloudbuild.worker.yaml` (`us-central1`) |
| Vertex region | `apps/backend/services/ai/vertex_gemini_service.py` (`us-west4`) |
| Release / SHA notes | `apps/mobile/ANDROID_RELEASE.md`, `ENV_SETUP.md` |

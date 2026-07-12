RemiMinder Environment Setup Guide

## Where to create `.env` files

### Backend and monorepo-wide variables

Recommended: create **one** `.env` at the **repository root** for Supabase, API URL, and server settings (see below). Use the path you use on your machine, for example:

- macOS / Linux: `/path/to/RemiMinderAI-Code-Review/.env`
- Windows: `C:\path\to\RemiMinderAI-Code-Review\.env`

The Python backend reads this file from its own working directory; follow `apps/backend` README for exact expectations.

### Flutter mobile (required for Google Sign-In)

The Flutter app loads **`apps/mobile/.env`** only. That file must exist and is bundled at build time (`flutter: assets:` in `apps/mobile/pubspec.yaml`).

**If you use a root `.env` for the monorepo**, copy or sync the variables the mobile app needs into `apps/mobile/.env` (or symlink if your setup allows). The mobile build does **not** automatically read the repository root `.env`.

## Required environment variables

### Mobile app (`apps/mobile/.env`)

Use the **Firebase Web client** OAuth client ID (Firebase Console → Project settings → Your apps → Web app, or Authentication → Sign-in method → Google). It looks like `xxxx.apps.googleusercontent.com`.

Either variable name is supported (same value):

```bash
API_BASE_URL=http://localhost:8000
MOBILE_API_BASE_URL=http://localhost:8000
FLUTTER_ENV=development
# Use one of the following (not both required):
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
# GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

On Android the app also reads **`default_web_client_id`** from the merged `google-services.json` (no `.env` required) so the Web client ID always matches your Firebase project.

`GOOGLE_CLIENT_ID` matches the name used in the shared examples below; the app checks `GOOGLE_WEB_CLIENT_ID` first, then `GOOGLE_CLIENT_ID`. If neither is present in the loaded `.env` file, the app still uses the Firebase **Web client ID** documented for this repository (same as below) so Google Sign-In works in CI and fresh builds; override anytime via `.env` or `--dart-define=GOOGLE_WEB_CLIENT_ID=...`.

### Both backend and mobile (example root `.env`)

```bash
# =============================================================================
# SUPABASE CONFIGURATION (Get from Supabase Dashboard)
# =============================================================================
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# =============================================================================
# GOOGLE OAUTH CONFIGURATION (for mobile: Web client ID — copy into apps/mobile/.env)
# =============================================================================
# For iOS: com.googleusercontent.apps.xxxxxxxxxx-xxxxxxxxxxxxxxxxxx
# For Android / serverClientId: xxxxxxxxxx-xxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
GOOGLE_CLIENT_ID=575820802106-m8q0lu61mdgls5r354uvd93phvf7ig9a.apps.googleusercontent.com

# =============================================================================
# API CONFIGURATION
# =============================================================================
API_BASE_URL=http://localhost:8000
FLUTTER_ENV=development
```

### Backend only (often in root ` .env` or `apps/backend/.env`)

```bash
HOST=0.0.0.0
PORT=8000
DEBUG=True
```

## How to get Supabase keys

1. Go to Supabase Dashboard and open your project.
2. Go to **Settings → API**.
3. Copy **Project URL** → `SUPABASE_URL`.
4. Copy **anon/public** key → `SUPABASE_ANON_KEY`.
5. Copy **service_role** key → `SUPABASE_SERVICE_ROLE_KEY`.

## Next steps

1. Create `.env` files with real keys (never commit them).
2. Ensure **`apps/mobile/.env`** includes `GOOGLE_CLIENT_ID` or `GOOGLE_WEB_CLIENT_ID` and run `flutter pub get` before `flutter run` / `flutter build`.
3. Test backend: `cd apps/backend` and start per that app’s README.

Firebase Android is already configured for this project (Google + Email/Password, **`google-services.json`** under `apps/mobile/android/app/` — often gitignored, supplied locally or via CI secrets). If Google Sign-In still returns `sign_in_failed` on a **new machine**, compare your debug keystore fingerprints to the Firebase Android app and confirm `apps/mobile/.env` is loaded after rebuild.

### SHA-1 vs SHA-256 in Firebase

Your **signing certificate** has **both** a SHA-1 and a SHA-256 fingerprint. They are different hashes of the **same** public key—not alternatives.

- In **Firebase Console → Project settings → Your apps → Android**, use **Add fingerprint** and paste the **SHA-1** value when the UI asks for it (same place accepts standard certificate fingerprints per [Google’s Firebase help](https://support.google.com/firebase/answer/9137403)).
- If your build log or tool only printed **SHA-256**, get **SHA-1** from the same keystore or APK, for example:
  - From the **debug keystore** (Windows path shown):

    `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android`

  - Or from `apps/mobile/android`: `.\gradlew signingReport` and copy both **SHA1** and **SHA256** lines for the variant you install (debug vs release).

Add every fingerprint for keys that sign builds you run (debug, release, Play App Signing), then download an updated **`google-services.json`** if Firebase prompts you to.

### Samsung / physical device crash on launch

If the app **installs but closes immediately** on a real phone, the most common cause is a **missing or placeholder** `google-services.json` (the repo may ship a stub with `mobilesdk_app_id` ending in zeros). Push/FCM starts native Firebase code before the UI loads and can crash the process.

**Fix:**

1. On your Mac, print your **debug SHA-1** (used by `flutter run`):

   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
   ```

2. [Firebase Console](https://console.firebase.google.com/) → project **stunning-ripsaw-480402-i4** → Project settings → Your apps → Android app **`com.remiminder.app.dev`** → **Add fingerprint** → paste SHA-1.

3. Download **`google-services.json`** and replace:

   `apps/mobile/android/app/google-services.json`

4. Rebuild:

   ```bash
   cd apps/mobile
   flutter clean && flutter pub get
   flutter run -d <device-id>
   ```

5. If it still crashes, capture logs:

   ```bash
   adb logcat -c
   # open app on phone
   adb logcat -d | grep -iE "FATAL|AndroidRuntime|Firebase|remiminder"
   ```

The app is designed to **open without Firebase** (welcome screen) if init fails, but a bad `google-services.json` can still crash native code before Dart runs — replacing that file is required for a stable Samsung build.

## Security notes

- Never commit `.env` files to git.
- The service role key has admin privileges; keep it secret.
- Use different keys for development, staging, and production.

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

`GOOGLE_CLIENT_ID` matches the name used in the shared examples below; the app checks `GOOGLE_WEB_CLIENT_ID` first, then `GOOGLE_CLIENT_ID`.

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

Firebase Android is already configured for this project (Google + Email/Password, debug SHA-1, **`google-services.json`** under `apps/mobile/android/app/` — often gitignored, supplied locally or via CI secrets). If Google Sign-In still returns `sign_in_failed` on a **new machine**, compare your debug keystore SHA-1 to the Firebase Android app and confirm `apps/mobile/.env` is loaded after rebuild.

## Security notes

- Never commit `.env` files to git.
- The service role key has admin privileges; keep it secret.
- Use different keys for development, staging, and production.

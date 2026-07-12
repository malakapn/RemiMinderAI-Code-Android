# Android release signing (Google Play)

Play / Android package ID: **`com.remiminder.app.dev`**

## 1. Create a release keystore (once)

```bash
keytool -genkey -v \
  -keystore ~/remiminder-release.keystore \
  -alias remiminder \
  -keyalg RSA -keysize 2048 -validity 10000
```

Keep the keystore and passwords secure. **Never commit** the keystore or `key.properties`.

## 2. Configure signing locally

Copy the example file and fill in your paths:

```bash
cp apps/mobile/android/key.properties.example apps/mobile/android/key.properties
```

Edit `key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=remiminder
storeFile=/absolute/path/to/remiminder-release.keystore
```

`apps/mobile/android/app/build.gradle.kts` uses this file automatically. Without it, release builds fall back to debug signing (local dev only).

## 3. Firebase / Google Sign-In

1. In [Firebase Console](https://console.firebase.google.com), use Android app package name **`com.remiminder.app.dev`** (or register it if missing).
2. Download `google-services.json` to `apps/mobile/android/app/google-services.json` (gitignored).
3. Add the release SHA-1 and SHA-256 fingerprints from your release keystore to Firebase (Project settings → Your apps → Android).
4. Ensure Google Sign-In OAuth client IDs include the production package name.

Get fingerprints:

```bash
keytool -list -v -keystore ~/remiminder-release.keystore -alias remiminder
```

## 4. Build release AAB

```bash
cd apps/mobile
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to Google Play Console.

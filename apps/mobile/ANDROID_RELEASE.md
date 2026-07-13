# Android release signing (Google Play)

Play / Android package ID: **`com.remiminderai.app`**

## 1. Create a release keystore (once)

```bash
cd apps/mobile/android/app
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -dname "CN=Paramita Malakar, OU=Mobile, O=RemiMinderAI, C=US"
```

Keep the keystore and passwords secure. **Never commit** the keystore or `key.properties`.

## 2. Configure signing locally

Create `apps/mobile/android/key.properties` (gitignored):

```bash
cp apps/mobile/android/key.properties.example apps/mobile/android/key.properties
```

Edit `key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

`storeFile` is relative to `android/app/` (where `upload-keystore.jks` lives).  
`apps/mobile/android/app/build.gradle.kts` reads `android/key.properties` automatically. Without it, release builds fall back to debug signing (rejected by Play Console).

## 3. Firebase / Google Sign-In

1. In [Firebase Console](https://console.firebase.google.com), register Android app package name **`com.remiminderai.app`**.
2. Download `google-services.json` to `apps/mobile/android/app/google-services.json` (gitignored).
3. Add the release SHA-1 and SHA-256 fingerprints from your upload keystore to Firebase.
4. Ensure Google Sign-In OAuth clients include the production package name.

Get fingerprints:

```bash
keytool -list -v -keystore apps/mobile/android/app/upload-keystore.jks -alias upload
```

## 4. Build release AAB

```bash
cd apps/mobile
flutter clean
flutter pub get
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to Google Play Console.

## Verify signing (not debug)

```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab | head -40
```

Look for your upload certificate CN (`Paramita Malakar` / `RemiMinderAI`), not Android Debug.

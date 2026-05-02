plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.remiminder.app.dev"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.remiminder.app.dev"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true

        // Google Sign-In Configuration
        manifestPlaceholders["appAuthRedirectScheme"] = "com.remiminder.app.dev"
    }

    signingConfigs {
        create("release") {
            // CI passes credentials via env (see .github/workflows/build.yml).
            val ksPath =
                System.getenv("ANDROID_UPLOAD_KEYSTORE_FILE")?.takeIf { it.isNotBlank() }
                    ?: "upload-keystore.jks"
            storeFile = file(ksPath)
            storePassword =
                System.getenv("KEYSTORE_STORE_PASSWORD")?.takeIf { it.isNotBlank() }
                    ?: "rrRR123!@#"
            keyAlias =
                System.getenv("KEYSTORE_ALIAS")?.takeIf { it.isNotBlank() } ?: "upload"
            keyPassword =
                System.getenv("KEYSTORE_KEY_PASSWORD")?.takeIf { it.isNotBlank() }
                    ?: "rrRR123!@#"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

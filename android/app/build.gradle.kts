plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The single source of truth for the application id lives in android/gradle.properties
// (dipiAppId). Change it there only. The Kotlin namespace stays fixed at
// com.yourname.dipi so no source files have to move.
val dipiAppId: String = (project.findProperty("dipiAppId") as String?) ?: "com.yourname.dipi"

// Optional NDK override (see android/gradle.properties).
val dipiNdkVersion: String = (project.findProperty("dipiNdkVersion") as String?).orEmpty().trim()

android {
    namespace = "com.yourname.dipi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = dipiNdkVersion.ifEmpty { flutter.ndkVersion }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Change the application id in android/gradle.properties (dipiAppId) — one place only.
        applicationId = dipiAppId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

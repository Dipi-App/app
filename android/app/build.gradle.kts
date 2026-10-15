import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException

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

// ---------------------------------------------------------------------------
// Release signing.
//
// The release keystore and its passwords are read from, in order:
//   1. environment variables (used by CI):
//        DIPI_KEYSTORE_FILE, DIPI_KEYSTORE_PASSWORD, DIPI_KEY_ALIAS,
//        DIPI_KEY_PASSWORD
//   2. android/key.properties (local builds; git-ignored)
//
// A release build is NEVER signed with the debug key. If no release signing is
// configured, a release build fails loudly instead of silently producing a
// debug-signed APK that could never update an installed release.
// ---------------------------------------------------------------------------
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

fun signingValue(envName: String, propertyName: String): String? {
    val fromEnv = System.getenv(envName)?.trim()
    if (!fromEnv.isNullOrEmpty()) return fromEnv
    return keystoreProperties.getProperty(propertyName)?.trim()?.ifEmpty { null }
}

val releaseStoreFile = signingValue("DIPI_KEYSTORE_FILE", "storeFile")
val releaseStorePassword = signingValue("DIPI_KEYSTORE_PASSWORD", "storePassword")
val releaseKeyAlias = signingValue("DIPI_KEY_ALIAS", "keyAlias")
val releaseKeyPassword = signingValue("DIPI_KEY_PASSWORD", "keyPassword")
val hasReleaseSigning = listOf(
    releaseStoreFile,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrEmpty() }

// Fail before compiling anything when a release build lacks a real key.
val buildingRelease =
    gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }
if (buildingRelease && !hasReleaseSigning) {
    throw GradleException(
        "Release signing is not configured. Set the environment variables " +
            "DIPI_KEYSTORE_FILE, DIPI_KEYSTORE_PASSWORD, DIPI_KEY_ALIAS and " +
            "DIPI_KEY_PASSWORD (CI) or create android/key.properties (local). " +
            "Release builds are never signed with the debug key.",
    )
}

android {
    namespace = "com.yourname.dipi"
    // Latest stable Android API level (Android 16) for both the SDK the app is
    // compiled against and the behaviour it opts into.
    compileSdk = 36
    ndkVersion = dipiNdkVersion.ifEmpty { flutter.ndkVersion }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Change the application id in android/gradle.properties (dipiAppId) — one place only.
        applicationId = dipiAppId
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                // Modern APK signature schemes. minSdk is 24, so the legacy v1
                // (JAR) signature is not needed; v2 + v3 cover every device the
                // app supports.
                enableV1Signing = false
                enableV2Signing = true
                enableV3Signing = true
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
            // R8: shrink unused code and resources. The app loads no code at
            // runtime, so full shrinking is safe.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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

# R8 / ProGuard rules for Dipi release builds.
#
# R8 shrinking (isMinifyEnabled) and resource shrinking are on for release.
# The Flutter engine is reached through JNI, so its classes must be kept.

# --- Flutter engine -------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# --- AndroidX WorkManager (background auto-backup) ------------------------
# WorkManager instantiates workers reflectively from the manifest.
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-keepclassmembers class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

# --- Google Play Core (deferred components) -------------------------------
# Flutter's embedding references Play Core for deferred components, which Dipi
# does not use. Silence R8 so shrinking can proceed; the classes are never
# reached at runtime.
-dontwarn com.google.android.play.core.**

# --- Kotlin metadata ------------------------------------------------------
-keepclassmembers class **$WhenMappings { <fields>; }
-keepattributes *Annotation*, InnerClasses, Signature, RuntimeVisibleAnnotations

# Flutter embedding is referenced by the generated plugin registrant.
-keep class io.flutter.embedding.engine.plugins.shim.** { *; }

package com.yourname.dipi

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Used by the in-app update flow (see lib/features/app_update and
    // ApkUpdates.kt). The APK is verified before Android's installer sees it;
    // the user still confirms the install.
    private val updateChannel = "dipi/update"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            updateChannel,
        )
        ApkUpdates.attach(channel)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url.isNullOrBlank()) {
                        result.error("bad_args", "url is required", null)
                    } else {
                        result.success(openUrl(url))
                    }
                }
                "canInstall" -> result.success(ApkUpdates.canInstall(this))
                "openInstallSettings" -> result.success(ApkUpdates.openInstallSettings(this))
                "supportedAbi" -> result.success(ApkUpdates.supportedAbi())
                "installUpdate" -> {
                    val url = call.argument<String>("url")
                    val version = call.argument<String>("version")
                    val sha256 = call.argument<String>("sha256")
                    if (url.isNullOrBlank() || version.isNullOrBlank()) {
                        result.error("bad_args", "url and version are required", null)
                    } else {
                        ApkUpdates.requestNotificationPermission(this)
                        result.success(ApkUpdates.start(this, url, version, sha256))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        ApkUpdates.setVisible(true)
    }

    override fun onPause() {
        ApkUpdates.setVisible(false)
        super.onPause()
    }

    override fun onDestroy() {
        ApkUpdates.detach()
        super.onDestroy()
    }

    /** Hands a web link to the system browser. Returns false when nothing can. */
    private fun openUrl(url: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }
}

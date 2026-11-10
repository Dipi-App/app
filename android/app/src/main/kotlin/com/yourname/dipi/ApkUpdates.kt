package com.yourname.dipi

import android.Manifest
import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageInstaller
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

/**
 * In-app update for the GitHub APK, following the same rules as Shroudly:
 * download only after the user taps install, verify that the file is this
 * package, newer, and signed with this install's certificate, then let
 * Android's installer ask the user. Nothing is installed silently.
 */
object ApkUpdates {
    private const val MAX_BYTES = 120L * 1024 * 1024
    private const val MAX_REDIRECTS = 5
    private const val CHANNEL_ID = "dipi_updates"
    private const val NOTICE_ID = 41
    private const val NOTIFICATION_PERMISSION_REQUEST = 71
    const val EXTRA_VERSION = "version"

    private val allowedHosts = setOf(
        "github.com",
        "www.github.com",
        "objects.githubusercontent.com",
        "github-releases.githubusercontent.com",
        "release-assets.githubusercontent.com",
    )

    private var channel: MethodChannel? = null

    @Volatile
    private var running = false

    @Volatile
    private var visible = false

    fun attach(methodChannel: MethodChannel) {
        channel = methodChannel
    }

    fun detach() {
        channel = null
    }

    fun setVisible(value: Boolean) {
        visible = value
    }

    fun supportedAbi(): String = Build.SUPPORTED_ABIS.firstOrNull().orEmpty()

    fun canInstall(context: Context): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.packageManager.canRequestPackageInstalls()
        } else {
            true
        }

    fun openInstallSettings(context: Context): Boolean = try {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            true
        } else {
            context.startActivity(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:${context.packageName}"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            true
        }
    } catch (_: Exception) {
        false
    }

    /** Android 13+ hides the fallback notification without this permission. */
    fun requestNotificationPermission(activity: Activity) {
        if (Build.VERSION.SDK_INT < 33) return
        if (activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        try {
            activity.requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_REQUEST,
            )
        } catch (_: Exception) {
            // The download still works; only the background notice is lost.
        }
    }

    fun start(context: Context, url: String, version: String, sha256: String?): Boolean {
        if (running) return false
        val initial = Uri.parse(url)
        if (initial.scheme != "https" || initial.host !in allowedHosts) return false
        if (version.isBlank()) return false

        running = true
        val app = context.applicationContext
        Thread({ run(app, url, version, sha256.orEmpty()) }, "dipi-update").apply {
            isDaemon = true
        }.start()
        return true
    }

    private fun run(context: Context, url: String, version: String, sha256: String) {
        val dir = File(context.cacheDir, "update").apply { mkdirs() }
        dir.listFiles()?.forEach { it.delete() }
        val file = File(dir, "dipi-$version.apk")
        try {
            emit("downloading", 0, version)
            fetch(url, file) { done, total ->
                val percent = if (total > 0) ((done * 100) / total).toInt() else 0
                emit("downloading", percent, version)
            }
            emit("verifying", 100, version)
            if (sha256.isNotEmpty() && !shaMatches(file, sha256)) {
                emit("failed", 100, version, "فایل دانلودشده سالم نیست. دوباره تلاش کن.")
                return
            }
            if (!verified(context, file)) {
                emit(
                    "failed",
                    100,
                    version,
                    "این فایل دیپی نیست، تازه‌تر نیست، یا امضای آن با نسخه نصب‌شده یکی نیست.",
                )
                return
            }
            install(context, file, version)
            emit("waiting", 100, version)
        } catch (_: Exception) {
            emit(
                "failed",
                0,
                version,
                "دانلود یا نصب انجام نشد. اتصال اینترنت را بررسی کن و دوباره تلاش کن.",
            )
        } finally {
            running = false
            file.delete()
        }
    }

    private fun fetch(
        url: String,
        file: File,
        progress: (Long, Long) -> Unit,
    ) {
        var current = url
        var hops = 0
        while (true) {
            val parsed = URL(current)
            if (parsed.protocol != "https" || parsed.host !in allowedHosts) {
                throw IOException("blocked host")
            }
            val connection = parsed.openConnection() as HttpURLConnection
            try {
                connection.instanceFollowRedirects = false
                connection.connectTimeout = 15000
                connection.readTimeout = 20000
                connection.setRequestProperty("User-Agent", "dipi-android-updater")
                val status = connection.responseCode
                if (status in 300..399) {
                    val location = connection.getHeaderField("Location")
                        ?: throw IOException("redirect without location")
                    current = URL(parsed, location).toString()
                    hops += 1
                    if (hops > MAX_REDIRECTS) throw IOException("too many redirects")
                    continue
                }
                if (status != 200) throw IOException("HTTP $status")
                val total = connection.contentLengthLong
                if (total > MAX_BYTES) throw IOException("file too large")
                connection.inputStream.use { input ->
                    file.outputStream().use { output ->
                        val buffer = ByteArray(64 * 1024)
                        var done = 0L
                        while (true) {
                            val read = input.read(buffer)
                            if (read < 0) break
                            done += read
                            if (done > MAX_BYTES) throw IOException("file too large")
                            output.write(buffer, 0, read)
                            progress(done, total)
                        }
                        output.flush()
                        if (total >= 0 && done != total) throw IOException("cut short")
                    }
                }
                return
            } finally {
                connection.disconnect()
            }
        }
    }

    private fun shaMatches(file: File, expected: String): Boolean {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buffer = ByteArray(64 * 1024)
            while (true) {
                val read = input.read(buffer)
                if (read < 0) break
                digest.update(buffer, 0, read)
            }
        }
        val actual = digest.digest().joinToString("") { "%02x".format(it) }
        return actual.equals(expected.trim(), ignoreCase = true)
    }

    @Suppress("DEPRECATION")
    private fun flags(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            // Both flags, like Shroudly: signingInfo is preferred below, and
            // signatures stay populated for devices that use the fallback.
            PackageManager.GET_SIGNING_CERTIFICATES or PackageManager.GET_SIGNATURES
        } else {
            PackageManager.GET_SIGNATURES
        }

    @Suppress("DEPRECATION")
    private fun signers(info: PackageInfo?): Set<String> {
        if (info == null) return emptySet()
        val certificates =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && info.signingInfo != null) {
                info.signingInfo!!.apkContentsSigners
            } else {
                info.signatures
            }
        return certificates
            ?.filterNotNull()
            ?.map {
                MessageDigest.getInstance("SHA-256")
                    .digest(it.toByteArray())
                    .joinToString("") { byte -> "%02x".format(byte) }
            }
            ?.toSet()
            .orEmpty()
    }

    @Suppress("DEPRECATION")
    private fun versionCode(info: PackageInfo?): Long =
        when {
            info == null -> -1L
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.P -> info.longVersionCode
            else -> info.versionCode.toLong()
        }

    private fun verified(context: Context, file: File): Boolean {
        val manager = context.packageManager
        val archive = try {
            manager.getPackageArchiveInfo(file.path, flags())
        } catch (_: Exception) {
            null
        }
        val installed = try {
            manager.getPackageInfo(context.packageName, flags())
        } catch (_: Exception) {
            null
        }
        if (archive?.packageName != context.packageName) return false
        if (versionCode(archive) <= versionCode(installed)) return false
        val own = signers(installed)
        return own.isNotEmpty() && own == signers(archive)
    }

    private fun install(context: Context, file: File, version: String) {
        val installer = context.packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(
            PackageInstaller.SessionParams.MODE_FULL_INSTALL,
        ).apply {
            setAppPackageName(context.packageName)
            setSize(file.length())
            setInstallReason(PackageManager.INSTALL_REASON_USER)
        }
        val sessionId = installer.createSession(params)
        installer.openSession(sessionId).use { session ->
            session.openWrite("dipi-$version.apk", 0, file.length()).use { output ->
                file.inputStream().use { input -> input.copyTo(output) }
                session.fsync(output)
            }
            val callback = Intent(context, UpdateInstallReceiver::class.java)
                .setPackage(context.packageName)
                .putExtra(EXTRA_VERSION, version)
            val mutable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_MUTABLE
            } else {
                0
            }
            val pending = PendingIntent.getBroadcast(
                context,
                sessionId,
                callback,
                PendingIntent.FLAG_UPDATE_CURRENT or mutable,
            )
            session.commit(pending.intentSender)
        }
    }

    fun confirm(context: Context, version: String, confirm: Intent) {
        val app = context.applicationContext
        confirm.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (visible) {
            try {
                app.startActivity(confirm)
                return
            } catch (_: Exception) {
                // Fall through to a notification.
            }
        }
        notifyReady(app, version, confirm)
    }

    fun failed(version: String, message: String?) {
        emit("failed", 0, version, message ?: "نصب انجام نشد.")
    }

    fun installed(version: String) {
        emit("installed", 100, version)
    }

    private fun notifyReady(context: Context, version: String, confirm: Intent) {
        try {
            val manager = context.getSystemService(NotificationManager::class.java) ?: return
            if (Build.VERSION.SDK_INT >= 33 &&
                context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                return
            }
            val pending = PendingIntent.getActivity(
                context,
                NOTICE_ID,
                confirm,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                manager.createNotificationChannel(
                    NotificationChannel(
                        CHANNEL_ID,
                        "نصب به‌روزرسانی دیپی",
                        NotificationManager.IMPORTANCE_DEFAULT,
                    ),
                )
                Notification.Builder(context, CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context)
            }
            manager.notify(
                NOTICE_ID,
                builder
                    .setSmallIcon(android.R.drawable.stat_sys_download_done)
                    .setContentTitle("نسخه $version آماده نصب است")
                    .setContentText("برای نصب، همین اعلان را بزن.")
                    .setContentIntent(pending)
                    .setAutoCancel(true)
                    .build(),
            )
        } catch (_: Exception) {
            // The in-app dialog still says the install is waiting.
        }
    }

    private fun emit(
        stage: String,
        percent: Int,
        version: String,
        message: String? = null,
    ) {
        Handler(Looper.getMainLooper()).post {
            channel?.invokeMethod(
                "installProgress",
                hashMapOf(
                    "stage" to stage,
                    "percent" to percent,
                    "version" to version,
                    "message" to message,
                ),
            )
        }
    }
}

/** What Android's installer did with the update. */
class UpdateInstallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val version = intent.getStringExtra(ApkUpdates.EXTRA_VERSION).orEmpty()
        when (intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                val confirm = if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_INTENT)
                }
                if (confirm == null) {
                    ApkUpdates.failed(version, "پنجره نصب اندروید باز نشد.")
                } else {
                    ApkUpdates.confirm(context, version, confirm)
                }
            }
            PackageInstaller.STATUS_SUCCESS -> ApkUpdates.installed(version)
            else -> ApkUpdates.failed(
                version,
                "نصب لغو شد یا انجام نشد. دوباره تلاش کن.",
            )
        }
    }
}

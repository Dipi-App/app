package ir.dipi.dipi_documents

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Writes JSON backups into the shared `Documents/dipi` folder through
 * `MediaStore`, so no storage permission is needed on Android 10 (API 29) and
 * newer. Publishing uses `IS_PENDING` so a half-written file is never visible.
 */
class DipiDocumentsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "dipi_documents")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveBackup" -> handleSave(call, result)
            "listBackups" -> handleList(result)
            "readBackup" -> handleRead(call, result)
            "hasAllFilesAccess" -> result.success(hasAllFilesAccess())
            "openAllFilesSettings" -> openAllFilesSettings(result)
            else -> result.notImplemented()
        }
    }

    /**
     * Whether this install may read files it did not write. Android 11 hides
     * them, and a reinstall's old backups are in exactly that group.
     */
    private fun hasAllFilesAccess(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.R ||
            Environment.isExternalStorageManager()

    /**
     * Opens the system "All files access" page for this app. There is no dialog
     * to answer here: the platform only lets the user turn it on in Settings,
     * so the caller waits for the app to come back to the foreground.
     */
    private fun openAllFilesSettings(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            result.success(false)
            return
        }
        val packageUri = Uri.parse("package:${context.packageName}")
        val candidates = listOf(
            Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, packageUri),
            Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION),
        )
        for (intent in candidates) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                context.startActivity(intent)
                result.success(true)
                return
            } catch (error: Exception) {
                // Some builds ship only the generic screen.
            }
        }
        result.success(false)
    }

    private fun handleRead(call: MethodCall, result: MethodChannel.Result) {
        val uriValue = call.argument<String>("uri")
        if (uriValue == null) {
            result.error("bad_args", "uri is required", null)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success(null)
            return
        }
        val text = try {
            read(Uri.parse(uriValue))
        } catch (error: Exception) {
            // A file written by an earlier install may no longer be readable.
            null
        }
        result.success(text)
    }

    private fun read(uri: Uri): String? = when (uri.scheme) {
        "file" -> File(uri.path ?: return null).takeIf { it.isFile }?.readText()
        else -> context.contentResolver.openInputStream(uri)?.use { input ->
            String(input.readBytes(), Charsets.UTF_8)
        }
    }

    private fun handleSave(call: MethodCall, result: MethodChannel.Result) {
        val tempPath = call.argument<String>("tempPath")
        val fileName = call.argument<String>("fileName")
        val keep = call.argument<Int>("keep") ?: 10
        if (tempPath == null || fileName == null) {
            result.error("bad_args", "tempPath and fileName are required", null)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error(
                "unsupported",
                "Writing to Documents needs Android 10 or newer.",
                null,
            )
            return
        }
        try {
            result.success(save(tempPath, fileName, keep))
        } catch (error: Exception) {
            result.error("save_failed", error.message ?: "save failed", null)
        }
    }

    private fun collection(): Uri =
        MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)

    private fun relativePath(): String = "${Environment.DIRECTORY_DOCUMENTS}/$FOLDER"

    private fun save(tempPath: String, fileName: String, keep: Int): Map<String, Any?> {
        val source = File(tempPath)
        val bytes = source.readBytes()
        val resolver = context.contentResolver

        // Replace a file with the same name instead of failing on a conflict.
        findExisting(fileName)?.let { resolver.delete(it, null, null) }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, "application/json")
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath())
            // Hide the row until the contents are fully written.
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(collection(), values)
            ?: throw IllegalStateException("MediaStore insert failed")

        try {
            resolver.openOutputStream(uri, "w")?.use { out ->
                out.write(bytes)
                out.flush()
            } ?: throw IllegalStateException("Could not open the output stream")
            val done = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            resolver.update(uri, done, null, null)
        } catch (error: Exception) {
            resolver.delete(uri, null, null)
            throw error
        } finally {
            source.delete()
        }

        prune(keep)
        return mapOf("name" to fileName, "size" to bytes.size, "uri" to uri.toString())
    }

    private fun findExisting(fileName: String): Uri? {
        val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} = ? AND " +
            "${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?"
        val args = arrayOf(fileName, "${relativePath()}/%")
        context.contentResolver
            .query(collection(), arrayOf(MediaStore.MediaColumns._ID), selection, args, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    return ContentUris.withAppendedId(collection(), cursor.getLong(0))
                }
            }
        return null
    }

    private fun handleList(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }
        try {
            result.success(list())
        } catch (error: Exception) {
            result.error("list_failed", error.message ?: "list failed", null)
        }
    }

    private fun list(): List<Map<String, Any?>> {
        val found = linkedMapOf<String, Map<String, Any?>>()
        for (row in fromMediaStore()) found[row["name"] as String] = row
        // A reinstall that has just been given "All files access" may still see
        // its own rows only: the platform applies that permission to a process
        // when it starts. Reading the folder itself is the second opinion.
        if (hasAllFilesAccess()) {
            val documents = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOCUMENTS,
            )
            File(documents, FOLDER).listFiles { file ->
                file.isFile && file.name.startsWith(PREFIX)
            }?.forEach { file ->
                found.putIfAbsent(
                    file.name,
                    mapOf(
                        "name" to file.name,
                        "size" to file.length(),
                        "uri" to Uri.fromFile(file).toString(),
                    ),
                )
            }
        }
        return found.values.sortedByDescending { it["name"] as String }
    }

    private fun fromMediaStore(): List<Map<String, Any?>> {
        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.SIZE,
        )
        val selection = "${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?"
        val args = arrayOf("${relativePath()}/%")
        val found = mutableListOf<Map<String, Any?>>()
        context.contentResolver
            .query(collection(), projection, selection, args, null)
            ?.use { cursor ->
                val idIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                val nameIndex =
                    cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
                val sizeIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
                while (cursor.moveToNext()) {
                    val id = cursor.getLong(idIndex)
                    found.add(
                        mapOf(
                            "name" to cursor.getString(nameIndex),
                            "size" to cursor.getLong(sizeIndex),
                            "uri" to ContentUris.withAppendedId(collection(), id).toString(),
                        ),
                    )
                }
            }
        found.sortByDescending { it["name"] as String }
        return found
    }

    /** Keeps the [keep] newest `dipi_backup_*` files and deletes the rest. */
    private fun prune(keep: Int) {
        if (keep <= 0) return
        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
        )
        val selection = "${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ? AND " +
            "${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ?"
        val args = arrayOf("${relativePath()}/%", "${PREFIX}%")
        val rows = mutableListOf<Pair<String, Long>>()
        context.contentResolver
            .query(collection(), projection, selection, args, null)
            ?.use { cursor ->
                val idIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                val nameIndex =
                    cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
                while (cursor.moveToNext()) {
                    rows.add(cursor.getString(nameIndex) to cursor.getLong(idIndex))
                }
            }
        // Newest first: the name carries YYYYMMDD_HHmm, so text order is time order.
        rows.sortByDescending { it.first }
        for (index in keep until rows.size) {
            context.contentResolver.delete(
                ContentUris.withAppendedId(collection(), rows[index].second),
                null,
                null,
            )
        }
    }

    companion object {
        private const val FOLDER = "dipi"
        private const val PREFIX = "dipi_backup_"
    }
}

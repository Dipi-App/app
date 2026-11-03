import 'package:flutter/services.dart';

/// A file written to the shared `Documents/dipi` folder.
class SavedDocument {
  const SavedDocument({
    required this.fileName,
    required this.sizeInBytes,
    this.uri,
  });

  final String fileName;
  final int sizeInBytes;
  final String? uri;

  factory SavedDocument.fromMap(Map<Object?, Object?> map) => SavedDocument(
    fileName: (map['name'] as String?) ?? '',
    sizeInBytes: (map['size'] as num?)?.toInt() ?? 0,
    uri: map['uri'] as String?,
  );
}

/// Small helper around Android's `MediaStore` for writing files into
/// `Documents/dipi` without any storage permission (Android 10+).
class DipiDocuments {
  const DipiDocuments._();

  static const MethodChannel _channel = MethodChannel('dipi_documents');

  /// Folder under `Documents` that backups go into.
  static const String folderName = 'dipi';

  /// Copies the file at [tempPath] to `Documents/dipi/[fileName]`, then keeps
  /// at most [keep] backups (newest first) and deletes the older ones.
  static Future<SavedDocument> saveBackup({
    required String tempPath,
    required String fileName,
    int keep = 10,
  }) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'saveBackup',
      {'tempPath': tempPath, 'fileName': fileName, 'keep': keep},
    );
    if (result == null) {
      throw PlatformException(
        code: 'save_failed',
        message: 'ذخیره‌ی فایل پشتیبان انجام نشد.',
      );
    }
    return SavedDocument.fromMap(result);
  }

  /// Backups currently in `Documents/dipi`, newest first. Each entry carries the
  /// [SavedDocument.uri] needed to read the file back.
  static Future<List<SavedDocument>> listBackups() async {
    final raw = await _channel.invokeListMethod<Object?>('listBackups');
    if (raw == null) return const [];
    return [
      for (final item in raw)
        if (item is Map) SavedDocument.fromMap(item.cast<Object?, Object?>()),
    ];
  }

  /// Reads the file at [uri] as text, or null when it cannot be read.
  ///
  /// On Android 11 and newer a reinstall cannot see files written by the
  /// install it replaced — they belong to no app any more, and neither a
  /// MediaStore query nor the system file picker reaches them. Granting
  /// [hasAllFilesAccess] is the only way back.
  static Future<String?> readBackup(String uri) => _channel.invokeMethod<String>(
    'readBackup',
    {'uri': uri},
  );

  /// Whether this install may read files it did not write itself. True on
  /// Android 10 and older, where the question does not arise.
  static Future<bool> hasAllFilesAccess() async =>
      await _channel.invokeMethod<bool>('hasAllFilesAccess') ?? true;

  /// Opens the system "All files access" page for this app. Returns false when
  /// the platform has no such screen to show.
  static Future<bool> openAllFilesSettings() async =>
      await _channel.invokeMethod<bool>('openAllFilesSettings') ?? false;
}

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
    int keep = 14,
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

  /// Backups currently in `Documents/dipi`, newest first.
  static Future<List<SavedDocument>> listBackups() async {
    final raw = await _channel.invokeListMethod<Object?>('listBackups');
    if (raw == null) return const [];
    return [
      for (final item in raw)
        if (item is Map) SavedDocument.fromMap(item.cast<Object?, Object?>()),
    ];
  }
}

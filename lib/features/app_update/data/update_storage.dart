import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/release_asset.dart';

/// A download on disk (possibly only partial) and its metadata.
class StoredUpdate {
  const StoredUpdate({
    required this.tag,
    required this.version,
    required this.notes,
    required this.apkName,
    required this.url,
    required this.checksumUrl,
    required this.expectedBytes,
    required this.expectedSha,
    required this.complete,
    required this.apkFile,
    required this.metaFile,
  });

  final String tag;
  final String version;
  final String notes;
  final String apkName;
  final String url;
  final String checksumUrl;
  final int expectedBytes;

  /// The verified SHA-256, kept so the install can be re-checked offline.
  final String expectedSha;

  /// True once the file has been hash-checked and is safe to install.
  final bool complete;

  final File apkFile;
  final File metaFile;

  int get existingBytes => apkFile.existsSync() ? apkFile.lengthSync() : 0;

  bool get filePresent => apkFile.existsSync() && apkFile.lengthSync() > 0;
}

/// Keeps the APK and its metadata in an app-private folder. Never a public one.
///
/// The folder lives under the app's external files dir when available (so a
/// ~50 MB APK does not eat internal storage), falling back to app support or
/// cache. Files are named after the version and ABI, so only one update is
/// ever kept.
class UpdateStorage {
  static const String _dirName = 'dipi-update';
  static const String _metaName = 'update-meta.json';

  Directory? _cached;

  Future<Directory> directory() async {
    final cached = _cached;
    if (cached != null) return cached;
    final base = await _baseDirectory();
    final dir = Directory(p.join(base.path, _dirName));
    if (!dir.existsSync()) await dir.create(recursive: true);
    _cached = dir;
    return dir;
  }

  Future<Directory> _baseDirectory() async {
    try {
      final external = await getExternalStorageDirectory();
      if (external != null) return external;
    } catch (_) {}
    try {
      return await getApplicationSupportDirectory();
    } catch (_) {}
    return getTemporaryDirectory();
  }

  Future<File> _metaFile() async =>
      File(p.join((await directory()).path, _metaName));

  /// Prepares storage for [apk], deleting files from any other version, and
  /// returns the (maybe partial) download to continue.
  Future<StoredUpdate> begin({
    required String tag,
    required String version,
    required String notes,
    required ReleaseAsset apk,
    required ReleaseAsset? checksum,
  }) async {
    final dir = await directory();
    await _deleteOthers(dir, keepApkName: apk.name);
    final apkFile = File(p.join(dir.path, apk.name));
    final metaFile = File(p.join(dir.path, _metaName));
    final update = StoredUpdate(
      tag: tag,
      version: version,
      notes: notes,
      apkName: apk.name,
      url: apk.downloadUrl,
      checksumUrl: checksum?.downloadUrl ?? '',
      expectedBytes: apk.sizeInBytes,
      expectedSha: '',
      complete: false,
      apkFile: apkFile,
      metaFile: metaFile,
    );
    await _writeMeta(update);
    return update;
  }

  /// Records that the file passed its hash check.
  Future<void> markVerified(StoredUpdate update, String expectedSha) =>
      _writeMeta(update, complete: true, expectedSha: expectedSha);

  Future<void> _writeMeta(
    StoredUpdate update, {
    bool complete = false,
    String? expectedSha,
  }) async {
    await update.metaFile.writeAsString(
      jsonEncode({
        'tag': update.tag,
        'version': update.version,
        'notes': update.notes,
        'apkName': update.apkName,
        'url': update.url,
        'checksumUrl': update.checksumUrl,
        'expectedBytes': update.expectedBytes,
        'expectedSha': expectedSha ?? update.expectedSha,
        'complete': complete || update.complete,
      }),
      flush: true,
    );
  }

  /// Reads the on-disk update, or null when there is none.
  Future<StoredUpdate?> loadPending() async {
    final metaFile = await _metaFile();
    if (!metaFile.existsSync()) return null;
    Map<String, Object?> json;
    try {
      json = (jsonDecode(await metaFile.readAsString()) as Map)
          .cast<String, Object?>();
    } catch (_) {
      await deleteAll();
      return null;
    }
    final apkName = json['apkName'] as String? ?? '';
    if (apkName.isEmpty) {
      await deleteAll();
      return null;
    }
    final dir = await directory();
    final apkFile = File(p.join(dir.path, apkName));
    if (!apkFile.existsSync() || apkFile.lengthSync() == 0) {
      await deleteAll();
      return null;
    }
    return StoredUpdate(
      tag: json['tag'] as String? ?? '',
      version: json['version'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      apkName: apkName,
      url: json['url'] as String? ?? '',
      checksumUrl: json['checksumUrl'] as String? ?? '',
      expectedBytes: (json['expectedBytes'] as num?)?.toInt() ?? 0,
      expectedSha: json['expectedSha'] as String? ?? '',
      complete: json['complete'] == true,
      apkFile: apkFile,
      metaFile: metaFile,
    );
  }

  Future<void> deleteAll() async {
    final dir = await directory();
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync()) {
      try {
        entity.deleteSync();
      } catch (_) {}
    }
  }

  Future<void> _deleteOthers(
    Directory dir, {
    required String keepApkName,
  }) async {
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name == _metaName) continue;
      if (name == keepApkName) continue;
      try {
        await entity.delete();
      } catch (_) {}
    }
  }
}

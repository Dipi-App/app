import 'dart:io';

import 'package:dipi_documents/dipi_documents.dart';
import 'package:flutter/services.dart'
    show MissingPluginException, PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/providers/database_providers.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/key_value_dao.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/state/settings_providers.dart';
import 'backup_repository.dart';

/// A backup that could not be written. [message] is shown to the user.
class LocalBackupException implements Exception {
  LocalBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalBackupResult {
  const LocalBackupResult({required this.fileName, required this.sizeInBytes});

  final String fileName;
  final int sizeInBytes;
}

/// How long between automatic backups, and how many files to keep.
const Duration autoBackupInterval = Duration(hours: 12);
const int autoBackupRetention = 14;

/// Writes one JSON backup into `Documents/dipi`.
///
/// This is a plain function on purpose: the workmanager background isolate has
/// no Riverpod scope, so it calls this directly with its own database.
Future<LocalBackupResult> runLocalBackup({AppDatabase? database}) async {
  final db = database ?? AppDatabase();
  final ownsDatabase = database == null;
  File? temp;
  try {
    final settings = AppSettings.fromMap(await KeyValueDao(db).all());
    final document = await BackupRepository(
      db,
    ).buildDocument(settings: settings.toMap());

    final tempDir = await getTemporaryDirectory();
    final name = AppInfo.autoBackupFileName(DateTime.now());
    temp = File(p.join(tempDir.path, '$name.tmp'));
    // Write fully to a temp file first, then let MediaStore publish it atomically.
    await temp.writeAsString(document.encodeForFile(), flush: true);

    final saved = await DipiDocuments.saveBackup(
      tempPath: temp.path,
      fileName: name,
      keep: autoBackupRetention,
    );
    await KeyValueDao(
      db,
    ).write('lastBackupAt', DateTime.now().toIso8601String());
    return LocalBackupResult(
      fileName: saved.fileName,
      sizeInBytes: saved.sizeInBytes,
    );
  } on PlatformException catch (error) {
    throw LocalBackupException(_describe(error));
  } on MissingPluginException {
    throw LocalBackupException('پشتیبان خودکار در این دستگاه پشتیبانی نمی‌شود.');
  } finally {
    if (temp != null && temp.existsSync()) {
      try {
        temp.deleteSync();
      } catch (_) {}
    }
    if (ownsDatabase) await db.close();
  }
}

String _describe(PlatformException error) => switch (error.code) {
  'unsupported' => 'پشتیبان خودکار روی اندروید ۱۰ و جدیدتر کار می‌کند.',
  _ => 'ذخیره‌ی فایل پشتیبان انجام نشد.',
};

/// Foreground entry point used by the button in the backup screen.
class LocalBackupService {
  LocalBackupService(this._ref);

  final Ref _ref;

  Future<LocalBackupResult> createBackup() async {
    final result = await runLocalBackup(
      database: _ref.read(databaseProvider),
    );
    await _ref
        .read(settingsControllerProvider.notifier)
        .setLastBackupAt(DateTime.now());
    return result;
  }
}

final localBackupServiceProvider = Provider<LocalBackupService>(
  (ref) => LocalBackupService(ref),
);

/// True when the last backup is missing or older than [autoBackupInterval].
bool isAutoBackupDue({required DateTime now, DateTime? lastBackup}) {
  if (lastBackup == null) return true;
  if (now.isBefore(lastBackup)) return true;
  return now.difference(lastBackup) >= autoBackupInterval;
}

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
  const LocalBackupResult({
    required this.fileName,
    required this.sizeInBytes,
    required this.created,
  });

  /// The data matched the last written backup, so nothing was created.
  const LocalBackupResult.skipped()
    : fileName = '',
      sizeInBytes = 0,
      created = false;

  final String fileName;
  final int sizeInBytes;

  /// False when the ledger matched the last backup and no file was written.
  final bool created;
}

/// How long between automatic backups, and how many files to keep.
const Duration autoBackupInterval = Duration(hours: 12);
const int autoBackupRetention = 10;

/// Key holding the fingerprint of the data in the newest written backup.
const String lastBackupFingerprintKey = 'lastBackupFingerprint';

/// Writes one JSON backup into `Documents/dipi`.
///
/// When the ledger produces the same fingerprint as the last written backup,
/// no file is created and the result reports [LocalBackupResult.created] false.
///
/// This is a plain function on purpose: the workmanager background isolate has
/// no Riverpod scope, so it calls this directly with its own database.
Future<LocalBackupResult> runLocalBackup({AppDatabase? database}) async {
  final db = database ?? AppDatabase();
  final ownsDatabase = database == null;
  File? temp;
  try {
    final dao = KeyValueDao(db);
    final settings = AppSettings.fromMap(await dao.all());
    final document = await BackupRepository(db)
        .buildDocument(settings: settings.toMap());

    final fingerprint = document.contentFingerprint;
    if (await dao.read(lastBackupFingerprintKey) == fingerprint) {
      return const LocalBackupResult.skipped();
    }

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
    await dao.write('lastBackupAt', DateTime.now().toIso8601String());
    await dao.write(lastBackupFingerprintKey, fingerprint);
    return LocalBackupResult(
      fileName: saved.fileName,
      sizeInBytes: saved.sizeInBytes,
      created: true,
    );
  } on PlatformException catch (error) {
    throw LocalBackupException(_describe(error));
  } on MissingPluginException {
    throw LocalBackupException(
      'پشتیبان خودکار در این دستگاه پشتیبانی نمی‌شود.',
    );
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
    final result = await runLocalBackup(database: _ref.read(databaseProvider));
    // A skipped run writes nothing, so the last-backup time must stay where it
    // is; the reminder and the 12-hour due check both read it.
    if (!result.created) return result;
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

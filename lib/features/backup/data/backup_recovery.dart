import 'package:dipi_documents/dipi_documents.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/providers/database_providers.dart';
import '../../settings/state/settings_providers.dart';
import '../domain/backup_document.dart';
import '../state/backup_providers.dart';
import 'backup_repository.dart';

/// Set once the user has answered the reinstall recovery offer, either way.
/// Lives in `key_values` and deliberately outside `AppSettings`, so it never
/// lands inside a backup and never looks like a data change.
const String backupRecoveryOfferedKey = 'backupRecoveryOffered';

/// The moment a backup was written, read back out of its file name.
DateTime? backupRecoveryFileNameDate(String fileName) {
  final digits = fileName.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 12) return null;
  return DateTime(
    int.parse(digits.substring(0, 4)),
    int.parse(digits.substring(4, 6)),
    int.parse(digits.substring(6, 8)),
    int.parse(digits.substring(8, 10)),
    int.parse(digits.substring(10, 12)),
  );
}

/// Whether to look for a backup left behind by an earlier install.
///
/// Onboarding alone is not enough: it stays true after the first setup, so a
/// user who deletes everything would be offered a restore every start.
bool shouldOfferBackupRecovery({
  required bool onboardingSeen,
  required int ledgerRowCount,
  required bool recoveryOffered,
}) =>
    onboardingSeen && ledgerRowCount == 0 && !recoveryOffered;

extension RecoverableBackups on List<SavedDocument> {
  /// Dipi backups only, newest first; the name carries `YYYYMMDD_HHmm`, so
  /// text order is time order.
  List<SavedDocument> newestFirst() =>
      (where((doc) => doc.fileName.startsWith(AppInfo.autoBackupPrefix)).toList())
        ..sort((a, b) => b.fileName.compareTo(a.fileName));
}

/// Whether a backup holds anything worth restoring.
///
/// A fresh install writes its own snapshot before this offer runs, so the
/// newest file is often an empty one — and restoring it would be a no-op.
bool backupHasLedgerData(BackupDocument document) =>
    document.employers.isNotEmpty ||
    document.workEntries.isNotEmpty ||
    document.payments.isNotEmpty;

/// A backup found on the device that the app can offer to restore.
class RecoverableBackup {
  const RecoverableBackup({
    required this.document,
    required this.fileName,
  });

  final BackupDocument document;
  final String fileName;

  int get employers => document.employers.length;
  int get workEntries => document.workEntries.length;
  int get payments => document.payments.length;
}

class BackupRecoveryService {
  BackupRecoveryService(this._ref);

  final Ref _ref;

  /// The newest backup in `Documents/dipi` that still holds data.
  ///
  /// Returns null when the folder is empty, every file is an empty snapshot, or
  /// the platform hides files left behind by an earlier install — which Android
  /// 11 does. Callers fall back to the system file picker in that case.
  Future<RecoverableBackup?> findRecoverableBackup() async {
    final found = (await DipiDocuments.listBackups()).newestFirst();
    for (final candidate in found) {
      final uri = candidate.uri;
      if (uri == null) continue;
      final source = await DipiDocuments.readBackup(uri);
      if (source == null) continue;
      try {
        final document = BackupDocument.decode(source);
        if (!backupHasLedgerData(document)) continue;
        return RecoverableBackup(document: document, fileName: candidate.fileName);
      } on BackupFormatException {
        // Not a Dipi backup, or from a newer schema: try the next file.
        continue;
      }
    }
    return null;
  }

  /// Imports [backup] and stops the offer from coming back.
  Future<ImportResult> restore(
    RecoverableBackup backup,
    ImportMode mode,
  ) async {
    final result = await _ref
        .read(backupRepositoryProvider)
        .import(document: backup.document, mode: mode);
    await markOffered();
    if (mode == ImportMode.replace && backup.document.settings.isNotEmpty) {
      await _ref
          .read(settingsControllerProvider.notifier)
          .applyImported(backup.document.settings);
    }
    return result;
  }

  Future<bool> alreadyOffered() async =>
      (await _ref.read(keyValueDaoProvider).read(backupRecoveryOfferedKey)) ==
      'true';

  Future<void> markOffered() =>
      _ref.read(keyValueDaoProvider).write(backupRecoveryOfferedKey, 'true');
}

final backupRecoveryServiceProvider = Provider<BackupRecoveryService>(
  (ref) => BackupRecoveryService(ref),
);

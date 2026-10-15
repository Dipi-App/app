import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../settings/state/settings_providers.dart';
import '../data/backup_repository.dart';

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => BackupRepository(ref.watch(databaseProvider)),
);

/// Whether the "no recent backup" reminder should be shown right now.
///
/// With the automatic local backup running every 12 hours this almost never
/// fires, but it still covers a user who disabled nothing and simply has an
/// empty ledger that has not been backed up yet.
final backupReminderProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsValueProvider);
  final lastBackup = settings.lastBackupDate;
  final lastReminder = settings.lastBackupReminderAt == null
      ? null
      : DateTime.tryParse(settings.lastBackupReminderAt!);

  const interval = Duration(days: 30);
  final stale =
      lastBackup == null || DateTime.now().difference(lastBackup) > interval;
  if (!stale) return false;
  if (lastReminder != null &&
      DateTime.now().difference(lastReminder) < const Duration(days: 3)) {
    return false;
  }
  return true;
});

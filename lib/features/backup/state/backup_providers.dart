import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../settings/state/settings_providers.dart';
import '../data/backup_repository.dart';
import '../data/drive_backup_service.dart';

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => BackupRepository(ref.watch(databaseProvider)),
);

final driveBackupServiceProvider = Provider<DriveBackupService>((ref) {
  final service = DriveBackupService();
  ref.onDispose(service.dispose);
  return service;
});

/// The Google account used only for Drive backup, or null when signed out.
class DriveSession extends AsyncNotifier<DriveAccount?> {
  @override
  Future<DriveAccount?> build() async {
    final service = ref.watch(driveBackupServiceProvider);
    if (!service.isConfigured) return null;
    return service.restoreSession();
  }

  Future<DriveAccount> signIn() async {
    final account = await ref.read(driveBackupServiceProvider).signIn();
    state = AsyncData(account);
    return account;
  }

  Future<void> signOut() async {
    await ref.read(driveBackupServiceProvider).signOut();
    state = const AsyncData(null);
  }
}

final driveSessionProvider =
    AsyncNotifierProvider<DriveSession, DriveAccount?>(DriveSession.new);

/// Metadata of the backup currently stored in Drive, if any.
final driveBackupInfoProvider = FutureProvider.autoDispose<DriveBackupInfo?>((
  ref,
) async {
  final session = ref.watch(driveSessionProvider).value;
  if (session == null) return null;
  return ref.watch(driveBackupServiceProvider).latestBackup();
});

/// Whether the "no recent backup" reminder should be shown right now.
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

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:workmanager/workmanager.dart';

import 'local_backup_service.dart';

/// Unique name for the periodic WorkManager task.
const String autoBackupTaskName = 'dipi-auto-backup';

/// Entry point WorkManager calls. Must stay a top-level function with the
/// `vm:entry-point` pragma so it survives tree-shaking in release builds.
@pragma('vm:entry-point')
void autoBackupCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != autoBackupTaskName) return true;
    try {
      await runLocalBackup();
      return true;
    } catch (_) {
      // Returning false asks WorkManager to retry with its backoff policy.
      return false;
    }
  });
}

/// Registers the 12-hour periodic backup. WorkManager persists it across
/// reboots. Safe to call on every start; the task is updated in place.
Future<void> initAutoBackupScheduler() async {
  if (kIsWeb || !Platform.isAndroid) return;
  try {
    await Workmanager().initialize(autoBackupCallbackDispatcher);
    await Workmanager().registerPeriodicTask(
      autoBackupTaskName,
      autoBackupTaskName,
      frequency: autoBackupInterval,
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  } catch (_) {
    // Scheduling must never block the app from starting.
  }
}

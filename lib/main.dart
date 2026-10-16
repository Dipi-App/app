import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/database_providers.dart';
import 'dev/demo_seeder.dart';
import 'features/backup/data/auto_backup_scheduler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Registers the 12-hour periodic backup; failures never block startup.
  unawaited(initAutoBackupScheduler());

  final container = ProviderContainer();
  if (kDemoMode) {
    // Demo builds only: fill an empty database so screenshots have data.
    // `kDemoMode` is a const false in normal builds, so this whole branch (and
    // the seeder library) is dropped by the compiler.
    await seedDemoData(container.read(databaseProvider));
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const DipiApp()),
  );
}

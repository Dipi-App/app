import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/backup/data/auto_backup_scheduler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Registers the 12-hour periodic backup; failures never block startup.
  unawaited(initAutoBackupScheduler());
  runApp(const ProviderScope(child: DipiApp()));
}

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/constants/app_info.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Employers, WorkEntries, Payments, KeyValues])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'dipi'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => AppInfo.schemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      await m.createAll();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

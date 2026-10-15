import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/db/employer_dao.dart';
import '../../data/db/key_value_dao.dart';
import '../../data/db/payment_dao.dart';
import '../../data/db/work_entry_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final keyValueDaoProvider = Provider<KeyValueDao>(
  (ref) => KeyValueDao(ref.watch(databaseProvider)),
);

final employerDaoProvider = Provider<EmployerDao>(
  (ref) => EmployerDao(ref.watch(databaseProvider)),
);

final workEntryDaoProvider = Provider<WorkEntryDao>(
  (ref) => WorkEntryDao(ref.watch(databaseProvider)),
);

final paymentDaoProvider = Provider<PaymentDao>(
  (ref) => PaymentDao(ref.watch(databaseProvider)),
);

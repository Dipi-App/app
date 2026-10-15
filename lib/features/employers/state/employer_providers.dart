import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../data/db/app_database.dart';

/// All employers, archived ones included. Archived employers still colour the
/// calendar for the days that were logged while they were active.
final employersProvider = StreamProvider<List<Employer>>(
  (ref) => ref.watch(employerDaoProvider).watchAll(includeArchived: true),
);

final activeEmployersProvider = Provider<List<Employer>>((ref) {
  final employers = ref.watch(employersProvider).value ?? const <Employer>[];
  return employers.where((employer) => !employer.isArchived).toList();
});

final employersByIdProvider = Provider<Map<int, Employer>>((ref) {
  final employers = ref.watch(employersProvider).value ?? const <Employer>[];
  return {for (final employer in employers) employer.id: employer};
});

final employerByIdProvider = StreamProvider.family<Employer?, int>(
  (ref, id) => ref.watch(employerDaoProvider).watchById(id),
);

final employerEntriesProvider = StreamProvider.family<List<WorkEntry>, int>(
  (ref, employerId) =>
      ref.watch(workEntryDaoProvider).watchForEmployer(employerId),
);

final archivedEmployersProvider = Provider<List<Employer>>((ref) {
  final employers = ref.watch(employersProvider).value ?? const <Employer>[];
  return employers.where((employer) => employer.isArchived).toList();
});

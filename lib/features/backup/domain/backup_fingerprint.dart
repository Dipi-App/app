/// Builds the stable text behind `BackupDocument.contentFingerprint`.
///
/// The export timestamp and the row `createdAt` values stay out of it, and so
/// do the settings keys in [volatileSettingKeys]: all of those move on their own
/// between two runs, so including them would make every backup look like new
/// data. `schemaVersion` and `appVersion` do count, so an upgrade always leaves
/// one snapshot of its own.
library;

/// Settings written by the app itself, not typed by the worker.
const Set<String> volatileSettingKeys = {
  'lastBackupAt',
  'lastBackupFingerprint',
  'lastBackupReminderAt',
  'lastUpdateCheckAt',
  'backupRecoveryOffered',
};

String _field(Object? value) => value?.toString() ?? '';

int _byId(Map<String, Object?> a, Map<String, Object?> b) =>
    _field(a['id']).compareTo(_field(b['id']));

/// The fingerprint input for one ledger snapshot. Rows are ordered by id, so
/// the result does not depend on the order the database returned them in.
String buildBackupFingerprintSource({
  required int schemaVersion,
  required String appVersion,
  required Iterable<Map<String, Object?>> employers,
  required Iterable<Map<String, Object?>> workEntries,
  required Iterable<Map<String, Object?>> payments,
  required Map<String, String> settings,
}) {
  List<Map<String, Object?>> sorted(Iterable<Map<String, Object?>> rows) =>
      rows.toList()..sort(_byId);

  final stableSettings = settings.keys
      .where((key) => !volatileSettingKeys.contains(key))
      .toList()
    ..sort();

  final parts = <String>[
    'V$schemaVersion|$appVersion',
    for (final row in sorted(employers))
      'E${_field(row['id'])}|${_field(row['name'])}|${_field(row['color'])}|'
          '${_field(row['phone'])}|${_field(row['note'])}|'
          '${_field(row['defaultWageType'])}|${_field(row['defaultDailyWage'])}|'
          '${_field(row['isArchived'])}',
    for (final row in sorted(workEntries))
      'W${_field(row['id'])}|${_field(row['employerId'])}|${_field(row['date'])}|'
          '${_field(row['place'])}|${_field(row['job'])}|'
          '${_field(row['startTime'])}|${_field(row['endTime'])}|'
          '${_field(row['wageType'])}|${_field(row['wageAmount'])}|'
          '${_field(row['outOfPocketAmount'])}|${_field(row['note'])}',
    for (final row in sorted(payments))
      'P${_field(row['id'])}|${_field(row['employerId'])}|${_field(row['date'])}|'
          '${_field(row['amount'])}|${_field(row['type'])}|${_field(row['note'])}',
    for (final key in stableSettings) 'S$key=${settings[key]}',
  ];
  return parts.join('\n');
}

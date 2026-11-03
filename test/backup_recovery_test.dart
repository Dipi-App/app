import 'package:dipi/features/backup/data/backup_recovery.dart';
import 'package:dipi/features/backup/domain/backup_document.dart';
import 'package:dipi_documents/dipi_documents.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldOfferBackupRecovery', () {
    test('a reinstall with backup files left behind is offered', () {
      expect(
        shouldOfferBackupRecovery(
          onboardingSeen: true,
          ledgerRowCount: 0,
          recoveryOffered: false,
        ),
        isTrue,
      );
    });

    test('the first setup is not interrupted', () {
      expect(
        shouldOfferBackupRecovery(
          onboardingSeen: false,
          ledgerRowCount: 0,
          recoveryOffered: false,
        ),
        isFalse,
      );
    });

    test('a ledger with data is never offered', () {
      expect(
        shouldOfferBackupRecovery(
          onboardingSeen: true,
          ledgerRowCount: 3,
          recoveryOffered: false,
        ),
        isFalse,
      );
    });

    test('asked once, never asked again', () {
      expect(
        shouldOfferBackupRecovery(
          onboardingSeen: true,
          ledgerRowCount: 0,
          recoveryOffered: true,
        ),
        isFalse,
      );
    });
  });

  group('newestFirst', () {
    test('sorts by the timestamp carried in the file name', () {
      final found = _docs([
        'dipi_backup_20261015_1130.json',
        'dipi_backup_20261102_0805.json',
        'dipi_backup_20261015_0940.json',
      ]).newestFirst();
      expect(
        found.map((doc) => doc.fileName),
        [
          'dipi_backup_20261102_0805.json',
          'dipi_backup_20261015_1130.json',
          'dipi_backup_20261015_0940.json',
        ],
      );
    });

    test('ignores unrelated files in the folder', () {
      final found = _docs([
        'notes.txt',
        'dipi_backup_20261015_1130.json',
      ]).newestFirst();
      expect(found.map((doc) => doc.fileName), [
        'dipi_backup_20261015_1130.json',
      ]);
    });

    test('a later minute of the same day is newer, not the other way round', () {
      // Real files from the emulator: the 20:17 one holds the data.
      final found = _docs([
        'dipi_backup_20261103_2013.json',
        'dipi_backup_20261103_2017.json',
      ]).newestFirst();
      expect(found.first.fileName, 'dipi_backup_20261103_2017.json');
    });

    test('compares by day before time', () {
      final found = _docs([
        'dipi_backup_20261102_2359.json',
        'dipi_backup_20261103_0001.json',
      ]).newestFirst();
      expect(found.first.fileName, 'dipi_backup_20261103_0001.json');
    });
  });

  group('backupHasLedgerData', () {
    test('the empty snapshot a fresh install writes is not restorable', () {
      expect(backupHasLedgerData(_document(employers: const [])), isFalse);
    });

    test('one employer is enough to offer', () {
      expect(backupHasLedgerData(_document()), isTrue);
    });
  });
}

List<SavedDocument> _docs(List<String> names) => [
  for (final name in names) SavedDocument(fileName: name, sizeInBytes: 1),
];

BackupDocument _document({List<int> employers = const [1]}) => BackupDocument(
  schemaVersion: BackupDocument.currentSchemaVersion,
  appVersion: '1.6.1',
  exportedAt: '2026-11-03T00:00:00.000',
  employers: [
    for (final id in employers)
      BackupEmployer(
        id: id,
        name: 'کارفرمای $id',
        color: 0xFF2E7D6F,
        defaultWageType: 'fixed',
        isArchived: false,
        createdAt: '2026-01-01T00:00:00.000',
      ),
  ],
  workEntries: const [],
  payments: const [],
  settings: const {},
);

import 'package:dipi/core/constants/app_info.dart';
import 'package:dipi/features/backup/data/local_backup_service.dart';
import 'package:dipi/features/backup/domain/backup_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('auto backup file name', () {
    test('uses dipi_backup_YYYYMMDD_HHmm.json', () {
      expect(
        AppInfo.autoBackupFileName(DateTime(2026, 3, 7, 9, 5)),
        'dipi_backup_20260307_0905.json',
      );
    });
  });

  group('isAutoBackupDue', () {
    final now = DateTime(2026, 1, 1, 12);

    test('due when never backed up', () {
      expect(isAutoBackupDue(now: now), isTrue);
    });

    test('not due within 12 hours', () {
      expect(
        isAutoBackupDue(
          now: now,
          lastBackup: now.subtract(const Duration(hours: 11)),
        ),
        isFalse,
      );
    });

    test('due after 12 hours', () {
      expect(
        isAutoBackupDue(
          now: now,
          lastBackup: now.subtract(const Duration(hours: 13)),
        ),
        isTrue,
      );
    });

    test('a future timestamp is treated as due', () {
      expect(
        isAutoBackupDue(now: now, lastBackup: now.add(const Duration(days: 1))),
        isTrue,
      );
    });
  });

  group('contentFingerprint', () {
    test('ignores the export timestamp', () {
      expect(
        _document(exportedAt: '2027-06-06T09:30:00.000').contentFingerprint,
        _document().contentFingerprint,
      );
    });

    test('ignores row order', () {
      expect(
        _document(employerIds: const [2, 1]).contentFingerprint,
        _document(employerIds: const [1, 2]).contentFingerprint,
      );
    });

    test('adds a backup when work is registered', () {
      expect(
        _document(employerIds: const [1, 2]).contentFingerprint,
        isNot(_document().contentFingerprint),
      );
    });

    test('adds a backup when a wage amount changes', () {
      expect(
        _document(wageAmount: 90000).contentFingerprint,
        isNot(_document().contentFingerprint),
      );
    });

    test('ignores settings the app writes on its own', () {
      expect(
        _document(
          settings: {
            'currencyUnit': 'toman',
            'lastBackupAt': '2026-01-01T00:00:00.000',
            'lastBackupFingerprint': 'abc',
            'lastBackupReminderAt': '2026-01-01T00:00:00.000',
            'lastUpdateCheckAt': '2026-01-01T00:00:00.000',
            'backupRecoveryOffered': 'true',
          },
        ).contentFingerprint,
        _document(settings: {'currencyUnit': 'toman'}).contentFingerprint,
      );
    });

    test('counts a real setting change as new data', () {
      expect(
        _document(settings: {'currencyUnit': 'rial'}).contentFingerprint,
        isNot(
          _document(settings: {'currencyUnit': 'toman'}).contentFingerprint,
        ),
      );
    });

    test('an app upgrade leaves one snapshot of its own', () {
      expect(
        _document(appVersion: '1.7.0').contentFingerprint,
        isNot(_document().contentFingerprint),
      );
    });
  });

  group('auto backup JSON shape', () {
    test('wraps meta and data', () {
      final json = _document().toFileJson();
      expect(
        json.keys,
        containsAll(['schemaVersion', 'appVersion', 'createdAt', 'data']),
      );
      final data = json['data'] as Map;
      expect(
        data.keys,
        containsAll(['employers', 'workEntries', 'payments', 'settings']),
      );
    });

    test('encodeForFile round-trips', () {
      final document = _document();
      final restored = BackupDocument.decode(document.encodeForFile());
      expect(restored.employers.length, document.employers.length);
      expect(restored.workEntries.length, document.workEntries.length);
      expect(restored.payments.length, document.payments.length);
      expect(restored.exportedAt, document.exportedAt);
    });

    test('the flat manual export still decodes', () {
      final document = _document();
      final restored = BackupDocument.decode(document.encode());
      expect(restored.employers.single.name, 'کارفرمای 1');
      expect(restored.payments.single.amount, 1500);
    });
  });
}

BackupDocument _document({
  String exportedAt = '2026-01-01T00:00:00.000',
  String appVersion = '1.6.1',
  List<int> employerIds = const [1],
  int wageAmount = 50000,
  Map<String, String> settings = const {'currencyUnit': 'toman'},
}) {
  return BackupDocument(
    schemaVersion: BackupDocument.currentSchemaVersion,
    appVersion: appVersion,
    exportedAt: exportedAt,
    employers: [
      for (final id in employerIds)
        BackupEmployer(
          id: id,
          name: 'کارفرمای $id',
          color: 0xFF2E7D6F,
          defaultWageType: 'fixed',
          isArchived: false,
          createdAt: '2026-01-01T00:00:00.000',
        ),
    ],
    workEntries: [
      BackupWorkEntry(
        id: 1,
        employerId: 1,
        date: '2026-01-01',
        wageType: 'fixed',
        wageAmount: wageAmount,
        outOfPocketAmount: 0,
        createdAt: '2026-01-01T00:00:00.000',
      ),
    ],
    payments: [
      BackupPayment(
        id: 1,
        employerId: 1,
        date: '2026-01-01',
        amount: 1500,
        type: 'wage',
        createdAt: '2026-01-01T00:00:00.000',
      ),
    ],
    settings: settings,
  );
}

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
        isAutoBackupDue(
          now: now,
          lastBackup: now.add(const Duration(days: 1)),
        ),
        isTrue,
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
      expect(restored.employers.single.name, 'کارفرما');
      expect(restored.payments.single.amount, 1500);
    });
  });
}

BackupDocument _document() => BackupDocument.fromJson({
  'schemaVersion': 1,
  'appVersion': '1.2.1',
  'exportedAt': '2026-01-01T00:00:00.000',
  'employers': [
    {
      'id': 1,
      'name': 'کارفرما',
      'color': 0xFF2E7D6F,
      'defaultWageType': 'fixed',
      'isArchived': false,
      'createdAt': '',
    },
  ],
  'workEntries': [
    {
      'id': 1,
      'employerId': 1,
      'date': '2026-01-01',
      'wageType': 'fixed',
      'outOfPocketAmount': 0,
      'createdAt': '',
    },
  ],
  'payments': [
    {
      'id': 1,
      'employerId': 1,
      'date': '2026-01-01',
      'amount': 1500,
      'type': 'wage',
      'createdAt': '',
    },
  ],
  'settings': {'currencyUnit': 'toman'},
});

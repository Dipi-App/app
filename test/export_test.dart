import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dipi/core/utils/money.dart';
import 'package:dipi/data/db/app_database.dart';
import 'package:dipi/features/export/domain/export_data.dart';
import 'package:dipi/features/export/domain/export_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

WorkEntry entry({
  int id = 1,
  int employerId = 1,
  required String date,
  int? wage,
  int outOfPocket = 0,
  String? place,
  String? job,
  String? start,
  String? end,
  String wageType = 'fixed',
  String? note,
}) {
  return WorkEntry(
    id: id,
    employerId: employerId,
    date: date,
    place: place,
    job: job,
    startTime: start,
    endTime: end,
    wageType: wageType,
    wageAmount: wage,
    outOfPocketAmount: outOfPocket,
    note: note,
    createdAt: '2024-05-12T00:00:00.000',
  );
}

Payment payment({
  int id = 1,
  int employerId = 1,
  required String date,
  required int amount,
  String type = 'wage',
}) {
  return Payment(
    id: id,
    employerId: employerId,
    date: date,
    amount: amount,
    type: type,
    note: null,
    createdAt: '2024-05-12T00:00:00.000',
  );
}

Employer employer({int id = 1, String name = 'کارگاه آفتاب'}) => Employer(
  id: id,
  name: name,
  color: 0xFF2E7D6F,
  phone: null,
  note: null,
  defaultWageType: 'fixed',
  defaultDailyWage: null,
  isArchived: false,
  createdAt: '2024-05-01T00:00:00.000',
);

ExportData buildData({
  List<WorkEntry> entries = const [],
  List<Payment> payments = const [],
  List<Employer> employers = const [],
  Set<int> employerIds = const {},
  DateTime? from,
  DateTime? to,
}) {
  return buildExportData(
    employers: employers.isEmpty ? [employer()] : employers,
    entries: entries,
    payments: payments,
    from: from ?? DateTime(2024, 5, 1),
    to: to ?? DateTime(2024, 5, 31),
    employerIds: employerIds,
    unit: CurrencyUnit.toman,
    generatedAt: DateTime(2024, 6, 1),
  );
}

void main() {
  group('buildExportData', () {
    test('filters by date range', () {
      final data = buildData(
        entries: [
          entry(date: '2024-04-30', wage: 100),
          entry(id: 2, date: '2024-05-12', wage: 200),
          entry(id: 3, date: '2024-06-01', wage: 300),
        ],
      );
      expect(data.sections.single.entries, hasLength(1));
      expect(data.sections.single.entries.single.wageAmount, 200);
      expect(data.overall.balanceRial, 200);
    });

    test('filters by employer', () {
      final data = buildData(
        employers: [employer(), employer(id: 2, name: 'آقای رضایی')],
        employerIds: {2},
        entries: [
          entry(date: '2024-05-12', wage: 100),
          entry(id: 2, employerId: 2, date: '2024-05-12', wage: 900),
        ],
      );
      expect(data.sections, hasLength(1));
      expect(data.sections.single.name, 'آقای رضایی');
    });

    test('sorts employers by name and entries by date', () {
      final data = buildData(
        employers: [employer(name: 'ب'), employer(id: 2, name: 'الف')],
        entries: [
          entry(employerId: 1, date: '2024-05-20', wage: 1),
          entry(id: 2, employerId: 2, date: '2024-05-11', wage: 2),
          entry(id: 3, employerId: 1, date: '2024-05-10', wage: 3),
        ],
      );
      expect(data.sections.map((s) => s.name), ['الف', 'ب']);
      expect(
        data.sections[1].entries.map((e) => e.date),
        ['2024-05-10', '2024-05-20'],
      );
    });

    test('builds a file stem with both ends of the range', () {
      final data = buildData(from: DateTime(2024, 5, 1), to: DateTime(2024, 5, 31));
      expect(data.fileStem, 'dipi-report-20240501-20240531');
    });

    test('an empty range produces no sections', () {
      final data = buildData(entries: [entry(date: '2024-01-01', wage: 5)]);
      expect(data.sections, isEmpty);
      expect(data.hasData, isFalse);
    });
  });

  group('plain text export', () {
    test('starts with a utf-8 BOM and marks lines as rtl', () {
      final file = renderExport(
        buildData(entries: [entry(date: '2024-05-12', wage: 5000000)]),
        ExportFormat.txt,
      );
      expect(file.bytes.take(3), [0xEF, 0xBB, 0xBF]);
      expect(file.fileName, endsWith('.txt'));
      final text = utf8.decode(file.bytes);
      expect(text, contains('کارگاه آفتاب'));
      expect(text, contains('۵۰۰٬۰۰۰ تومان'));
      // Every non-empty line carries a right-to-left mark.
      final lines = text.split('\n').where((line) => line.trim().isNotEmpty);
      expect(
        lines.every((line) => line.startsWith('\u200F')),
        isTrue,
      );
    });

    test('marks unknown wages as pending instead of zero', () {
      final file = renderExport(
        buildData(entries: [entry(date: '2024-05-12')]),
        ExportFormat.txt,
      );
      final text = utf8.decode(file.bytes);
      expect(text, contains('دستمزد: در انتظار'));
      expect(text, contains('توجه: ۱ روزکار با دستمزد نامعلوم'));
    });
  });

  group('markdown export', () {
    test('wraps the report in an rtl block with a totals table', () {
      final file = renderExport(
        buildData(
          entries: [entry(date: '2024-05-12', wage: 5000000, job: 'بنایی')],
          payments: [payment(date: '2024-05-20', amount: 1000000)],
        ),
        ExportFormat.markdown,
      );
      final text = utf8.decode(file.bytes);
      expect(text, startsWith('<div dir="rtl" align="right">'));
      expect(text, endsWith('</div>\n'));
      expect(text, contains('| مورد | مقدار |'));
      expect(text, contains('## کارگاه آفتاب'));
      expect(text, contains('- ۱۴۰۳/۰۲/۲۳ | بنایی'));
      expect(text, contains('# جمع کل'));
      expect(file.fileName, endsWith('.md'));
    });
  });

  group('docx export', () {
    late ExportFile file;

    setUp(() {
      file = renderExport(
        buildData(
          entries: [
            entry(
              date: '2024-05-12',
              wage: 5000000,
              place: 'کارگاه ۲',
              job: 'بنایی',
              start: '08:00',
              end: '16:30',
            ),
          ],
          payments: [payment(date: '2024-05-20', amount: 1000000)],
        ),
        ExportFormat.docx,
      );
    });

    test('is a zip with the parts Word needs', () {
      expect(file.bytes.take(2), [0x50, 0x4B]); // "PK"
      final archive = ZipDecoder().decodeBytes(file.bytes);
      final names = archive.files.map((f) => f.name).toSet();
      expect(names, contains('[Content_Types].xml'));
      expect(names, contains('_rels/.rels'));
      expect(names, contains('word/document.xml'));
      expect(names, contains('word/styles.xml'));
      expect(names, contains('word/_rels/document.xml.rels'));
      expect(file.fileName, endsWith('.docx'));
      expect(
        file.mimeType,
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
    });

    test('sets right-to-left on the document, paragraphs and runs', () {
      final archive = ZipDecoder().decodeBytes(file.bytes);
      final document = utf8.decode(
        archive.findFile('word/document.xml')!.readBytes()!,
      );
      expect(document, contains('<w:bidi/>'));
      expect(document, contains('<w:rtl/>'));
      expect(document, contains('<w:jc w:val="right"/>'));
      expect(document, contains('<w:bidiVisual/>'));
      expect(document, contains('w:cs="Vazirmatn"'));
      expect(document, contains('<w:sectPr><w:bidi/>'));
      expect(document, contains('کارگاه آفتاب'));
      expect(document, contains('۵۰۰٬۰۰۰ تومان'));
    });

    test('escapes xml characters', () {
      final risky = renderExport(
        buildData(
          employers: [employer(name: 'شرکت <الف> & پسران')],
          entries: [entry(date: '2024-05-12', wage: 1)],
        ),
        ExportFormat.docx,
      );
      final archive = ZipDecoder().decodeBytes(risky.bytes);
      final document = utf8.decode(
        archive.findFile('word/document.xml')!.readBytes()!,
      );
      expect(document, contains('شرکت &lt;الف&gt; &amp; پسران'));
      expect(document, isNot(contains('<الف>')));
    });

    test('the styles part defaults to persian rtl', () {
      final archive = ZipDecoder().decodeBytes(file.bytes);
      final styles = utf8.decode(
        archive.findFile('word/styles.xml')!.readBytes()!,
      );
      expect(styles, contains('<w:rtl/>'));
      expect(styles, contains('<w:bidi/>'));
      expect(styles, contains('w:styleId="Normal"'));
    });
  });
}

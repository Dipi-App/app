import '../../../core/utils/jalali_utils.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/settlement.dart';
import '../../../core/utils/money.dart';

enum ExportFormat {
  txt('متن ساده', 'txt', 'text/plain', 'کم‌حجم و ساده؛ برای هر برنامه‌ای باز می‌شود.'),
  markdown(
    'مارک‌داون',
    'md',
    'text/markdown',
    'ساختاردار و راست‌به‌چپ؛ مناسب گیت‌هاب و دفترچه‌ها.',
  ),
  docx(
    'ورد',
    'docx',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'سند رسمی و راست‌به‌چپ با جدول؛ مناسب چاپ و ارسال.',
  );

  const ExportFormat(this.label, this.extension, this.mimeType, this.description);

  final String label;
  final String extension;
  final String mimeType;
  final String description;
}

class ExportEmployerSection {
  const ExportEmployerSection({
    required this.employer,
    required this.entries,
    required this.payments,
    required this.totals,
  });

  final Employer? employer;
  final List<WorkEntry> entries;
  final List<Payment> payments;
  final SettlementSummary totals;

  String get name => employer?.name ?? 'کارفرمای حذف‌شده';
}

class ExportData {
  const ExportData({
    required this.from,
    required this.to,
    required this.sections,
    required this.overall,
    required this.unit,
    required this.generatedAt,
  });

  final DateTime from;
  final DateTime to;
  final List<ExportEmployerSection> sections;
  final SettlementSummary overall;
  final CurrencyUnit unit;
  final DateTime generatedAt;

  bool get hasData => sections.isNotEmpty;

  String get rangeLabel =>
      '${formatJalaliLong(from)} تا ${formatJalaliLong(to)}';

  String get fileStem {
    String stamp(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
    return 'dipi-report-${stamp(from)}-${stamp(to)}';
  }
}

/// Filters the ledger down to the requested range and employers and computes
/// every total the three exporters need.
ExportData buildExportData({
  required List<Employer> employers,
  required List<WorkEntry> entries,
  required List<Payment> payments,
  required DateTime from,
  required DateTime to,
  required Set<int> employerIds,
  required CurrencyUnit unit,
  DateTime? generatedAt,
}) {
  final fromIso = toIsoDate(from);
  final toIso = toIsoDate(to);
  final employersById = {for (final employer in employers) employer.id: employer};

  bool inRange(String iso) => iso.compareTo(fromIso) >= 0 && iso.compareTo(toIso) <= 0;
  bool wanted(int employerId) =>
      employerIds.isEmpty || employerIds.contains(employerId);

  final entriesByEmployer = <int, List<WorkEntry>>{};
  for (final entry in entries) {
    if (!inRange(entry.date) || !wanted(entry.employerId)) continue;
    entriesByEmployer.putIfAbsent(entry.employerId, () => []).add(entry);
  }

  final paymentsByEmployer = <int, List<Payment>>{};
  for (final payment in payments) {
    if (!inRange(payment.date) || !wanted(payment.employerId)) continue;
    paymentsByEmployer.putIfAbsent(payment.employerId, () => []).add(payment);
  }

  final ids = <int>{
    ...entriesByEmployer.keys,
    ...paymentsByEmployer.keys,
  };

  final sections = <ExportEmployerSection>[
    for (final id in ids)
      ExportEmployerSection(
        employer: employersById[id],
        entries: _sortedEntries(entriesByEmployer[id] ?? const []),
        payments: _sortedPayments(paymentsByEmployer[id] ?? const []),
        totals: summarizeSettlement(
          entries: entriesByEmployer[id] ?? const [],
          payments: paymentsByEmployer[id] ?? const [],
        ),
      ),
  ];
  sections.sort(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );

  final allEntries = [
    for (final section in sections) ...section.entries,
  ];
  final allPayments = [
    for (final section in sections) ...section.payments,
  ];

  return ExportData(
    from: dateOnly(from),
    to: dateOnly(to),
    sections: sections,
    overall: summarizeSettlement(entries: allEntries, payments: allPayments),
    unit: unit,
    generatedAt: generatedAt ?? DateTime.now(),
  );
}

List<WorkEntry> _sortedEntries(List<WorkEntry> entries) {
  final sorted = [...entries];
  sorted.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return (a.startTime ?? '').compareTo(b.startTime ?? '');
  });
  return sorted;
}

List<Payment> _sortedPayments(List<Payment> payments) {
  final sorted = [...payments];
  sorted.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return a.id.compareTo(b.id);
  });
  return sorted;
}

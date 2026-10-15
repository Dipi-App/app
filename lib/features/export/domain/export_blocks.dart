import '../../../core/utils/jalali_utils.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../core/utils/time_utils.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/enums.dart';
import '../../../core/constants/app_info.dart';
import 'export_data.dart';

/// A tiny format-neutral document model. The three exporters (txt, markdown,
/// docx) each render the same blocks, so they can never disagree.
sealed class ExportBlock {
  const ExportBlock();
}

final class ExportHeading extends ExportBlock {
  const ExportHeading(this.text, {this.level = 1});

  final String text;
  final int level;
}

final class ExportParagraph extends ExportBlock {
  const ExportParagraph(this.text, {this.bold = false});

  final String text;
  final bool bold;
}

final class ExportKeyValues extends ExportBlock {
  const ExportKeyValues(this.rows);

  final List<(String, String)> rows;
}

final class ExportBullets extends ExportBlock {
  const ExportBullets(this.items);

  final List<String> items;
}

final class ExportDivider extends ExportBlock {
  const ExportDivider();
}

List<ExportBlock> exportBlocks(ExportData data) {
  final blocks = <ExportBlock>[
    ExportHeading('${AppInfo.nameFa} — گزارش روزکار و حساب', level: 1),
    ExportParagraph(AppInfo.taglineFa),
    ExportKeyValues([
      ('بازه گزارش', data.rangeLabel),
      ('تاریخ ساخت', formatJalaliLong(data.generatedAt)),
      ('واحد پول', data.unit.label),
      ('تعداد کارفرما', toPersianDigits(data.sections.length)),
    ]),
    const ExportDivider(),
  ];

  if (!data.hasData) {
    blocks.add(
      const ExportParagraph('در این بازه و با این فیلترها داده‌ای ثبت نشده است.'),
    );
  }

  for (final section in data.sections) {
    blocks
      ..add(ExportHeading(section.name, level: 2))
      ..add(ExportKeyValues(_summaryRows(section, data.unit)));

    if (section.entries.isNotEmpty) {
      blocks
        ..add(const ExportParagraph('روزکارها', bold: true))
        ..add(
          ExportBullets([
            for (final entry in section.entries) _entryLine(entry, data.unit),
          ]),
        );
    }

    if (section.payments.isNotEmpty) {
      blocks
        ..add(const ExportParagraph('پرداخت‌ها', bold: true))
        ..add(
          ExportBullets([
            for (final payment in section.payments)
              _paymentLine(payment, data.unit),
          ]),
        );
    }

    if (section.totals.pendingCount > 0) {
      blocks.add(
        ExportParagraph(
          'توجه: ${toPersianDigits(section.totals.pendingCount)} روزکار با دستمزد '
          'نامعلوم در این گزارش هست و در جمع دستمزد نیامده است.',
        ),
      );
    }

    blocks.add(const ExportDivider());
  }

  blocks
    ..add(ExportHeading('جمع کل', level: 1))
    ..add(ExportKeyValues(_overallRows(data)));

  return blocks;
}

List<(String, String)> _summaryRows(ExportEmployerSection section, CurrencyUnit unit) {
  final totals = section.totals;
  return [
    ('روزهای کاری', toPersianDigits(totals.dayCount)),
    ('تعداد روزکار', toPersianDigits(totals.entryCount)),
    ('مجموع ساعت', formatHours(totals.hours)),
    ('جمع دستمزد', _money(totals.wageRial, unit)),
    ('هزینه از جیب من', _money(totals.outOfPocketRial, unit)),
    ('جمع پرداخت‌ها', _money(totals.paymentsTotalRial, unit)),
    ('مانده', '${totals.state.label} ${_money(totals.balanceRial.abs(), unit)}'),
  ];
}

List<(String, String)> _overallRows(ExportData data) {
  final totals = data.overall;
  return [
    ('کارفرماها', toPersianDigits(data.sections.length)),
    ('روزهای کاری', toPersianDigits(totals.dayCount)),
    ('تعداد روزکار', toPersianDigits(totals.entryCount)),
    ('مجموع ساعت', formatHours(totals.hours)),
    ('جمع دستمزد', _money(totals.wageRial, data.unit)),
    ('هزینه از جیب من', _money(totals.outOfPocketRial, data.unit)),
    ('جمع پرداخت‌ها', _money(totals.paymentsTotalRial, data.unit)),
    (
      'مانده کل',
      '${totals.state.label} ${_money(totals.balanceRial.abs(), data.unit)}',
    ),
  ];
}

String _entryLine(WorkEntry entry, CurrencyUnit unit) {
  final parts = <String>[formatJalaliShortIso(entry.date)];
  final title = [
    if ((entry.place ?? '').trim().isNotEmpty) entry.place!.trim(),
    if ((entry.job ?? '').trim().isNotEmpty) entry.job!.trim(),
  ].join(' · ');
  if (title.isNotEmpty) parts.add(title);
  if (entry.startTime != null && entry.endTime != null) {
    parts.add(
      '${formatClockText(entry.startTime)} تا ${formatClockText(entry.endTime)} '
      '(${formatDuration(shiftDuration(entry.startTime, entry.endTime))})',
    );
  }
  parts.add(
    entry.wageAmount == null
        ? 'دستمزد: در انتظار'
        : 'دستمزد: ${_money(entry.wageAmount!, unit)}',
  );
  if (entry.outOfPocketAmount > 0) {
    parts.add('از جیب: ${_money(entry.outOfPocketAmount, unit)}');
  }
  if (entry.wageType == WageType.variable.name) {
    parts.add('متغیر');
  }
  if ((entry.note ?? '').trim().isNotEmpty) {
    parts.add('یادداشت: ${entry.note!.trim()}');
  }
  return parts.join(' | ');
}

String _paymentLine(Payment payment, CurrencyUnit unit) {
  final parts = <String>[
    formatJalaliShortIso(payment.date),
    PaymentType.fromName(payment.type).label,
    _money(payment.amount, unit),
  ];
  if ((payment.note ?? '').trim().isNotEmpty) {
    parts.add('یادداشت: ${payment.note!.trim()}');
  }
  return parts.join(' | ');
}

String _money(int rial, CurrencyUnit unit) => formatMoney(rial, unit);

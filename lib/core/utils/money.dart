import 'persian_digits.dart';

enum CurrencyUnit {
  toman('تومان', 10),
  rial('ریال', 1);

  const CurrencyUnit(this.label, this.rialFactor);

  final String label;

  /// How many Rial one unit of this currency is worth.
  /// All amounts are stored in the database as Rial (the canonical integer unit).
  final int rialFactor;

  static CurrencyUnit fromName(String? name) => CurrencyUnit.values.firstWhere(
    (unit) => unit.name == name,
    orElse: () => CurrencyUnit.toman,
  );

  int toRial(int amountInThisUnit) => amountInThisUnit * rialFactor;

  int fromRial(int rialAmount) => rialAmount ~/ rialFactor;
}

String groupDigits(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('٬');
    }
    buffer.write(digits[i]);
  }
  return '${negative ? '−' : ''}$buffer';
}

String formatMoney(
  int rialAmount,
  CurrencyUnit unit, {
  bool withUnit = true,
  bool signed = false,
}) {
  final display = unit.fromRial(rialAmount);
  final grouped = groupDigits(display);
  final sign = signed && display > 0 ? '+' : '';
  final text = toPersianDigits('$sign$grouped');
  return withUnit ? '$text ${unit.label}' : text;
}

String formatMoneyCompact(int rialAmount, CurrencyUnit unit) {
  final display = unit.fromRial(rialAmount).abs();
  String scaled(double value) =>
      toPersianDigits(value.toStringAsFixed(1)).replaceAll('.', '٫');
  if (display >= 1000000000) {
    return '${scaled(display / 1000000000)} میلیارد';
  }
  if (display >= 1000000) {
    return '${scaled(display / 1000000)} میلیون';
  }
  if (display >= 1000) {
    return '${toPersianDigits(display ~/ 1000)} هزار';
  }
  return toPersianDigits(display);
}

String formatBalanceLabel(int rialAmount) {
  if (rialAmount > 0) return 'طلبکار';
  if (rialAmount < 0) return 'بدهکار';
  return 'تسویه';
}

const String _asciiDigits = '0123456789';
const String _persianDigits = '۰۱۲۳۴۵۶۷۸۹';
const String _arabicDigits = '٠١٢٣٤٥٦٧٨٩';

String toPersianDigits(Object? value) {
  final text = value?.toString() ?? '';
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    final pos = _asciiDigits.indexOf(char);
    buffer.write(pos == -1 ? char : _persianDigits[pos]);
  }
  return buffer.toString();
}

String toEnglishDigits(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    final persianPos = _persianDigits.indexOf(char);
    if (persianPos != -1) {
      buffer.write(_asciiDigits[persianPos]);
      continue;
    }
    final arabicPos = _arabicDigits.indexOf(char);
    buffer.write(arabicPos == -1 ? char : _asciiDigits[arabicPos]);
  }
  return buffer.toString();
}

int? parsePersianInt(String? value) {
  if (value == null) return null;
  final normalized = toEnglishDigits(value)
      .trim()
      .replaceAll(',', '')
      .replaceAll('٬', '')
      .replaceAll(' ', '');
  if (normalized.isEmpty) return null;
  return int.tryParse(normalized);
}

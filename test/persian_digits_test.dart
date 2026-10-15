import 'package:dipi/core/utils/persian_digits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('toPersianDigits', () {
    test('converts ascii digits', () {
      expect(toPersianDigits(123), '۱۲۳');
      expect(toPersianDigits('2024/05/12'), '۲۰۲۴/۰۵/۱۲');
    });

    test('keeps non digits', () {
      expect(toPersianDigits('a1b'), 'a۱b');
    });
  });

  group('toEnglishDigits', () {
    test('converts persian and arabic digits', () {
      expect(toEnglishDigits('۱۲۳'), '123');
      expect(toEnglishDigits('٤٥٦'), '456');
      expect(toEnglishDigits('۵۶۷'), '567');
    });
  });

  group('parsePersianInt', () {
    test('parses grouped persian numbers', () {
      expect(parsePersianInt('۱٬۲۳۴٬۵۶۷'), 1234567);
      expect(parsePersianInt('1,234'), 1234);
      expect(parsePersianInt(''), isNull);
      expect(parsePersianInt(null), isNull);
      expect(parsePersianInt('abc'), isNull);
    });
  });
}

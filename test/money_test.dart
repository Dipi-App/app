import 'package:dipi/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('grouping', () {
    test('adds persian separators', () {
      expect(groupDigits(0), '0');
      expect(groupDigits(999), '999');
      expect(groupDigits(1000), '1٬000');
      expect(groupDigits(1234567), '1٬234٬567');
      expect(groupDigits(-4500), '−4٬500');
    });
  });

  group('currency conversion', () {
    test('toman is ten rial', () {
      expect(CurrencyUnit.toman.rialFactor, 10);
      expect(CurrencyUnit.toman.toRial(5000), 50000);
      expect(CurrencyUnit.toman.fromRial(50000), 5000);
      expect(CurrencyUnit.rial.toRial(5000), 5000);
    });

    test('unknown names fall back to toman', () {
      expect(CurrencyUnit.fromName(null), CurrencyUnit.toman);
      expect(CurrencyUnit.fromName('nonsense'), CurrencyUnit.toman);
      expect(CurrencyUnit.fromName('rial'), CurrencyUnit.rial);
    });
  });

  group('formatting', () {
    test('formats with unit and persian digits', () {
      expect(formatMoney(50000, CurrencyUnit.toman), '۵٬۰۰۰ تومان');
      expect(formatMoney(50000, CurrencyUnit.rial), '۵۰٬۰۰۰ ریال');
      expect(formatMoney(50000, CurrencyUnit.toman, withUnit: false), '۵٬۰۰۰');
    });

    test('signed formatting', () {
      expect(
        formatMoney(50000, CurrencyUnit.toman, signed: true),
        '+۵٬۰۰۰ تومان',
      );
      expect(formatMoney(-50000, CurrencyUnit.toman, signed: true), '−۵٬۰۰۰ تومان');
    });

    test('compact formatting', () {
      expect(formatMoneyCompact(500000000, CurrencyUnit.toman), '۵۰٫۰ میلیون');
      expect(formatMoneyCompact(50000, CurrencyUnit.toman), '۵ هزار');
    });
  });

  group('balance label', () {
    test('maps sign to persian label', () {
      expect(formatBalanceLabel(1), 'طلبکار');
      expect(formatBalanceLabel(-1), 'بدهکار');
      expect(formatBalanceLabel(0), 'تسویه');
    });
  });
}

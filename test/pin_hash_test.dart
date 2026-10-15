import 'package:dipi/core/utils/pin_hash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hashPin', () {
    test('is stable for the same pin and salt', () {
      final salt = generatePinSalt();
      expect(hashPin('1234', salt), hashPin('1234', salt));
    });

    test('changes with the salt', () {
      expect(
        hashPin('1234', 'salt-a'),
        isNot(hashPin('1234', 'salt-b')),
      );
    });

    test('changes with the pin', () {
      const salt = 'salt';
      expect(hashPin('1234', salt), isNot(hashPin('1235', salt)));
    });

    test('never contains the pin itself', () {
      expect(hashPin('12345678', 'salt'), isNot(contains('12345678')));
    });
  });

  group('generatePinSalt', () {
    test('is not empty and differs between calls', () {
      final first = generatePinSalt();
      final second = generatePinSalt();
      expect(first, isNotEmpty);
      expect(first, isNot(second));
    });
  });

  group('verifyPin', () {
    test('accepts the right pin', () {
      final salt = generatePinSalt();
      final hash = hashPin('4321', salt);
      expect(verifyPin('4321', hash: hash, salt: salt), isTrue);
    });

    test('rejects a wrong pin', () {
      final salt = generatePinSalt();
      final hash = hashPin('4321', salt);
      expect(verifyPin('1234', hash: hash, salt: salt), isFalse);
    });

    test('rejects missing hash or salt', () {
      expect(verifyPin('1234', hash: null, salt: 'x'), isFalse);
      expect(verifyPin('1234', hash: 'x', salt: null), isFalse);
      expect(verifyPin('1234', hash: '', salt: ''), isFalse);
    });
  });

  group('isValidPin', () {
    test('accepts four to eight digits', () {
      expect(isValidPin('1234'), isTrue);
      expect(isValidPin('12345678'), isTrue);
      expect(isValidPin('۱۲۳۴'), isTrue);
    });

    test('rejects too short or too long pins', () {
      expect(isValidPin('123'), isFalse);
      expect(isValidPin('123456789'), isFalse);
      expect(isValidPin(''), isFalse);
    });
  });
}

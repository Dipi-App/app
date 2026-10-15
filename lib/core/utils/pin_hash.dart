import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// The PIN is never stored, only a salted SHA-256 hash of it.
String hashPin(String pin, String salt) =>
    sha256.convert(utf8.encode('dipi:v1:$salt:$pin')).toString();

String generatePinSalt() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return base64UrlEncode(bytes);
}

bool verifyPin(String pin, {required String? hash, required String? salt}) {
  if (hash == null || salt == null || hash.isEmpty || salt.isEmpty) {
    return false;
  }
  return hashPin(pin, salt) == hash;
}

/// Accepts 4 to 8 digits, Persian or ASCII.
bool isValidPin(String pin) {
  final digits = pin.replaceAll(RegExp(r'[^0-9۰-۹]'), '');
  return digits.length >= 4 && digits.length <= 8;
}

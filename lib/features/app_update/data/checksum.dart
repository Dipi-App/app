import 'dart:io';

import 'package:crypto/crypto.dart';

/// Hex SHA-256 of [bytes].
String sha256OfBytes(List<int> bytes) => sha256.convert(bytes).toString();

/// Hex SHA-256 of a file, read in chunks so a big APK does not fill memory.
Future<String> sha256OfFile(File file) async {
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString();
}

/// Reads the hash out of a `<hash>  <filename>` checksum file.
/// Returns null when the text is not a valid SHA-256 line.
String? parseSha256File(String content) {
  final tokens = content.trim().split(RegExp(r'\s+'));
  if (tokens.isEmpty) return null;
  final hex = tokens.first.toLowerCase();
  return RegExp(r'^[0-9a-f]{64}$').hasMatch(hex) ? hex : null;
}

/// Case-insensitive compare of two hex hashes.
bool checksumMatches(String downloaded, String expected) =>
    downloaded.toLowerCase() == expected.toLowerCase();

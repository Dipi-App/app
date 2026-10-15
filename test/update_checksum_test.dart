import 'dart:io';

import 'package:dipi/features/app_update/data/checksum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // SHA-256 of the ASCII string "abc".
  const abcHash =
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';

  group('sha256', () {
    test('hashes bytes', () {
      expect(sha256OfBytes('abc'.codeUnits), abcHash);
    });

    test('hashes a file the same way', () async {
      final dir = await Directory.systemTemp.createTemp('dipi-checksum');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/sample.bin');
      await file.writeAsBytes('abc'.codeUnits);
      expect(await sha256OfFile(file), abcHash);
    });
  });

  group('parseSha256File', () {
    test('reads the hash from a `<hash>  <name>` line', () {
      expect(parseSha256File('$abcHash  dipi.apk'), abcHash);
    });

    test('tolerates uppercase and extra spaces', () {
      expect(parseSha256File('  ${abcHash.toUpperCase()}   dipi.apk\n'), abcHash);
    });

    test('returns null for junk', () {
      expect(parseSha256File('not a hash'), isNull);
      expect(parseSha256File(''), isNull);
    });
  });

  test('checksumMatches ignores case', () {
    expect(checksumMatches(abcHash.toUpperCase(), abcHash), isTrue);
    expect(checksumMatches('deadbeef', abcHash), isFalse);
  });
}

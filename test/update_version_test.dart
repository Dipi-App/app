import 'package:dipi/features/app_update/domain/check_schedule.dart';
import 'package:dipi/features/app_update/domain/semantic_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SemanticVersion', () {
    test('parses v-prefixed, plain and build versions', () {
      expect(SemanticVersion.tryParse('v1.2.3'), const SemanticVersion(1, 2, 3));
      expect(SemanticVersion.tryParse('1.2.3'), const SemanticVersion(1, 2, 3));
      expect(SemanticVersion.tryParse('1.2.3+4'), const SemanticVersion(1, 2, 3, 4));
      expect(SemanticVersion.tryParse('v2.0.0+10'), const SemanticVersion(2, 0, 0, 10));
    });

    test('drops pre-release metadata', () {
      expect(
        SemanticVersion.tryParse('v1.2.3-beta.1'),
        const SemanticVersion(1, 2, 3),
      );
    });

    test('rejects text that is not a version', () {
      expect(SemanticVersion.tryParse(null), isNull);
      expect(SemanticVersion.tryParse(''), isNull);
      expect(SemanticVersion.tryParse('latest'), isNull);
    });

    test('compares numerically, not as strings', () {
      expect(
        SemanticVersion.tryParse('1.10.0')! >
            SemanticVersion.tryParse('1.9.0')!,
        isTrue,
      );
      expect(
        SemanticVersion.tryParse('2.0.0')! >
            SemanticVersion.tryParse('1.99.99')!,
        isTrue,
      );
    });

    test('equal versions are not newer', () {
      expect(
        SemanticVersion.tryParse('1.1.0')! >
            SemanticVersion.tryParse('v1.1.0')!,
        isFalse,
      );
    });

    test('build number breaks a tie', () {
      expect(
        SemanticVersion.tryParse('1.0.0+3')! >
            SemanticVersion.tryParse('1.0.0+2')!,
        isTrue,
      );
      // Installed 1.1.0+2 is not older than the tag v1.1.0.
      expect(
        SemanticVersion.tryParse('1.1.0+2')! >
            SemanticVersion.tryParse('v1.1.0')!,
        isTrue,
      );
    });
  });

  group('isCheckDue', () {
    final now = DateTime(2026, 1, 1, 12);

    test('runs when never checked', () {
      expect(isCheckDue(now: now, lastCheck: null), isTrue);
    });

    test('skips inside the 6-hour window', () {
      expect(
        isCheckDue(now: now, lastCheck: now.subtract(const Duration(hours: 5))),
        isFalse,
      );
    });

    test('runs after the window', () {
      expect(
        isCheckDue(now: now, lastCheck: now.subtract(const Duration(hours: 7))),
        isTrue,
      );
    });

    test('a manual check always runs', () {
      expect(
        isCheckDue(
          now: now,
          lastCheck: now.subtract(const Duration(minutes: 1)),
          manual: true,
        ),
        isTrue,
      );
    });

    test('a backwards clock does not lock the check', () {
      expect(
        isCheckDue(now: now, lastCheck: now.add(const Duration(days: 2))),
        isTrue,
      );
    });
  });
}

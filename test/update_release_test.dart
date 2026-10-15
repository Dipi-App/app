import 'package:dipi/features/app_update/domain/abi_matcher.dart';
import 'package:dipi/features/app_update/domain/app_release.dart';
import 'package:dipi/features/app_update/domain/release_asset.dart';
import 'package:dipi/features/app_update/domain/semantic_version.dart';
import 'package:flutter_test/flutter_test.dart';

ReleaseAsset _apk(String name, {int size = 100}) => ReleaseAsset(
  name: name,
  sizeInBytes: size,
  downloadUrl: 'https://github.com/mst-ghi/dipi/releases/download/v1.2.0/$name',
);

AppRelease _release({List<ReleaseAsset>? extra}) => AppRelease(
  tag: 'v1.2.0',
  version: const SemanticVersion(1, 2, 0),
  body: 'notes',
  assets: [
    _apk('dipi-v1.2.0-arm64-v8a.apk', size: 30),
    _apk('dipi-v1.2.0-armeabi-v7a.apk', size: 25),
    _apk('dipi-v1.2.0-x86_64.apk', size: 28),
    _apk('dipi-v1.2.0-universal.apk', size: 60),
    ...?extra,
  ],
);

void main() {
  group('pickApkForAbis', () {
    test('picks the exact ABI', () {
      final picked = pickApkForAbis(_release(), ['arm64-v8a', 'armeabi-v7a']);
      expect(picked?.name, 'dipi-v1.2.0-arm64-v8a.apk');
    });

    test('falls back to the next supported ABI', () {
      final picked = pickApkForAbis(_release(), ['armeabi-v7a']);
      expect(picked?.name, 'dipi-v1.2.0-armeabi-v7a.apk');
    });

    test('uses the universal APK when no ABI matches', () {
      final picked = pickApkForAbis(_release(), ['mips']);
      expect(picked?.name, 'dipi-v1.2.0-universal.apk');
    });

    test('uses the universal APK when the ABI list is empty', () {
      final picked = pickApkForAbis(_release(), const []);
      expect(picked?.name, 'dipi-v1.2.0-universal.apk');
    });

    test('uses a lone APK when the release has only one', () {
      final release = AppRelease(
        tag: 'v1.2.0',
        version: const SemanticVersion(1, 2, 0),
        body: '',
        assets: [_apk('dipi-v1.2.0-arm64-v8a.apk')],
      );
      final picked = pickApkForAbis(release, ['mips']);
      expect(picked?.name, 'dipi-v1.2.0-arm64-v8a.apk');
    });

    test('cannot guess with several ABIs and no universal APK', () {
      final release = _release().copyWithoutUniversal();
      expect(pickApkForAbis(release, ['mips']), isNull);
    });
  });

  group('checksumFor', () {
    test('finds the matching .sha256 asset', () {
      final release = _release(
        extra: [
          const ReleaseAsset(
            name: 'dipi-v1.2.0-arm64-v8a.apk.sha256',
            sizeInBytes: 80,
            downloadUrl: 'https://github.com/x/y.sha256',
          ),
        ],
      );
      final apk = release.apks.firstWhere((a) => a.name.contains('arm64'));
      expect(release.checksumFor(apk)?.name, 'dipi-v1.2.0-arm64-v8a.apk.sha256');
    });

    test('returns null when no checksum is published', () {
      final release = _release();
      expect(release.checksumFor(release.apks.first), isNull);
    });
  });

  test('AppRelease.fromJson reads tag, body and assets', () {
    final release = AppRelease.fromJson({
      'tag_name': 'v3.1.4',
      'body': 'fixed things',
      'assets': [
        {
          'name': 'dipi-v3.1.4-universal.apk',
          'size': 123,
          'browser_download_url': 'https://github.com/a/b.apk',
        },
      ],
    });
    expect(release.version, const SemanticVersion(3, 1, 4));
    expect(release.body, 'fixed things');
    expect(release.apks.single.name, 'dipi-v3.1.4-universal.apk');
  });
}

extension on AppRelease {
  AppRelease copyWithoutUniversal() => AppRelease(
    tag: tag,
    version: version,
    body: body,
    assets: assets.where((a) => !a.name.contains('universal')).toList(),
  );
}

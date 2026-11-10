import 'package:dipi/features/app_update/domain/app_release.dart';
import 'package:dipi/features/app_update/domain/release_asset.dart';
import 'package:dipi/features/app_update/domain/semantic_version.dart';
import 'package:dipi/features/app_update/domain/update_config.dart';
import 'package:flutter_test/flutter_test.dart';

ReleaseAsset _apk(String name, {int size = 100}) => ReleaseAsset(
  name: name,
  sizeInBytes: size,
  downloadUrl: 'https://github.com/Dipi-App/app/releases/download/v1.2.0/$name',
);

AppRelease _release({List<ReleaseAsset>? extra}) => AppRelease(
  tag: 'v1.2.0',
  version: const SemanticVersion(1, 2, 0),
  body: 'notes',
  htmlUrl: 'https://github.com/Dipi-App/app/releases/tag/v1.2.0',
  assets: [
    _apk('dipi-1.2.0-arm64-v8a.apk', size: 30),
    _apk('dipi-1.2.0-armeabi-v7a.apk', size: 25),
    _apk('dipi-1.2.0-x86_64.apk', size: 28),
    _apk('dipi-1.2.0.apk', size: 60),
    ...?extra,
  ],
);

void main() {
  group('bestApk', () {
    test('prefers the stable universal name dipi-<version>.apk', () {
      expect(_release().bestApk?.name, 'dipi-1.2.0.apk');
    });

    test('accepts the legacy -universal.apk name', () {
      final release = AppRelease(
        tag: 'v1.2.0',
        version: const SemanticVersion(1, 2, 0),
        body: '',
        assets: [
          _apk('dipi-1.2.0-arm64-v8a.apk'),
          _apk('dipi-1.2.0-universal.apk'),
        ],
      );
      expect(release.bestApk?.name, 'dipi-1.2.0-universal.apk');
    });

    test('falls back to any APK when there is no universal one', () {
      final release = AppRelease(
        tag: 'v1.2.0',
        version: const SemanticVersion(1, 2, 0),
        body: '',
        assets: [_apk('dipi-1.2.0-arm64-v8a.apk')],
      );
      expect(release.bestApk?.name, 'dipi-1.2.0-arm64-v8a.apk');
    });
  });

  group('apkForAbi', () {
    test('picks the APK built for the device ABI', () {
      expect(
        _release().apkForAbi('arm64-v8a')?.name,
        'dipi-1.2.0-arm64-v8a.apk',
      );
      expect(
        _release().apkForAbi('armeabi-v7a')?.name,
        'dipi-1.2.0-armeabi-v7a.apk',
      );
    });

    test('falls back to the universal APK for an unknown ABI', () {
      expect(_release().apkForAbi('mips')?.name, 'dipi-1.2.0.apk');
      expect(_release().apkForAbi(null)?.name, 'dipi-1.2.0.apk');
    });
  });

  test('ReleaseAsset reads the sha256 digest GitHub publishes', () {
    final asset = ReleaseAsset.fromJson({
      'name': 'dipi-1.2.0.apk',
      'size': 12,
      'browser_download_url': 'https://github.com/a/b.apk',
      'digest': 'sha256:ABCDEF0123',
    });
    expect(asset.sha256, 'abcdef0123');
  });

  test('the update feed points at the canonical repository', () {
    expect(UpdateConfig.githubOwner, 'Dipi-App');
    expect(UpdateConfig.githubRepo, 'app');
    expect(
      UpdateConfig.latestReleaseApi,
      'https://api.github.com/repos/Dipi-App/app/releases/latest',
    );
  });

  group('downloadUrl', () {
    test('is the chosen APK download link', () {
      expect(_release().downloadUrl, contains('dipi-1.2.0.apk'));
    });

    test('falls back to the release page when there is no APK', () {
      const release = AppRelease(
        tag: 'v1.2.0',
        version: SemanticVersion(1, 2, 0),
        body: '',
        htmlUrl: 'https://github.com/Dipi-App/app/releases/tag/v1.2.0',
        assets: [],
      );
      expect(release.downloadUrl, 'https://github.com/Dipi-App/app/releases/tag/v1.2.0');
    });

    test('falls back to the latest releases page when nothing is available', () {
      const release = AppRelease(
        tag: 'v1.2.0',
        version: SemanticVersion(1, 2, 0),
        body: '',
        assets: [],
      );
      expect(release.downloadUrl, UpdateConfig.releasesPageUrl);
    });
  });

  test('AppRelease.fromJson reads tag, body, html_url and assets', () {
    final release = AppRelease.fromJson({
      'tag_name': 'v3.1.4',
      'body': 'fixed things',
      'html_url': 'https://github.com/Dipi-App/app/releases/tag/v3.1.4',
      'assets': [
        {
          'name': 'dipi-3.1.4.apk',
          'size': 123,
          'browser_download_url': 'https://github.com/a/b.apk',
        },
      ],
    });
    expect(release.version, const SemanticVersion(3, 1, 4));
    expect(release.body, 'fixed things');
    expect(release.htmlUrl, contains('v3.1.4'));
    expect(release.apks.single.name, 'dipi-3.1.4.apk');
    expect(release.downloadUrl, 'https://github.com/a/b.apk');
  });
}

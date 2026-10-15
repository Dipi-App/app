import 'package:dipi/core/providers/app_info_providers.dart';
import 'package:dipi/features/app_update/data/github_release_client.dart';
import 'package:dipi/features/app_update/domain/app_release.dart';
import 'package:dipi/features/app_update/domain/release_asset.dart';
import 'package:dipi/features/app_update/domain/semantic_version.dart';
import 'package:dipi/features/app_update/state/update_controller.dart';
import 'package:dipi/features/app_update/state/update_providers.dart';
import 'package:dipi/features/settings/domain/app_settings.dart';
import 'package:dipi/features/settings/state/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppRelease _release() => const AppRelease(
  tag: 'v1.2.0',
  version: SemanticVersion(1, 2, 0),
  body: 'تازه‌ها',
  htmlUrl: 'https://github.com/mst-ghi/dipi/releases/tag/v1.2.0',
  assets: [
    ReleaseAsset(
      name: 'dipi-1.2.0.apk',
      sizeInBytes: 16,
      downloadUrl: 'https://github.com/mst-ghi/dipi/releases/download/v1.2.0/dipi-1.2.0.apk',
    ),
  ],
);

class _FakeGitHub extends GitHubReleaseClient {
  AppRelease? release;
  GitHubReleaseException? error;
  int calls = 0;

  @override
  Future<AppRelease?> latest({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    calls++;
    final e = error;
    if (e != null) throw e;
    return release;
  }
}

class _FakeSettings extends SettingsController {
  _FakeSettings(this._initial);

  final AppSettings _initial;

  @override
  Future<AppSettings> build() async => _initial;

  @override
  Future<void> setLastUpdateCheckAt(DateTime at) async {
    state = AsyncData(
      state.requireValue.copyWith(lastUpdateCheckAt: at.toIso8601String()),
    );
  }
}

void main() {
  late _FakeGitHub github;
  late ProviderContainer container;

  Future<void> setUpContainer({AppSettings? appSettings}) async {
    github = _FakeGitHub();
    final settings = _FakeSettings(appSettings ?? const AppSettings());
    container = ProviderContainer(
      overrides: [
        githubReleaseClientProvider.overrideWithValue(github),
        settingsControllerProvider.overrideWith(() => settings),
        appVersionProvider.overrideWith((ref) async => '1.0.0+1'),
      ],
    );
    addTearDown(container.dispose);
    await container.read(settingsControllerProvider.future);
  }

  test('a newer release is found and remembered', () async {
    await setUpContainer();
    github.release = _release();
    final controller = container.read(updateControllerProvider.notifier);

    final result = await controller.check(manual: false);
    expect(result.outcome, CheckOutcome.found);
    expect(result.release?.version, const SemanticVersion(1, 2, 0));
    expect(container.read(updateControllerProvider).hasUpdate, isTrue);
  });

  test('no newer release reports up to date and clears the flag', () async {
    await setUpContainer();
    github.release = null;
    final controller = container.read(updateControllerProvider.notifier);

    final result = await controller.check(manual: true);
    expect(result.outcome, CheckOutcome.upToDate);
    expect(container.read(updateControllerProvider).hasUpdate, isFalse);
  });

  test('a network error is quiet and reported as offline', () async {
    await setUpContainer();
    github.error = GitHubReleaseException('no net');
    final controller = container.read(updateControllerProvider.notifier);

    final result = await controller.check(manual: true);
    expect(result.outcome, CheckOutcome.offLine);
    expect(container.read(updateControllerProvider).hasUpdate, isFalse);
  });

  test('the 24-hour window skips automatic checks but not manual ones', () async {
    await setUpContainer();
    github.release = null;
    final controller = container.read(updateControllerProvider.notifier);

    await controller.check(manual: false);
    expect(github.calls, 1);

    expect(
      (await controller.check(manual: false)).outcome,
      CheckOutcome.skipped,
    );
    expect(github.calls, 1);

    // A manual check ignores the window.
    expect((await controller.check(manual: true)).outcome, CheckOutcome.upToDate);
    expect(github.calls, 2);
  });
}

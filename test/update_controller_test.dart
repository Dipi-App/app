import 'dart:io';

import 'package:dio/dio.dart' show CancelToken;
import 'package:dipi/core/providers/app_info_providers.dart';
import 'package:dipi/features/app_update/data/apk_installer.dart';
import 'package:dipi/features/app_update/data/checksum.dart';
import 'package:dipi/features/app_update/data/connectivity_service.dart';
import 'package:dipi/features/app_update/data/github_release_client.dart';
import 'package:dipi/features/app_update/data/update_download_service.dart';
import 'package:dipi/features/app_update/data/update_storage.dart';
import 'package:dipi/features/app_update/domain/app_release.dart';
import 'package:dipi/features/app_update/domain/release_asset.dart';
import 'package:dipi/features/app_update/domain/semantic_version.dart';
import 'package:dipi/features/app_update/domain/update_phase.dart';
import 'package:dipi/features/app_update/state/update_controller.dart';
import 'package:dipi/features/app_update/state/update_providers.dart';
import 'package:dipi/features/settings/domain/app_settings.dart';
import 'package:dipi/features/settings/state/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---- fakes ----

const _apkName = 'dipi-v1.2.0-arm64-v8a.apk';

AppRelease _release({bool withChecksum = true}) => AppRelease(
  tag: 'v1.2.0',
  version: const SemanticVersion(1, 2, 0),
  body: 'تازه‌ها',
  assets: [
    const ReleaseAsset(
      name: _apkName,
      sizeInBytes: 16,
      downloadUrl: 'https://github.com/a/$_apkName',
    ),
    if (withChecksum)
      const ReleaseAsset(
        name: '$_apkName.sha256',
        sizeInBytes: 70,
        downloadUrl: 'https://github.com/a/$_apkName.sha256',
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

class _FakeConnectivity extends ConnectivityService {
  _FakeConnectivity(this.value);
  NetworkStatus value;

  @override
  Future<NetworkStatus> status() async => value;
}

class _FakeStorage extends UpdateStorage {
  _FakeStorage() {
    dir = Directory.systemTemp.createTempSync('dipi-update-test');
  }

  late final Directory dir;
  StoredUpdate? pending;
  int deleteAllCalls = 0;

  StoredUpdate _copy(StoredUpdate s, {bool? complete, String? sha}) => StoredUpdate(
    tag: s.tag,
    version: s.version,
    notes: s.notes,
    apkName: s.apkName,
    url: s.url,
    checksumUrl: s.checksumUrl,
    expectedBytes: s.expectedBytes,
    expectedSha: sha ?? s.expectedSha,
    complete: complete ?? s.complete,
    apkFile: s.apkFile,
    metaFile: s.metaFile,
  );

  @override
  Future<Directory> directory() async => dir;

  @override
  Future<StoredUpdate> begin({
    required String tag,
    required String version,
    required String notes,
    required ReleaseAsset apk,
    required ReleaseAsset? checksum,
  }) async {
    final update = StoredUpdate(
      tag: tag,
      version: version,
      notes: notes,
      apkName: apk.name,
      url: apk.downloadUrl,
      checksumUrl: checksum?.downloadUrl ?? '',
      expectedBytes: apk.sizeInBytes,
      expectedSha: '',
      complete: false,
      apkFile: File('${dir.path}/${apk.name}'),
      metaFile: File('${dir.path}/meta.json'),
    );
    pending = update;
    return update;
  }

  @override
  Future<void> markVerified(StoredUpdate update, String expectedSha) async {
    pending = _copy(update, complete: true, sha: expectedSha);
  }

  @override
  Future<StoredUpdate?> loadPending() async => pending;

  @override
  Future<void> deleteAll() async {
    deleteAllCalls++;
    pending = null;
  }
}

class _FakeDownload extends UpdateDownloadService {
  _FakeDownload({this.checksumOf});
  final List<int>? checksumOf;
  final List<int> payload = const [1, 2, 3, 4, 5, 6, 7, 8];
  bool fail = false;

  @override
  Future<void> download({
    required Uri url,
    required File file,
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
    bool allowResume = true,
  }) async {
    if (fail) throw UpdateDownloadException('دانلود انجام نشد.');
    // Synchronous write keeps the test free of real async file I/O.
    file.writeAsBytesSync(payload, flush: true);
    onProgress(payload.length, payload.length);
  }

  @override
  Future<String> fetchChecksum(Uri url, {CancelToken? cancelToken}) async =>
      sha256OfBytes(checksumOf ?? payload);

  @override
  Future<String> hashOfFile(File file) async => sha256OfBytes(payload);
}

class _FakeInstaller extends ApkInstaller {
  bool can = true;
  bool opened = false;

  @override
  Future<bool> canInstall() async => can;

  @override
  Future<void> openInstallSettings() async {}

  @override
  Future<bool> launch(File apk) async {
    opened = true;
    return true;
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
  Future<void> waitForPhase(ProviderContainer container, UpdatePhase phase) async {
    for (var i = 0; i < 200; i++) {
      if (container.read(updateControllerProvider).phase == phase) return;
      await Future<void>.delayed(Duration.zero);
    }
    fail(
      'Timed out waiting for $phase; got '
      '${container.read(updateControllerProvider).phase}',
    );
  }

  late _FakeGitHub github;
  late _FakeConnectivity connectivity;
  late _FakeStorage storage;
  late _FakeDownload download;
  late _FakeInstaller installer;
  late _FakeSettings settings;
  late ProviderContainer container;

  Future<void> setUpContainer({
    NetworkStatus network = const NetworkStatus(
      onWifi: true,
      onMobile: false,
      online: true,
    ),
    AppSettings? appSettings,
    List<int>? checksumOf,
  }) async {
    github = _FakeGitHub();
    connectivity = _FakeConnectivity(network);
    storage = _FakeStorage();
    download = _FakeDownload(checksumOf: checksumOf);
    installer = _FakeInstaller();
    settings = _FakeSettings(appSettings ?? const AppSettings());

    container = ProviderContainer(
      overrides: [
        githubReleaseClientProvider.overrideWithValue(github),
        connectivityServiceProvider.overrideWithValue(connectivity),
        updateStorageProvider.overrideWithValue(storage),
        updateDownloadServiceProvider.overrideWithValue(download),
        apkInstallerProvider.overrideWithValue(installer),
        settingsControllerProvider.overrideWith(() => settings),
        deviceAbisProvider.overrideWith((ref) async => const ['arm64-v8a']),
        appVersionProvider.overrideWith((ref) async => '1.0.0+1'),
      ],
    );
    addTearDown(() {
      container.dispose();
      if (storage.dir.existsSync()) storage.dir.deleteSync(recursive: true);
    });
    await container.read(settingsControllerProvider.future);
  }

  test('Wi-Fi downloads by itself and reaches ready', () async {
    await setUpContainer();
    github.release = _release();
    final controller = container.read(updateControllerProvider.notifier);

    final outcome = await controller.checkForUpdates(manual: false);
    expect(outcome, CheckOutcome.found);

    await waitForPhase(container, UpdatePhase.ready);
    final state = container.read(updateControllerProvider);
    expect(state.phase, UpdatePhase.ready);
    expect(state.release?.version, const SemanticVersion(1, 2, 0));
  });

  test('mobile data waits in available, then a forced start downloads', () async {
    await setUpContainer(
      network: const NetworkStatus(onWifi: false, onMobile: true, online: true),
    );
    github.release = _release();
    final controller = container.read(updateControllerProvider.notifier);

    await controller.checkForUpdates(manual: false);
    expect(container.read(updateControllerProvider).phase, UpdatePhase.available);

    await controller.startDownload(force: true);
    expect(container.read(updateControllerProvider).phase, UpdatePhase.ready);
  });

  test('no newer release hides the icon and reports up to date', () async {
    await setUpContainer();
    github.release = null;
    final controller = container.read(updateControllerProvider.notifier);

    expect(await controller.checkForUpdates(manual: true), CheckOutcome.upToDate);
    expect(container.read(updateControllerProvider).phase, UpdatePhase.hidden);
  });

  test('a rate limit is quiet but reported', () async {
    await setUpContainer();
    github.error = GitHubReleaseException('rate', rateLimited: true);
    final controller = container.read(updateControllerProvider.notifier);

    expect(
      await controller.checkForUpdates(manual: true),
      CheckOutcome.rateLimited,
    );
    expect(container.read(updateControllerProvider).phase, UpdatePhase.hidden);
  });

  test('a bad checksum deletes the file and errors', () async {
    await setUpContainer(checksumOf: const [9, 9, 9]);
    github.release = _release();
    final controller = container.read(updateControllerProvider.notifier);

    await controller.checkForUpdates(manual: false);
    await waitForPhase(container, UpdatePhase.error);

    final state = container.read(updateControllerProvider);
    expect(state.phase, UpdatePhase.error);
    expect(state.errorMessage, contains('سالم نبود'));
    expect(storage.deleteAllCalls, greaterThan(0));
    expect(storage.pending, isNull);
  });

  test('the 6-hour window skips the second automatic check', () async {
    await setUpContainer();
    github.release = null;
    final controller = container.read(updateControllerProvider.notifier);

    await controller.checkForUpdates(manual: false);
    expect(github.calls, 1);

    expect(await controller.checkForUpdates(manual: false), CheckOutcome.skipped);
    expect(github.calls, 1);

    // A manual check ignores the window.
    expect(await controller.checkForUpdates(manual: true), CheckOutcome.upToDate);
    expect(github.calls, 2);
  });

  test('dismissing marks the session and blocks auto-open', () async {
    await setUpContainer();
    github.release = _release();
    final controller = container.read(updateControllerProvider.notifier);

    await controller.checkForUpdates(manual: false);
    await waitForPhase(container, UpdatePhase.ready);
    controller.dismissModal();
    expect(container.read(updateControllerProvider).dismissedThisSession, isTrue);
  });

  test('a partial download resumes on the next start', () async {
    await setUpContainer();
    // A previous run was closed mid-download.
    storage.pending = StoredUpdate(
      tag: 'v1.2.0',
      version: '1.2.0',
      notes: '',
      apkName: _apkName,
      url: 'https://github.com/a/$_apkName',
      checksumUrl: 'https://github.com/a/$_apkName.sha256',
      expectedBytes: 16,
      expectedSha: '',
      complete: false,
      apkFile: File('${storage.dir.path}/$_apkName')
        ..writeAsBytesSync(const [1, 2, 3]),
      metaFile: File('${storage.dir.path}/meta.json'),
    );
    final controller = container.read(updateControllerProvider.notifier);

    await controller.onAppStart();
    expect(container.read(updateControllerProvider).phase, UpdatePhase.ready);
  });

  test('install needs the unknown-sources permission first', () async {
    await setUpContainer();
    github.release = _release();
    installer.can = false;
    final controller = container.read(updateControllerProvider.notifier);

    await controller.checkForUpdates(manual: false);
    await waitForPhase(container, UpdatePhase.ready);
    expect(container.read(updateControllerProvider).phase, UpdatePhase.ready);

    expect(await controller.install(), InstallOutcome.needsPermission);
    expect(installer.opened, isFalse);

    installer.can = true;
    expect(await controller.install(), InstallOutcome.started);
    expect(installer.opened, isTrue);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/apk_installer.dart';
import '../data/connectivity_service.dart';
import '../data/device_abi.dart';
import '../data/github_release_client.dart';
import '../data/update_download_service.dart';
import '../data/update_storage.dart';
import '../domain/update_state.dart';
import 'update_controller.dart';

final githubReleaseClientProvider = Provider<GitHubReleaseClient>((ref) {
  final client = GitHubReleaseClient();
  ref.onDispose(client.dispose);
  return client;
});

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

final updateStorageProvider = Provider<UpdateStorage>(
  (ref) => UpdateStorage(),
);

final updateDownloadServiceProvider = Provider<UpdateDownloadService>((ref) {
  final service = UpdateDownloadService();
  ref.onDispose(service.dispose);
  return service;
});

final apkInstallerProvider = Provider<ApkInstaller>((ref) => ApkInstaller());

/// The phone's ABIs, used to choose the right APK.
final deviceAbisProvider = FutureProvider<List<String>>(
  (ref) => readDeviceAbis(),
);

final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

/// One-shot "نسخه جدید نصب شد" notice shown after an upgrade.
final updateInstalledNoticeProvider =
    NotifierProvider<UpdateInstalledNotice, String?>(
      UpdateInstalledNotice.new,
    );

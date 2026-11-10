import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/apk_update_installer.dart';
import '../data/github_release_client.dart';
import '../data/url_launcher_channel.dart';
import '../domain/update_state.dart';
import 'update_controller.dart';

final githubReleaseClientProvider = Provider<GitHubReleaseClient>((ref) {
  final client = GitHubReleaseClient();
  ref.onDispose(client.dispose);
  return client;
});

/// One installer for the app session: it owns the platform-channel handler
/// that receives download progress.
final apkUpdateInstallerProvider = Provider<ApkUpdateInstaller>((ref) {
  final installer = ApkUpdateInstaller();
  ref.onDispose(installer.dispose);
  return installer;
});

final urlLauncherProvider = Provider<UrlLauncherChannel>(
  (ref) => UrlLauncherChannel(),
);

final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

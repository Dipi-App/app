import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/github_release_client.dart';
import '../data/url_launcher_channel.dart';
import '../domain/update_state.dart';
import 'update_controller.dart';

final githubReleaseClientProvider = Provider<GitHubReleaseClient>((ref) {
  final client = GitHubReleaseClient();
  ref.onDispose(client.dispose);
  return client;
});

final urlLauncherProvider = Provider<UrlLauncherChannel>(
  (ref) => UrlLauncherChannel(),
);

final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

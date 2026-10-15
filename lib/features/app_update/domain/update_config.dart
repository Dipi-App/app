/// One place for the update source and its rules.
///
/// The owner and repo are read from the git remote:
/// `git@github.com:mst-ghi/dipi.git` -> owner `mst-ghi`, repo `dipi`.
abstract final class UpdateConfig {
  static const String githubOwner = 'mst-ghi';
  static const String githubRepo = 'dipi';

  static const String latestReleaseApi =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  /// At most one automatic check in this window. A manual check ignores it.
  static const Duration checkInterval = Duration(hours: 6);

  /// Only these hosts may serve the APK and its checksum.
  static const Set<String> allowedDownloadHosts = {
    'github.com',
    'www.github.com',
    'objects.githubusercontent.com',
    'github-releases.githubusercontent.com',
    'release-assets.githubusercontent.com',
  };

  /// The APK names the release workflow produces: `dipi-v1.2.0-<abi>.apk`
  /// and `dipi-v1.2.0-universal.apk`.
  static const String apkPrefix = 'dipi-';
  static const String universalAbi = 'universal';

  static bool isAllowedDownloadUrl(Uri url) =>
      url.scheme == 'https' && allowedDownloadHosts.contains(url.host);
}

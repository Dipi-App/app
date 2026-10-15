/// One place for the update source and its rules.
///
/// The owner and repo are read from the git remote:
/// `git@github.com:mst-ghi/dipi.git` -> owner `mst-ghi`, repo `dipi`.
abstract final class UpdateConfig {
  static const String githubOwner = 'mst-ghi';
  static const String githubRepo = 'dipi';

  static const String latestReleaseApi =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  /// The Releases page, used when a download link cannot be resolved.
  static const String releasesPageUrl =
      'https://github.com/$githubOwner/$githubRepo/releases/latest';

  /// Automatic checks run at most once in this window. A manual check ignores it.
  static const Duration checkInterval = Duration(hours: 24);

  /// Only these hosts may be opened in the browser, so a compromised API
  /// response can never redirect the user somewhere unexpected.
  static const Set<String> allowedLinkHosts = {
    'github.com',
    'www.github.com',
    'objects.githubusercontent.com',
    'github-releases.githubusercontent.com',
    'release-assets.githubusercontent.com',
  };

  static bool isAllowedLinkUrl(Uri url) =>
      url.scheme == 'https' && allowedLinkHosts.contains(url.host);
}

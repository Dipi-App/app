import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/app_release.dart';
import '../domain/update_config.dart';

class GitHubReleaseException implements Exception {
  GitHubReleaseException(this.message, {this.rateLimited = false});

  final String message;

  /// True for HTTP 403/429, i.e. GitHub rate limited us. Handled quietly.
  final bool rateLimited;

  @override
  String toString() => message;
}

/// Reads the newest published release from the GitHub REST API. No token.
///
/// Drafts and pre-releases are ignored, so the app never offers a test build.
class GitHubReleaseClient {
  GitHubReleaseClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  Future<AppRelease?> latest({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    http.Response response;
    try {
      response = await _http
          .get(
            Uri.parse(UpdateConfig.latestReleaseApi),
            headers: const {
              'Accept': 'application/vnd.github+json',
              'User-Agent': '${UpdateConfig.githubRepo}-android-updater',
              'X-GitHub-Api-Version': '2022-11-28',
            },
          )
          .timeout(timeout);
    } catch (_) {
      throw GitHubReleaseException('اتصال به اینترنت برقرار نشد.');
    }

    if (response.statusCode == 403 || response.statusCode == 429) {
      throw GitHubReleaseException('محدودیت موقت گیت‌هاب.', rateLimited: true);
    }
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw GitHubReleaseException('پاسخ نامنتظره از گیت‌هاب '
          '(${response.statusCode}).');
    }

    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw GitHubReleaseException('پاسخ گیت‌هاب خوانده نشد.');
    }
    if (decoded is! Map) return null;
    final json = decoded.cast<String, Object?>();
    if (json['draft'] == true || json['prerelease'] == true) return null;
    return AppRelease.fromJson(json);
  }

  void dispose() => _http.close();
}

import 'dart:convert';

import 'package:dipi/features/app_update/data/github_release_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

GitHubReleaseClient _client(Future<http.Response> Function(http.Request) handler) =>
    GitHubReleaseClient(client: MockClient(handler));

void main() {
  test('a missing repository is an error, not an up-to-date answer', () async {
    final client = _client((_) async => http.Response('{"message":"Not Found"}', 404));
    addTearDown(client.dispose);

    expect(
      () => client.latest(),
      throwsA(isA<GitHubReleaseException>()),
    );
  });

  test('429 is reported as rate limiting', () async {
    final client = _client((_) async => http.Response('', 429));
    addTearDown(client.dispose);

    await expectLater(
      client.latest(),
      throwsA(
        isA<GitHubReleaseException>().having(
          (error) => error.rateLimited,
          'rateLimited',
          isTrue,
        ),
      ),
    );
  });

  test('a release with an APK is parsed', () async {
    final body = jsonEncode({
      'tag_name': 'v1.8.0',
      'body': 'notes',
      'html_url': 'https://github.com/Dipi-App/app/releases/tag/v1.8.0',
      'draft': false,
      'prerelease': false,
      'assets': [
        {
          'name': 'dipi-1.8.0.apk',
          'size': 70,
          'browser_download_url':
              'https://github.com/Dipi-App/app/releases/download/v1.8.0/dipi-1.8.0.apk',
          'digest': 'sha256:abc',
        },
      ],
    });
    final client = _client((_) async => http.Response(body, 200));
    addTearDown(client.dispose);

    final release = await client.latest();
    expect(release?.tag, 'v1.8.0');
    expect(release?.apks.single.name, 'dipi-1.8.0.apk');
    expect(release?.apks.single.sha256, 'abc');
  });

  test('a draft release is ignored', () async {
    final body = jsonEncode({
      'tag_name': 'v9.0.0',
      'draft': true,
      'assets': const [],
    });
    final client = _client((_) async => http.Response(body, 200));
    addTearDown(client.dispose);

    expect(await client.latest(), isNull);
  });
}

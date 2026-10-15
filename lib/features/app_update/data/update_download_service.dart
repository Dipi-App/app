import 'dart:io';

import 'package:dio/dio.dart';

import '../domain/update_config.dart';
import 'checksum.dart';

class UpdateDownloadException implements Exception {
  UpdateDownloadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Real downloader: streams to a file and resumes with an HTTP `Range` header.
class UpdateDownloadService {
  UpdateDownloadService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              // No total receive timeout: a big APK on a slow link is fine.
              receiveTimeout: null,
              headers: const {'User-Agent': '${UpdateConfig.githubRepo}-updater'},
            ),
          );

  final Dio _dio;

  /// Downloads [url] into [file], continuing from whatever is already there.
  ///
  /// [onProgress] reports `(received, total)` where `total` may be -1 when the
  /// server does not tell us the size.
  Future<void> download({
    required Uri url,
    required File file,
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
    bool allowResume = true,
  }) async {
    if (!UpdateConfig.isAllowedDownloadUrl(url)) {
      throw UpdateDownloadException('نشانی دانلود معتبر نیست.');
    }
    final resumeFrom =
        allowResume && file.existsSync() ? file.lengthSync() : 0;
    final headers = <String, Object>{};
    if (resumeFrom > 0) headers['Range'] = 'bytes=$resumeFrom-';

    final Response<ResponseBody> response;
    try {
      response = await _dio.getUri<ResponseBody>(
        url,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
          followRedirects: true,
          validateStatus: (status) =>
              status == 200 || status == 206 || status == 416,
        ),
      );
    } on DioException catch (error) {
      throw UpdateDownloadException(_describe(error));
    }

    // The server could not honor our range: start over from an empty file.
    if (response.statusCode == 416 && resumeFrom > 0) {
      try {
        await file.writeAsBytes(const [], flush: true);
      } catch (_) {}
      return download(
        url: url,
        file: file,
        onProgress: onProgress,
        cancelToken: cancelToken,
        allowResume: false,
      );
    }

    final body = response.data;
    if (body == null) {
      throw UpdateDownloadException('پاسخ دانلود خالی بود.');
    }

    final isPartial = response.statusCode == 206 && resumeFrom > 0;
    final startAt = isPartial ? resumeFrom : 0;
    final contentLength = int.tryParse(
      response.headers.value(Headers.contentLengthHeader) ?? '',
    );
    final total = contentLength == null ? -1 : startAt + contentLength;

    RandomAccessFile handle;
    try {
      handle = await file.open(
        mode: isPartial ? FileMode.append : FileMode.write,
      );
    } on FileSystemException {
      throw UpdateDownloadException('نوشتن فایل دانلود ممکن نشد.');
    }

    var received = startAt;
    onProgress(received, total);
    try {
      await for (final chunk in body.stream) {
        handle.writeFromSync(chunk);
        received += chunk.length;
        onProgress(received, total);
      }
    } finally {
      await handle.close();
    }
  }

  /// Fetches and parses the release `.sha256` file.
  Future<String> fetchChecksum(Uri url, {CancelToken? cancelToken}) async {
    if (!UpdateConfig.isAllowedDownloadUrl(url)) {
      throw UpdateDownloadException('نشانی فایل بررسی معتبر نیست.');
    }
    try {
      final response = await _dio.getUri<String>(
        url,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status == 200,
        ),
      );
      final parsed = parseSha256File(response.data ?? '');
      if (parsed == null) {
        throw UpdateDownloadException('فایل بررسی خوانده نشد.');
      }
      return parsed;
    } on DioException catch (error) {
      throw UpdateDownloadException(_describe(error));
    }
  }

  Future<String> hashOfFile(File file) => sha256OfFile(file);

  String _describe(DioException error) {
    if (error.type == DioExceptionType.cancel) return 'دانلود لغو شد.';
    return 'دانلود انجام نشد. اتصال اینترنت را بررسی کنید.';
  }

  void dispose() => _dio.close(force: true);
}

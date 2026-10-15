import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_info.dart';

class DriveBackupException implements Exception {
  DriveBackupException(this.message, {this.needsSignIn = false});

  final String message;
  final bool needsSignIn;

  @override
  String toString() => message;
}

class DriveAccount {
  const DriveAccount({required this.email, this.displayName});

  final String email;
  final String? displayName;
}

class DriveBackupInfo {
  const DriveBackupInfo({
    required this.fileId,
    required this.modifiedAt,
    required this.sizeInBytes,
  });

  final String fileId;
  final DateTime modifiedAt;
  final int sizeInBytes;
}

/// Google Drive backup restricted to the hidden `drive.appdata` folder, using
/// the Drive REST API over the OAuth token that `google_sign_in` hands out.
///
/// No sign-up inside the app: Google login exists only to read and write this
/// one file, and the app cannot see anything else in the user's Drive.
class DriveBackupService {
  DriveBackupService({http.Client? client}) : _http = client ?? http.Client();

  static const String scope = 'https://www.googleapis.com/auth/drive.appdata';
  static const String backupFileName = 'dipi-backup.json';
  static const String _apiBase = 'https://www.googleapis.com/drive/v3/files';
  static const String _uploadBase =
      'https://www.googleapis.com/upload/drive/v3/files';

  final http.Client _http;
  GoogleSignInAccount? _account;
  bool _initialized = false;

  bool get isConfigured => AppInfo.googleBackupConfigured;

  DriveAccount? get currentAccount {
    final account = _account;
    if (account == null) return null;
    return DriveAccount(email: account.email, displayName: account.displayName);
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    if (!isConfigured) {
      throw DriveBackupException(
        'پشتیبان‌گیری گوگل‌درایو تنظیم نشده است. '
        'شناسه کلاینت OAuth را در راهنمای برنامه بسازید و هنگام ساخت برنامه '
        'با DIPI_GOOGLE_SERVER_CLIENT_ID معرفی کنید.',
      );
    }
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: AppInfo.googleServerClientId,
      );
      _initialized = true;
    } on GoogleSignInException catch (error) {
      throw DriveBackupException(
        'راه‌اندازی ورود گوگل ناموفق بود: ${error.description ?? error.code.name}',
      );
    }
  }

  /// Tries to reuse an existing Google session without showing any UI.
  Future<DriveAccount?> restoreSession() async {
    await _ensureInitialized();
    try {
      final attempt = GoogleSignIn.instance.attemptLightweightAuthentication();
      final account = attempt == null ? null : await attempt;
      if (account == null) return null;
      _account = account;
      return currentAccount;
    } on GoogleSignInException {
      return null;
    }
  }

  Future<DriveAccount> signIn() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      _account = account;
      return DriveAccount(
        email: account.email,
        displayName: account.displayName,
      );
    } on GoogleSignInException catch (error) {
      throw DriveBackupException(
        'ورود به گوگل انجام نشد: ${error.description ?? error.code.name}',
        needsSignIn: true,
      );
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    _account = null;
    await GoogleSignIn.instance.signOut();
  }

  Future<String> _accessToken({required bool interactive}) async {
    final account = _account;
    if (account == null) {
      throw DriveBackupException(
        'برای پشتیبان‌گیری گوگل‌درایو، اول وارد حساب گوگل شوید.',
        needsSignIn: true,
      );
    }
    try {
      final client = account.authorizationClient;
      if (!interactive) {
        final silent = await client.authorizationForScopes([scope]);
        if (silent != null) return silent.accessToken;
      }
      final authorization = await client.authorizeScopes([scope]);
      return authorization.accessToken;
    } on GoogleSignInException catch (error) {
      throw DriveBackupException(
        'اجازه دسترسی به گوگل‌درایو داده نشد: '
        '${error.description ?? error.code.name}',
        needsSignIn: true,
      );
    }
  }

  Map<String, String> _headers(String token, {String? contentType}) => {
    'Authorization': 'Bearer $token',
    'Content-Type': ?contentType,
  };

  /// Finds the single backup file inside the hidden app data folder.
  Future<DriveBackupInfo?> latestBackup({bool interactive = false}) async {
    final token = await _accessToken(interactive: interactive);
    final uri = Uri.parse(_apiBase).replace(
      queryParameters: {
        'spaces': 'appDataFolder',
        'q': "name = '$backupFileName' and trashed = false",
        'fields': 'files(id,name,modifiedTime,size)',
        'pageSize': '10',
      },
    );
    final response = await _http.get(uri, headers: _headers(token));
    _ensureSuccess(response, 'خواندن فهرست پشتیبان‌ها');
    final body = _decode(response);
    final files = (body['files'] as List?) ?? const [];
    if (files.isEmpty) return null;
    final file = files.first as Map;
    return DriveBackupInfo(
      fileId: file['id'] as String,
      modifiedAt:
          DateTime.tryParse(file['modifiedTime'] as String? ?? '') ??
          DateTime.now(),
      sizeInBytes: int.tryParse('${file['size'] ?? 0}') ?? 0,
    );
  }

  /// Uploads [json] to Drive, replacing the previous backup.
  Future<DriveBackupInfo> upload(
    String json, {
    bool interactive = false,
  }) async {
    final token = await _accessToken(interactive: interactive);
    final bytes = utf8.encode(json);
    final existing = await latestBackup(interactive: interactive);

    final String fileId;
    if (existing == null) {
      final response = await _http.post(
        Uri.parse(_apiBase),
        headers: _headers(token, contentType: 'application/json; charset=UTF-8'),
        body: jsonEncode({
          'name': backupFileName,
          'parents': ['appDataFolder'],
        }),
      );
      _ensureSuccess(response, 'ساخت فایل پشتیبان در درایو');
      fileId = (_decode(response)['id'] as String);
    } else {
      fileId = existing.fileId;
    }

    final uploadResponse = await _http.patch(
      Uri.parse('$_uploadBase/$fileId').replace(
        queryParameters: {'uploadType': 'media', 'fields': 'id,modifiedTime,size'},
      ),
      headers: _headers(token, contentType: 'application/json; charset=UTF-8'),
      body: bytes,
    );
    _ensureSuccess(uploadResponse, 'بارگذاری پشتیبان');
    final uploaded = _decode(uploadResponse);
    return DriveBackupInfo(
      fileId: fileId,
      modifiedAt:
          DateTime.tryParse(uploaded['modifiedTime'] as String? ?? '') ??
          DateTime.now(),
      sizeInBytes:
          int.tryParse('${uploaded['size'] ?? bytes.length}') ?? bytes.length,
    );
  }

  /// Downloads the backup JSON. Throws when there is nothing to restore.
  Future<String> download({bool interactive = false}) async {
    final info = await latestBackup(interactive: interactive);
    if (info == null) {
      throw DriveBackupException('در گوگل‌درایو پشتیبانی پیدا نشد.');
    }
    final token = await _accessToken(interactive: interactive);
    final response = await _http.get(
      Uri.parse('$_apiBase/${info.fileId}').replace(
        queryParameters: {'alt': 'media'},
      ),
      headers: _headers(token),
    );
    _ensureSuccess(response, 'دانلود پشتیبان');
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  Map<String, Object?> _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return const {};
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return decoded is Map ? decoded.cast<String, Object?>() : const {};
  }

  void _ensureSuccess(http.Response response, String what) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.statusCode == 401) {
      throw DriveBackupException(
        'نشست گوگل منقضی شده است؛ دوباره وارد شوید.',
        needsSignIn: true,
      );
    }
    if (response.statusCode == 403) {
      throw DriveBackupException(
        'گوگل اجازه «$what» را نداد. مطمئن شوید در Google Cloud '
        'سرویس Drive API فعال است و کاربر آزمایشی افزوده شده است.',
      );
    }
    throw DriveBackupException(
      '$what ناموفق بود (کد ${response.statusCode}).',
    );
  }

  void dispose() => _http.close();
}

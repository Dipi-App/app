import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// The phone's CPU ABIs, best-first, e.g. `['arm64-v8a', 'armeabi-v7a']`.
///
/// Empty when the info is unavailable (non-Android, tests); the caller then
/// falls back to the universal APK.
Future<List<String>> readDeviceAbis() async {
  try {
    if (!Platform.isAndroid) return const [];
    final info = await DeviceInfoPlugin().androidInfo;
    return info.supportedAbis;
  } catch (_) {
    return const [];
  }
}

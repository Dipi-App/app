import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes [bytes] to the app cache and hands the file to the system share sheet.
Future<void> shareBytes({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
  String? subject,
  String? text,
}) async {
  final file = await _writeToCache(fileName, bytes);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: mimeType, name: fileName)],
      subject: subject,
      text: text,
      title: subject,
      fileNameOverrides: [fileName],
    ),
  );
}

/// Opens the system "save as" dialog (SAF on Android). Returns the saved path
/// or null when the user cancelled.
Future<String?> saveBytesAs({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
  String? dialogTitle,
}) async {
  final uri = await FilePicker.saveFile(
    fileName: fileName,
    bytes: Uint8List.fromList(bytes),
    mimeType: mimeType,
    dialogTitle: dialogTitle,
  );
  return uri?.toString();
}

Future<File> _writeToCache(String fileName, List<int> bytes) async {
  final directory = await getTemporaryDirectory();
  final file = File(p.join(directory.path, fileName));
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

/// Human readable file size for the UI.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes بایت';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} کیلوبایت';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} مگابایت';
}

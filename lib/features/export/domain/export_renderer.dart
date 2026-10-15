import 'dart:convert';

import 'docx_writer.dart';
import 'export_blocks.dart';
import 'export_data.dart';
import 'export_text.dart';

class ExportFile {
  const ExportFile({
    required this.fileName,
    required this.bytes,
    required this.mimeType,
  });

  final String fileName;
  final List<int> bytes;
  final String mimeType;

  int get sizeInBytes => bytes.length;

  /// Only meaningful for the text formats; the UI shows it as a preview.
  String? get textPreview =>
      mimeType.startsWith('text/') ? utf8.decode(bytes, allowMalformed: true) : null;
}

/// Renders the report in the requested format. Pure — no IO, so it is easy to
/// unit test.
ExportFile renderExport(ExportData data, ExportFormat format) {
  final blocks = exportBlocks(data);
  final List<int> bytes;
  switch (format) {
    case ExportFormat.txt:
      // A UTF-8 BOM makes Windows Notepad and older editors read the Persian
      // text as UTF-8 instead of the system code page.
      bytes = [
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode(renderPlainText(blocks)),
      ];
    case ExportFormat.markdown:
      bytes = utf8.encode(renderMarkdown(blocks));
    case ExportFormat.docx:
      bytes = const DocxWriter().write(blocks);
  }

  return ExportFile(
    fileName: '${data.fileStem}.${format.extension}',
    bytes: bytes,
    mimeType: format.mimeType,
  );
}

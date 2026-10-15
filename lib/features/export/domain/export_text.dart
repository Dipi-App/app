import 'export_blocks.dart';

/// Plain text and markdown renderers for the shared export blocks.
///
/// Plain text has no direction metadata, so every line starts with a
/// right-to-left mark (U+200F) which makes editors that default to LTR lay the
/// Persian lines out correctly.
class _TxtWriter {
  const _TxtWriter();

  static const String rlm = '\u200F';

  String write(List<ExportBlock> blocks) {
    final lines = <String>[];
    for (final block in blocks) {
      switch (block) {
        case ExportHeading(:final text, :final level):
          lines.add('');
          lines.add(rlm + text);
          lines.add(rlm + (level == 1 ? '═' * text.length : '─' * text.length));
        case ExportParagraph(:final text, :final bold):
          lines.add(rlm + (bold ? '▪ $text' : text));
        case ExportKeyValues(:final rows):
          for (final (label, value) in rows) {
            lines.add('$rlm  $label: $value');
          }
        case ExportBullets(:final items):
          for (final item in items) {
            lines.add('$rlm    • $item');
          }
        case ExportDivider():
          lines.add(rlm + ('-' * 40));
      }
    }
    return '${lines.join('\n')}\n';
  }
}

String renderPlainText(List<ExportBlock> blocks) => const _TxtWriter().write(blocks);

/// Markdown has no direction flag either, so the whole report sits inside a
/// `dir="rtl"` block that GitHub, editors and print-to-PDF all understand.
String renderMarkdown(List<ExportBlock> blocks) {
  final lines = <String>['<div dir="rtl" align="right">', ''];
  for (final block in blocks) {
    switch (block) {
      case ExportHeading(:final text, :final level):
        lines
          ..add('')
          ..add('${'#' * level} $text');
      case ExportParagraph(:final text, :final bold):
        lines
          ..add('')
          ..add(bold ? '**$text**' : text);
      case ExportKeyValues(:final rows):
        lines
          ..add('')
          ..add('| مورد | مقدار |')
          ..add('| --- | --- |');
        for (final (label, value) in rows) {
          lines.add('| $label | $value |');
        }
      case ExportBullets(:final items):
        lines.add('');
        for (final item in items) {
          lines.add('- $item');
        }
      case ExportDivider():
        lines
          ..add('')
          ..add('---');
    }
  }
  lines
    ..add('')
    ..add('</div>')
    ..add('');
  return lines.join('\n');
}

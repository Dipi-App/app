import 'dart:convert';

import 'package:archive/archive.dart';

import 'export_blocks.dart';

/// Builds a .docx by hand (raw OOXML) instead of pulling in a docx package.
///
/// Right-to-left is set in three places so Persian renders correctly in Word,
/// LibreOffice, Google Docs and WPS:
///  * `w:docDefaults` — default paragraph `w:bidi` and run `w:rtl`
///  * every paragraph — `w:pPr/w:bidi` + `w:jc w:val="right"`
///  * every run — `w:rPr/w:rtl` and the complex-script font (`w:cs`)
///
/// Tables use `w:bidiVisual` so the first column sits on the right.
class DocxWriter {
  const DocxWriter();

  static const String _font = 'Vazirmatn';
  static const String _fallbackFont = 'Tahoma';
  static const int _bodySize = 22; // half-points → 11pt
  static const int _headingSize = 30;

  List<int> write(List<ExportBlock> blocks) {
    final archive = Archive()
      ..addFile(_file('[Content_Types].xml', _contentTypes))
      ..addFile(_file('_rels/.rels', _rootRels))
      ..addFile(_file('word/document.xml', _document(blocks)))
      ..addFile(_file('word/styles.xml', _styles))
      ..addFile(_file('word/_rels/document.xml.rels', _documentRels))
      ..addFile(_file('docProps/core.xml', _coreProps))
      ..addFile(_file('docProps/app.xml', _appProps));
    return ZipEncoder().encode(archive);
  }

  ArchiveFile _file(String path, String content) {
    final bytes = utf8.encode(content);
    return ArchiveFile(path, bytes.length, bytes);
  }

  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll('\r\n', '\n')
      .replaceAll('\n', ' ');

  String _run(
    String text, {
    bool bold = false,
    int? size,
    String? color,
  }) {
    final buffer = StringBuffer('<w:r><w:rPr>')
      ..write(
        '<w:rFonts w:ascii="$_font" w:hAnsi="$_font" w:cs="$_font" '
        'w:eastAsia="$_font"/>',
      );
    if (bold) buffer.write('<w:b/><w:bCs/>');
    buffer.write('<w:rtl/>');
    final fontSize = size ?? _bodySize;
    buffer.write('<w:sz w:val="$fontSize"/><w:szCs w:val="$fontSize"/>');
    if (color != null) buffer.write('<w:color w:val="$color"/>');
    buffer
      ..write('</w:rPr>')
      ..write('<w:t xml:space="preserve">${_escape(text)}</w:t>')
      ..write('</w:r>');
    return buffer.toString();
  }

  String _paragraph(
    String runsXml, {
    String? style,
    int? before,
    int? after,
    bool indent = false,
  }) {
    final buffer = StringBuffer('<w:p><w:pPr><w:bidi/><w:jc w:val="right"/>')
      ..write(
        '<w:pStyle w:val="${style ?? 'Normal'}"/>',
      );
    if (before != null || after != null) {
      buffer.write(
        '<w:spacing w:before="${before ?? 0}" w:after="${after ?? 0}"/>',
      );
    }
    if (indent) {
      buffer.write('<w:ind w:right="360" w:hanging="240"/>');
    }
    buffer
      ..write('</w:pPr>')
      ..write(runsXml)
      ..write('</w:p>');
    return buffer.toString();
  }

  String _textParagraph(
    String text, {
    bool bold = false,
    int? size,
    String? color,
    int? before,
    int? after,
    bool indent = false,
  }) => _paragraph(
    _run(text, bold: bold, size: size, color: color),
    before: before,
    after: after,
    indent: indent,
  );

  String _bullet(String text) => _paragraph(
    _run('• ', size: _bodySize) + _run(text),
    after: 40,
    indent: true,
  );

  String _table(List<(String, String)> rows) {
    final buffer = StringBuffer('<w:tbl><w:tblPr>')
      ..write('<w:tblW w:w="9600" w:type="dxa"/>')
      ..write(
        '<w:tblBorders>'
        '<w:top w:val="single" w:sz="4" w:color="D8D8D8"/>'
        '<w:left w:val="single" w:sz="4" w:color="D8D8D8"/>'
        '<w:bottom w:val="single" w:sz="4" w:color="D8D8D8"/>'
        '<w:right w:val="single" w:sz="4" w:color="D8D8D8"/>'
        '<w:insideH w:val="single" w:sz="4" w:color="D8D8D8"/>'
        '<w:insideV w:val="single" w:sz="4" w:color="D8D8D8"/>'
        '</w:tblBorders>',
      )
      // Makes the first column the rightmost one.
      ..write('<w:bidiVisual/>')
      ..write('<w:tblCellMar>')
      ..write('<w:top w:w="60" w:type="dxa"/><w:left w:w="120" w:type="dxa"/>')
      ..write('<w:bottom w:w="60" w:type="dxa"/><w:right w:w="120" w:type="dxa"/>')
      ..write('</w:tblCellMar>')
      ..write('</w:tblPr>')
      ..write('<w:tblGrid><w:gridCol w:w="3200"/><w:gridCol w:w="6400"/></w:tblGrid>');

    for (final (label, value) in rows) {
      buffer
        ..write('<w:tr>')
        ..write(
          '<w:tc><w:tcPr><w:tcW w:w="3200" w:type="dxa"/></w:tcPr>'
          '${_textParagraph(label, bold: true)}</w:tc>',
        )
        ..write(
          '<w:tc><w:tcPr><w:tcW w:w="6400" w:type="dxa"/></w:tcPr>'
          '${_textParagraph(value)}</w:tc>',
        )
        ..write('</w:tr>');
    }

    buffer.write('</w:tbl>');
    return buffer.toString();
  }

  String _document(List<ExportBlock> blocks) {
    final body = StringBuffer();
    for (final block in blocks) {
      switch (block) {
        case ExportHeading(:final text, :final level):
          body.write(
            _textParagraph(
              text,
              bold: true,
              size: level == 1 ? _headingSize + 6 : _headingSize,
              color: '1F5C52',
              before: 240,
              after: 80,
            ),
          );
        case ExportParagraph(:final text, :final bold):
          body.write(_textParagraph(text, bold: bold, after: 60));
        case ExportKeyValues(:final rows):
          if (rows.isNotEmpty) body.write(_table(rows));
        case ExportBullets(:final items):
          for (final item in items) {
            body.write(_bullet(item));
          }
        case ExportDivider():
          body.write(_textParagraph('────────────────────────────', color: 'BBBBBB'));
      }
    }
    // Word wants a paragraph after a table that ends the body.
    body.write(_textParagraph(''));

    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document '
        'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<w:body>$body'
        '<w:sectPr><w:bidi/>'
        '<w:pgSz w:w="11906" w:h="16838"/>'
        '<w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134" '
        'w:header="708" w:footer="708" w:gutter="0"/>'
        '</w:sectPr>'
        '</w:body></w:document>';
  }

  static const String _contentTypes =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
      '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
      '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>'
      '</Types>';

  static const String _rootRels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
      '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>'
      '</Relationships>';

  static const String _documentRels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>';

  static final String _coreProps =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<cp:coreProperties '
      'xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
      'xmlns:dc="http://purl.org/dc/elements/1.1/" '
      'xmlns:dcterms="http://purl.org/dc/terms/" '
      'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
      '<dc:title>گزارش روزکار و حساب</dc:title>'
      '<dc:creator>دیپی</dc:creator>'
      '<cp:lastModifiedBy>دیپی</cp:lastModifiedBy>'
      '</cp:coreProperties>';

  static const String _appProps =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" '
      'xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">'
      '<Application>Dipi</Application>'
      '</Properties>';

  static final String _styles =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:docDefaults>'
      '<w:rPrDefault><w:rPr>'
      '<w:rFonts w:ascii="$_font" w:hAnsi="$_font" w:cs="$_font" w:eastAsia="$_font"/>'
      '<w:rtl/><w:sz w:val="$_bodySize"/><w:szCs w:val="$_bodySize"/>'
      '</w:rPr></w:rPrDefault>'
      '<w:pPrDefault><w:pPr><w:bidi/><w:jc w:val="right"/></w:pPr></w:pPrDefault>'
      '</w:docDefaults>'
      '<w:style w:type="paragraph" w:default="1" w:styleId="Normal">'
      '<w:name w:val="Normal"/><w:qFormat/>'
      '<w:pPr><w:bidi/><w:jc w:val="right"/></w:pPr>'
      '<w:rPr>'
      '<w:rFonts w:ascii="$_font" w:hAnsi="$_font" w:cs="$_font"/>'
      '<w:rtl/><w:sz w:val="$_bodySize"/><w:szCs w:val="$_bodySize"/>'
      '</w:rPr></w:style>'
      '</w:styles>';

  /// Fallback font name, exposed so the UI can explain what Word will use when
  /// Vazirmatn is not installed on the reader's machine.
  static String get fallbackFont => _fallbackFont;
}

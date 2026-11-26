import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:universal_io/io.dart';
import 'dart:typed_data';

/// Document Export Service for exporting structured markdown plans and analyses
/// into publication-ready PDF, Word (.docx), or Markdown (.md) documents.
class DocumentExportService {
  /// Color accent used for export highlights (matches TealKit / ThiesCoder accent).
  static const Color accentOrange = Color(0xFFEA580C);

  /// Checks whether [content] represents a structured plan or analysis suitable for export.
  static bool isExportableAnalysisOrPlan(String content, {String? mode}) {
    if (content.trim().length < 60) return false;

    final lower = content.toLowerCase();
    final isPlanOrAsk = (mode == '/plan' || mode == '/ask');

    // Markdown headings (#, ##, ###)
    final hasHeadings = RegExp(r'(^|\n)#{1,4}\s+', multiLine: true).hasMatch(content);

    // Numbered sections like "1. Root Cause Analysis", "2. Proposed Architecture"
    final hasNumberedSections = RegExp(r'(^|\n)\d+\.\s+[A-Z]').hasMatch(content);

    // Bullet lists
    final hasBulletLists = RegExp(r'(^|\n)\s*[\*\-]\s+').hasMatch(content);

    // Common plan & analysis keywords
    final hasKeywords = lower.contains('plan') ||
        lower.contains('analysis') ||
        lower.contains('architect') ||
        lower.contains('root cause') ||
        lower.contains('recommend') ||
        lower.contains('overview') ||
        lower.contains('investigation') ||
        lower.contains('summary') ||
        lower.contains('checklist') ||
        lower.contains('benchmark') ||
        lower.contains('strategy') ||
        lower.contains('task');

    if (isPlanOrAsk) {
      return hasHeadings || hasNumberedSections || (hasBulletLists && hasKeywords) || hasKeywords;
    }

    // In other modes (/code), require explicit headings or numbered sections plus keywords
    return (hasHeadings || hasNumberedSections) && hasKeywords;
  }

  /// Exports [markdownContent] by displaying an interactive export dialog where the user can:
  /// 1. Choose or change the target folder via folder chooser
  /// 2. Edit or customize the filename
  /// 3. Select or switch the export format (PDF, Word, Markdown)
  static Future<void> exportDocument({
    required BuildContext context,
    required String markdownContent,
    required String format, // 'pdf', 'docx', 'md'
    String? workspaceDirectory,
  }) async {
    final title = _extractDocumentTitle(markdownContent);
    final defaultDir = await _resolveDefaultDirectory(workspaceDirectory);
    if (!context.mounted) return;

    final savedPath = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ExportDocumentDialog(
        initialTitle: title,
        markdownContent: markdownContent,
        initialFormat: format,
        defaultDirectory: defaultDir,
      ),
    );

    if (savedPath != null && savedPath.isNotEmpty && context.mounted) {
      final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
      final isContentUri = savedPath.startsWith('content://');
      final displayName = isContentUri
          ? Uri.decodeComponent(savedPath.split('/').last)
          : p.basename(savedPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Exported to $displayName'),
              ),
            ],
          ),
          duration: const Duration(seconds: 6),
          action: isContentUri
              ? null
              : SnackBarAction(
                  label: isMobile ? 'Share' : 'Open',
                  textColor: accentOrange,
                  onPressed: () {
                    _openExportedFile(savedPath);
                  },
                ),
        ),
      );
    }
  }

  static bool _isWritableDirectory(String dirPath) {
    try {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) return false;
      final probe = File(p.join(dirPath, '.export_probe_${DateTime.now().microsecondsSinceEpoch}'));
      probe.writeAsBytesSync(const []);
      probe.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String> _resolveDefaultDirectory(String? workspaceDirectory) async {
    if (kIsWeb) return '';

    if (workspaceDirectory != null &&
        workspaceDirectory.isNotEmpty &&
        _isWritableDirectory(workspaceDirectory)) {
      return workspaceDirectory;
    }

    try {
      if (Platform.isAndroid) {
        const publicDocs = '/storage/emulated/0/Documents';
        if (_isWritableDirectory(publicDocs)) return publicDocs;
        final extDir = await getExternalStorageDirectory();
        if (extDir != null && extDir.existsSync()) return extDir.path;
        final appDocs = await getApplicationDocumentsDirectory();
        return appDocs.path;
      }

      if (Platform.isIOS) {
        final appDocs = await getApplicationDocumentsDirectory();
        return appDocs.path;
      }

      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          final docs = p.join(userProfile, 'Documents');
          if (Directory(docs).existsSync()) return docs;
          final downloads = p.join(userProfile, 'Downloads');
          if (Directory(downloads).existsSync()) return downloads;
        }
        final appDocs = await getApplicationDocumentsDirectory();
        return appDocs.path;
      }

      if (Platform.isMacOS || Platform.isLinux) {
        final home = Platform.environment['HOME'];
        if (home != null) {
          final docs = p.join(home, 'Documents');
          if (_isWritableDirectory(docs)) return docs;
        }
        final appDocs = await getApplicationDocumentsDirectory();
        return appDocs.path;
      }
    } catch (_) {}

    return Directory.current.path;
  }

  static Future<void> _openExportedFile(String filePath) async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath)],
            text: p.basename(filePath),
          ),
        );
      } else if (Platform.isWindows) {
        await Process.run('cmd.exe', ['/c', 'start', '', filePath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
      } else {
        await Process.run('xdg-open', [filePath]);
      }
    } catch (_) {}
  }

  /// Extracts a human-readable title from the first heading or line of markdown.
  static String _extractDocumentTitle(String markdown) {
    final lines = markdown.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#')) {
        return trimmed.replaceFirst(RegExp(r'^#+\s*'), '').replaceAll(RegExp(r'[\*`_]'), '').trim();
      }
      if (RegExp(r'^\d+\.\s+[A-Za-z]').hasMatch(trimmed)) {
        return trimmed.replaceFirst(RegExp(r'^\d+\.\s*'), '').replaceAll(RegExp(r'[\*`_]'), '').trim();
      }
    }
    return 'Analysis & Implementation Plan';
  }

  // ─────────────────────────────────────────────────────────────
  // Pure-Dart Microsoft Word (.docx) Generator using archive
  // ─────────────────────────────────────────────────────────────

  /// Generates a valid Microsoft Word (.docx) file from markdown using `archive`.
  static Uint8List generateDocx({required String title, required String markdown}) {
    final archive = Archive();

    ArchiveFile createEntry(String name, String xmlContent) {
      final bytes = utf8.encode(xmlContent);
      return ArchiveFile(name, bytes.length, bytes);
    }

    // 1. [Content_Types].xml
    const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';
    archive.addFile(createEntry('[Content_Types].xml', contentTypesXml));

    // 2. _rels/.rels
    const rootRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    archive.addFile(createEntry('_rels/.rels', rootRelsXml));

    // 3. word/_rels/document.xml.rels
    const docRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
    archive.addFile(createEntry('word/_rels/document.xml.rels', docRelsXml));

    // 4. word/styles.xml
    final stylesXml = _buildDocxStylesXml();
    archive.addFile(createEntry('word/styles.xml', stylesXml));

    // 5. word/document.xml
    final docXml = _buildDocxDocumentXml(title, markdown);
    archive.addFile(createEntry('word/document.xml', docXml));

    // Encode to ZIP bytes
    final zipEncoder = ZipEncoder();
    final encoded = zipEncoder.encode(archive);
    return Uint8List.fromList(encoded);
  }

  static String _buildDocxStylesXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
          xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Segoe UI" w:hAnsi="Segoe UI" w:cs="Segoe UI"/>
        <w:color w:val="2C3E50"/>
        <w:sz w:val="22"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:after="160" w:line="276" w:lineRule="auto"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:uiPriority w:val="9"/>
    <w:qFormat/>
    <w:pPr>
      <w:spacing w:before="360" w:after="140"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Segoe UI Semibold" w:hAnsi="Segoe UI Semibold"/>
      <w:b/>
      <w:color w:val="EA580C"/>
      <w:sz w:val="34"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:uiPriority w:val="9"/>
    <w:qFormat/>
    <w:pPr>
      <w:spacing w:before="260" w:after="100"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Segoe UI Semibold" w:hAnsi="Segoe UI Semibold"/>
      <w:b/>
      <w:color w:val="0D9488"/>
      <w:sz w:val="28"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading3">
    <w:name w:val="heading 3"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:uiPriority w:val="9"/>
    <w:qFormat/>
    <w:pPr>
      <w:spacing w:before="200" w:after="80"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Segoe UI Semibold" w:hAnsi="Segoe UI Semibold"/>
      <w:b/>
      <w:color w:val="1E293B"/>
      <w:sz w:val="24"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="ListBullet">
    <w:name w:val="List Bullet"/>
    <w:basedOn w:val="Normal"/>
    <w:uiPriority w:val="10"/>
    <w:qFormat/>
    <w:pPr>
      <w:spacing w:after="100"/>
      <w:ind w:left="540"/>
    </w:pPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CodeBlock">
    <w:name w:val="Code Block"/>
    <w:basedOn w:val="Normal"/>
    <w:uiPriority w:val="11"/>
    <w:pPr>
      <w:shd w:val="clear" w:color="auto" w:fill="F1F5F9"/>
      <w:spacing w:before="60" w:after="60" w:line="240" w:lineRule="auto"/>
      <w:ind w:left="400" w:right="400"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/>
      <w:color w:val="0F172A"/>
      <w:sz w:val="19"/>
    </w:rPr>
  </w:style>
</w:styles>''';
  }

  static String _buildDocxDocumentXml(String title, String markdown) {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buf.writeln('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"');
    buf.writeln('            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"');
    buf.writeln('            xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math">');
    buf.writeln('  <w:body>');

    // Title paragraph
    buf.writeln('    <w:p>');
    buf.writeln('      <w:pPr><w:pStyle w:val="Heading1"/></w:pPr>');
    buf.writeln('      <w:r><w:t>${_xmlEscape(title)}</w:t></w:r>');
    buf.writeln('    </w:p>');

    final lines = markdown.split('\n');
    bool inCodeBlock = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        continue;
      }

      if (inCodeBlock) {
        buf.writeln('    <w:p>');
        buf.writeln('      <w:pPr><w:pStyle w:val="CodeBlock"/></w:pPr>');
        buf.writeln('      <w:r><w:t xml:space="preserve">${_xmlEscape(line)}</w:t></w:r>');
        buf.writeln('    </w:p>');
        continue;
      }

      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('# ')) {
        final text = trimmed.substring(2).trim();
        buf.writeln('    <w:p>');
        buf.writeln('      <w:pPr><w:pStyle w:val="Heading1"/></w:pPr>');
        buf.writeln('      <w:r><w:t>${_xmlEscape(text)}</w:t></w:r>');
        buf.writeln('    </w:p>');
      } else if (trimmed.startsWith('## ')) {
        final text = trimmed.substring(3).trim();
        buf.writeln('    <w:p>');
        buf.writeln('      <w:pPr><w:pStyle w:val="Heading2"/></w:pPr>');
        buf.writeln('      <w:r><w:t>${_xmlEscape(text)}</w:t></w:r>');
        buf.writeln('    </w:p>');
      } else if (trimmed.startsWith('### ') || trimmed.startsWith('#### ')) {
        final text = trimmed.replaceFirst(RegExp(r'^#+\s*'), '').trim();
        buf.writeln('    <w:p>');
        buf.writeln('      <w:pPr><w:pStyle w:val="Heading3"/></w:pPr>');
        buf.writeln('      <w:r><w:t>${_xmlEscape(text)}</w:t></w:r>');
        buf.writeln('    </w:p>');
      } else if (RegExp(r'^[\*\-]\s+').hasMatch(trimmed)) {
        final text = trimmed.replaceFirst(RegExp(r'^[\*\-]\s+'), '');
        buf.writeln('    <w:p>');
        buf.writeln('      <w:pPr><w:pStyle w:val="ListBullet"/></w:pPr>');
        _appendFormattedDocxRuns(buf, text);
        buf.writeln('    </w:p>');
      } else if (RegExp(r'^\d+\.\s+').hasMatch(trimmed)) {
        final text = trimmed.replaceFirst(RegExp(r'^\d+\.\s+'), '');
        final numMatch = RegExp(r'^(\d+)\.').firstMatch(trimmed);
        final numPrefix = numMatch != null ? '${numMatch.group(1)}. ' : '• ';
        buf.writeln('    <w:p>');
        buf.writeln('      <w:pPr><w:pStyle w:val="ListBullet"/></w:pPr>');
        buf.writeln('      <w:r><w:rPr><w:b/></w:rPr><w:t>${_xmlEscape(numPrefix)}</w:t></w:r>');
        _appendFormattedDocxRuns(buf, text);
        buf.writeln('    </w:p>');
      } else {
        buf.writeln('    <w:p>');
        buf.writeln('      <w:pPr><w:pStyle w:val="Normal"/></w:pPr>');
        _appendFormattedDocxRuns(buf, trimmed);
        buf.writeln('    </w:p>');
      }
    }

    buf.writeln('    <w:sectPr>');
    buf.writeln('      <w:pgSz w:w="11906" w:h="16838"/>'); // A4 in dxa
    buf.writeln('      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/>');
    buf.writeln('    </w:sectPr>');
    buf.writeln('  </w:body>');
    buf.writeln('</w:document>');
    return buf.toString();
  }

  static void _appendFormattedDocxRuns(StringBuffer buf, String text) {
    final tokens = _tokenizeMarkdownInline(text);
    for (final tok in tokens) {
      buf.write('      <w:r>');
      if (tok.isBold || tok.isItalic || tok.isCode) {
        buf.write('<w:rPr>');
        if (tok.isBold) buf.write('<w:b/>');
        if (tok.isItalic) buf.write('<w:i/>');
        if (tok.isCode) {
          buf.write('<w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/>');
          buf.write('<w:shd w:val="clear" w:color="auto" w:fill="F1F5F9"/>');
          buf.write('<w:color w:val="EA580C"/>');
        }
        buf.write('</w:rPr>');
      }
      buf.writeln('<w:t xml:space="preserve">${_xmlEscape(tok.text)}</w:t></w:r>');
    }
  }

  static List<_InlineToken> _tokenizeMarkdownInline(String text) {
    final list = <_InlineToken>[];
    final regex = RegExp(r'(\*\*[^\*]+\*\*|\*[^\*]+\*|`[^`]+`)');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        list.add(_InlineToken(text.substring(lastIndex, match.start)));
      }
      final raw = match.group(0)!;
      if (raw.startsWith('**') && raw.endsWith('**')) {
        list.add(_InlineToken(raw.substring(2, raw.length - 2), isBold: true));
      } else if (raw.startsWith('*') && raw.endsWith('*')) {
        list.add(_InlineToken(raw.substring(1, raw.length - 1), isItalic: true));
      } else if (raw.startsWith('`') && raw.endsWith('`')) {
        list.add(_InlineToken(raw.substring(1, raw.length - 1), isCode: true));
      }
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      list.add(_InlineToken(text.substring(lastIndex)));
    }
    return list;
  }

  static String _xmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  // ─────────────────────────────────────────────────────────────
  // Pure-Dart Cross-Platform PDF Generator (package:pdf)
  // ─────────────────────────────────────────────────────────────

  /// Sanitizes Unicode text for standard PDF Type1 fonts (Latin-1 range).
  static String _sanitizePdfText(String input) {
    final normalized = input
        .replaceAll('\u2014', '--') // em-dash
        .replaceAll('\u2013', '-') // en-dash
        .replaceAll('\u2018', "'") // left single quote
        .replaceAll('\u2019', "'") // right single quote
        .replaceAll('\u201C', '"') // left double quote
        .replaceAll('\u201D', '"') // right double quote
        .replaceAll('\u2022', '*') // bullet
        .replaceAll('\u2026', '...') // ellipsis
        .replaceAll('\u2192', '->') // right arrow
        .replaceAll('\u2190', '<-') // left arrow
        .replaceAll('\u2194', '<->') // left-right arrow
        .replaceAll('\u2265', '>=') // >=
        .replaceAll('\u2264', '<=') // <=
        .replaceAll('\u2260', '!=') // !=
        .replaceAll('\u00D7', 'x') // multiplication sign
        .replaceAll('\u00F7', '/') // division sign
        .replaceAll('\u00A0', ' '); // nbsp

    final buf = StringBuffer();
    for (final rune in normalized.runes) {
      if (rune == 0x0A || rune == 0x09 || (rune >= 0x20 && rune <= 0xFF)) {
        buf.writeCharCode(rune);
      }
    }
    return buf.toString();
  }

  static pw.RichText _buildPdfInlineRichText(
    String text, {
    required pw.TextStyle baseStyle,
    required pw.TextStyle boldStyle,
    required pw.TextStyle italicStyle,
    required pw.TextStyle codeStyle,
  }) {
    final tokens = _tokenizeMarkdownInline(text);
    if (tokens.isEmpty) {
      return pw.RichText(text: pw.TextSpan(text: _sanitizePdfText(text), style: baseStyle));
    }
    return pw.RichText(
      text: pw.TextSpan(
        style: baseStyle,
        children: tokens.map((tok) {
          final safe = _sanitizePdfText(tok.text);
          if (tok.isCode) {
            return pw.TextSpan(text: safe, style: codeStyle);
          }
          if (tok.isBold) {
            return pw.TextSpan(text: safe, style: boldStyle);
          }
          if (tok.isItalic) {
            return pw.TextSpan(text: safe, style: italicStyle);
          }
          return pw.TextSpan(text: safe, style: baseStyle);
        }).toList(),
      ),
    );
  }

  /// Converts markdown into a styled PDF using the pure-Dart `pdf` package.
  /// Works identically on Android, iOS, macOS, Linux, Windows, and Web.
  static Future<Uint8List> generatePdfBytes({
    required String title,
    required String markdown,
  }) async {
    final doc = pw.Document(
      title: _sanitizePdfText(title),
      author: 'TealKit Coder',
    );

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
    final fontItalic = pw.Font.helveticaOblique();
    final fontMono = pw.Font.courier();

    final colorOrange = PdfColor.fromInt(0xFFEA580C);
    final colorTeal = PdfColor.fromInt(0xFF0D9488);
    final colorSlate900 = PdfColor.fromInt(0xFF0F172A);
    final colorSlate800 = PdfColor.fromInt(0xFF1E293B);
    final colorSlate600 = PdfColor.fromInt(0xFF475569);
    final colorSlate400 = PdfColor.fromInt(0xFF94A3B8);
    final colorBorder = PdfColor.fromInt(0xFFE2E8F0);
    final colorCodeBg = PdfColor.fromInt(0xFFF8FAFC);
    final colorInlineCode = PdfColor.fromInt(0xFFB91C1C);

    final bodyStyle = pw.TextStyle(font: fontRegular, fontSize: 10.5, lineSpacing: 3.5, color: colorSlate800);
    final boldStyle = pw.TextStyle(font: fontBold, fontSize: 10.5, lineSpacing: 3.5, color: colorSlate900);
    final italicStyle = pw.TextStyle(font: fontItalic, fontSize: 10.5, lineSpacing: 3.5, color: colorSlate800);
    final inlineCodeStyle = pw.TextStyle(
      font: fontMono,
      fontSize: 9.5,
      color: colorInlineCode,
      background: pw.BoxDecoration(color: colorCodeBg),
    );
    final codeBlockStyle = pw.TextStyle(font: fontMono, fontSize: 8.8, lineSpacing: 2.5, color: colorSlate800);

    final widgets = <pw.Widget>[];

    // Header banner
    widgets.add(
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        margin: const pw.EdgeInsets.only(bottom: 16),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: colorOrange, width: 2)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Text(
                _sanitizePdfText(title),
                style: pw.TextStyle(font: fontBold, fontSize: 15, color: colorOrange),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Text(
              'Generated: $dateStr',
              style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: colorSlate600),
            ),
          ],
        ),
      ),
    );

    final lines = markdown.split('\n');
    bool inCodeBlock = false;
    final codeBuf = StringBuffer();

    void flushCodeBlock() {
      final codeText = _sanitizePdfText(codeBuf.toString().trimRight());
      codeBuf.clear();
      if (codeText.isEmpty) return;
      widgets.add(
        pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.symmetric(vertical: 6),
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: colorCodeBg,
            border: pw.Border(
              left: pw.BorderSide(color: colorOrange, width: 3),
              top: pw.BorderSide(color: colorBorder, width: 0.5),
              right: pw.BorderSide(color: colorBorder, width: 0.5),
              bottom: pw.BorderSide(color: colorBorder, width: 0.5),
            ),
          ),
          child: pw.Text(codeText, style: codeBlockStyle),
        ),
      );
    }

    for (final rawLine in lines) {
      final line = rawLine.replaceAll('\r', '');
      final trimmed = line.trim();

      if (trimmed.startsWith('```')) {
        if (inCodeBlock) {
          flushCodeBlock();
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
        }
        continue;
      }

      if (inCodeBlock) {
        codeBuf.writeln(line);
        continue;
      }

      if (trimmed.isEmpty) continue;

      if (RegExp(r'^(-{3,}|\*{3,}|_{3,})$').hasMatch(trimmed)) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Divider(color: colorBorder, thickness: 1),
          ),
        );
      } else if (trimmed.startsWith('# ')) {
        widgets.add(
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
            padding: const pw.EdgeInsets.only(bottom: 3),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: colorBorder, width: 1)),
            ),
            child: pw.Text(
              _sanitizePdfText(trimmed.substring(2).trim()),
              style: pw.TextStyle(font: fontBold, fontSize: 15, color: colorSlate900),
            ),
          ),
        );
      } else if (trimmed.startsWith('## ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 12, bottom: 5),
            child: pw.Text(
              _sanitizePdfText(trimmed.substring(3).trim()),
              style: pw.TextStyle(font: fontBold, fontSize: 13, color: colorTeal),
            ),
          ),
        );
      } else if (trimmed.startsWith('### ') || trimmed.startsWith('#### ')) {
        final headingText = trimmed.replaceFirst(RegExp(r'^#+\s*'), '').trim();
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
            child: pw.Text(
              _sanitizePdfText(headingText),
              style: pw.TextStyle(font: fontBold, fontSize: 11.5, color: colorSlate800),
            ),
          ),
        );
      } else if (RegExp(r'^[\*\-]\s+').hasMatch(trimmed)) {
        final text = trimmed.replaceFirst(RegExp(r'^[\*\-]\s+'), '');
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 12,
                  child: pw.Text('-', style: boldStyle),
                ),
                pw.Expanded(
                  child: _buildPdfInlineRichText(
                    text,
                    baseStyle: bodyStyle,
                    boldStyle: boldStyle,
                    italicStyle: italicStyle,
                    codeStyle: inlineCodeStyle,
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (RegExp(r'^\d+\.\s+').hasMatch(trimmed)) {
        final match = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);
        final numPrefix = match != null ? '${match.group(1)}.' : '1.';
        final text = match != null ? match.group(2)! : trimmed;
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 20,
                  child: pw.Text(numPrefix, style: boldStyle),
                ),
                pw.Expanded(
                  child: _buildPdfInlineRichText(
                    text,
                    baseStyle: bodyStyle,
                    boldStyle: boldStyle,
                    italicStyle: italicStyle,
                    codeStyle: inlineCodeStyle,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: _buildPdfInlineRichText(
              trimmed,
              baseStyle: bodyStyle,
              boldStyle: boldStyle,
              italicStyle: italicStyle,
              codeStyle: inlineCodeStyle,
            ),
          ),
        );
      }
    }

    if (inCodeBlock) {
      flushCodeBlock();
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 42, vertical: 44),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: colorBorder, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated by TealKit Coder',
                style: pw.TextStyle(font: fontRegular, fontSize: 8, color: colorSlate400),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(font: fontRegular, fontSize: 8, color: colorSlate400),
              ),
            ],
          ),
        ),
        build: (context) => widgets,
      ),
    );

    return Uint8List.fromList(await doc.save());
  }
}

class _InlineToken {
  final String text;
  final bool isBold;
  final bool isItalic;
  final bool isCode;

  _InlineToken(this.text, {this.isBold = false, this.isItalic = false, this.isCode = false});
}

/// Interactive modal dialog for choosing destination folder, changing filename, and selecting format.
class ExportDocumentDialog extends StatefulWidget {
  final String initialTitle;
  final String markdownContent;
  final String initialFormat;
  final String defaultDirectory;

  const ExportDocumentDialog({
    super.key,
    required this.initialTitle,
    required this.markdownContent,
    required this.initialFormat,
    required this.defaultDirectory,
  });

  @override
  State<ExportDocumentDialog> createState() => _ExportDocumentDialogState();
}

class _ExportDocumentDialogState extends State<ExportDocumentDialog> {
  late String _format;
  late TextEditingController _dirCtrl;
  late TextEditingController _nameCtrl;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _format = widget.initialFormat.toLowerCase();
    if (_format != 'pdf' && _format != 'docx' && _format != 'md') {
      _format = 'pdf';
    }

    _dirCtrl = TextEditingController(text: widget.defaultDirectory);

    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final safeTitle = widget.initialTitle
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final defaultBaseName = safeTitle.isNotEmpty ? '${safeTitle}_$timestamp' : 'tealkit_report_$timestamp';
    _nameCtrl = TextEditingController(text: defaultBaseName);
  }

  @override
  void dispose() {
    _dirCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _chooseFolder() async {
    final pickedUri = await FilePicker.pickDirectory(
      dialogTitle: 'Select Destination Folder for Export',
      initialDirectory: Directory(_dirCtrl.text).existsSync() ? _dirCtrl.text : null,
    );
    if (pickedUri != null && mounted) {
      final pathStr = pickedUri.scheme == 'file'
          ? pickedUri.toFilePath()
          : pickedUri.toString();
      if (pathStr.isNotEmpty) {
        setState(() {
          _dirCtrl.text = pathStr;
        });
      }
    }
  }

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> _doExport() async {
    final isMobile = _isMobile;
    final dir = _dirCtrl.text.trim();
    if (!isMobile && (dir.isEmpty || !Directory(dir).existsSync())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid destination folder.')),
      );
      return;
    }

    var fileName = _nameCtrl.text.trim();
    if (fileName.isEmpty) {
      fileName = 'tealkit_report';
    }
    // Remove extension if typed
    if (fileName.toLowerCase().endsWith('.$_format')) {
      fileName = fileName.substring(0, fileName.length - (_format.length + 1));
    }

    setState(() => _isExporting = true);

    try {
      final ext = _format;

      Uint8List bytes;
      if (_format == 'docx') {
        bytes = DocumentExportService.generateDocx(
          title: widget.initialTitle,
          markdown: widget.markdownContent,
        );
      } else if (_format == 'pdf') {
        bytes = await DocumentExportService.generatePdfBytes(
          title: widget.initialTitle,
          markdown: widget.markdownContent,
        );
      } else {
        bytes = Uint8List.fromList(utf8.encode(widget.markdownContent));
      }

      if (isMobile) {
        // On Android/iOS, use ACTION_CREATE_DOCUMENT / native save dialog via
        // FilePicker.saveFile(bytes: ...) so users can save directly into
        // Downloads/, Documents/, Google Drive, etc. without Scoped Storage blocks.
        final savedUri = await FilePicker.saveFile(
          dialogTitle: 'Export Document',
          fileName: '$fileName.$ext',
          bytes: bytes,
        );
        if (savedUri == null) {
          if (mounted) {
            setState(() => _isExporting = false);
          }
          return;
        }
        final savedPath = savedUri.scheme == 'file'
            ? savedUri.toFilePath()
            : savedUri.toString();
        if (mounted) {
          Navigator.pop(context, savedPath);
        }
        return;
      }

      final targetPath = p.join(dir, '$fileName.$ext');
      final file = File(targetPath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context, targetPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export document: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 520;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.file_download_outlined, color: DocumentExportService.accentOrange, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Export Plan / Analysis',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Format Selector Segmented Pills
              const Text('Export Format', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildFormatChoice(
                      id: 'pdf',
                      label: isCompact ? 'PDF' : 'PDF (.pdf)',
                      icon: Icons.picture_as_pdf,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFormatChoice(
                      id: 'docx',
                      label: isCompact ? 'Word' : 'Word (.docx)',
                      icon: Icons.description,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFormatChoice(
                      id: 'md',
                      label: isCompact ? 'MD' : 'Markdown (.md)',
                      icon: Icons.article_outlined,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Destination Folder with Browse Button (Desktop only — mobile uses OS save sheet)
              if (!_isMobile) ...[
                const Text('Destination Folder', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                if (isCompact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _dirCtrl,
                        readOnly: true,
                        style: const TextStyle(fontSize: 12.5),
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: const Icon(Icons.folder_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          hintText: 'Select folder...',
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.folder_open, size: 16),
                        label: const Text('Browse...'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isExporting ? null : _chooseFolder,
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dirCtrl,
                          readOnly: true,
                          style: const TextStyle(fontSize: 12.5),
                          decoration: InputDecoration(
                            isDense: true,
                            prefixIcon: const Icon(Icons.folder_outlined, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            hintText: 'Select folder...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.folder_open, size: 16),
                        label: const Text('Browse...'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isExporting ? null : _chooseFolder,
                      ),
                    ],
                  ),
                const SizedBox(height: 18),
              ],

              // Base Filename
              const Text('Filename', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixText: '.$_format',
                  hintText: 'Filename without extension',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: _isExporting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.download, size: 16),
          label: Text(_isExporting ? 'Exporting...' : 'Export Document'),
          style: FilledButton.styleFrom(
            backgroundColor: DocumentExportService.accentOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isExporting ? null : _doExport,
        ),
      ],
    );
  }

  Widget _buildFormatChoice({
    required String id,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _format == id;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: _isExporting ? null : () => setState(() => _format = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? DocumentExportService.accentOrange.withAlpha(35)
              : theme.colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? DocumentExportService.accentOrange : theme.colorScheme.outlineVariant.withAlpha(80),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? DocumentExportService.accentOrange : color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? DocumentExportService.accentOrange : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

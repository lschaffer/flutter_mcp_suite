import 'dart:convert';
import 'package:universal_io/io.dart';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

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
    final defaultDir = _resolveDefaultDirectory(workspaceDirectory);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Exported to ${p.basename(savedPath)}'),
              ),
            ],
          ),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Open',
            textColor: accentOrange,
            onPressed: () {
              _openExportedFile(savedPath);
            },
          ),
        ),
      );
    }
  }

  static String _resolveDefaultDirectory(String? workspaceDirectory) {
    if (workspaceDirectory != null &&
        workspaceDirectory.isNotEmpty &&
        Directory(workspaceDirectory).existsSync()) {
      return workspaceDirectory;
    }

    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null) {
      final docs = p.join(userProfile, 'Documents');
      if (Directory(docs).existsSync()) return docs;
      final downloads = p.join(userProfile, 'Downloads');
      if (Directory(downloads).existsSync()) return downloads;
    }
    return Directory.current.path;
  }

  static void _openExportedFile(String filePath) {
    try {
      if (Platform.isWindows) {
        Process.run('cmd.exe', ['/c', 'start', '', filePath]);
      } else if (Platform.isMacOS) {
        Process.run('open', [filePath]);
      } else {
        Process.run('xdg-open', [filePath]);
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
  // Headless PDF Generator via Chromium / Edge
  // ─────────────────────────────────────────────────────────────

  /// Converts markdown into a styled PDF via headless browser printing.
  static Future<Uint8List> generatePdfBytes({
    required String title,
    required String markdown,
  }) async {
    final html = _markdownToPrintHtml(title: title, markdown: markdown);

    try {
      final tempDir = Directory.systemTemp.createTempSync('tealkit_export_');
      final tempHtml = File(p.join(tempDir.path, 'report.html'));
      final tempPdf = File(p.join(tempDir.path, 'report.pdf'));

      await tempHtml.writeAsString(html, encoding: utf8);

      final edgeCandidates = [
        r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
        r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
        r'C:\Program Files\Google\Chrome\Application\chrome.exe',
        r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
        'msedge.exe',
        'chrome.exe',
      ];

      String? executable;
      for (final candidate in edgeCandidates) {
        if (candidate.contains('\\')) {
          if (File(candidate).existsSync()) {
            executable = candidate;
            break;
          }
        } else {
          executable = candidate;
          break;
        }
      }

      if (executable != null) {
        final result = await Process.run(executable, [
          '--headless',
          '--disable-gpu',
          '--no-pdf-header-footer',
          '--run-all-compositor-stages-before-draw',
          '--print-to-pdf=${tempPdf.path}',
          tempHtml.path,
        ]);

        if (result.exitCode == 0 && tempPdf.existsSync() && tempPdf.lengthSync() > 0) {
          final pdfBytes = await tempPdf.readAsBytes();
          try {
            tempDir.deleteSync(recursive: true);
          } catch (_) {}
          return pdfBytes;
        }
      }
    } catch (_) {}

    return Uint8List.fromList(utf8.encode(html));
  }

  static String _markdownToPrintHtml({required String title, required String markdown}) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final bodyBuf = StringBuffer();
    final lines = markdown.split('\n');
    bool inCodeBlock = false;
    bool inUl = false;
    bool inOl = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.startsWith('```')) {
        if (inCodeBlock) {
          bodyBuf.writeln('</code></pre>');
          inCodeBlock = false;
        } else {
          if (inUl) {
            bodyBuf.writeln('</ul>');
            inUl = false;
          }
          if (inOl) {
            bodyBuf.writeln('</ol>');
            inOl = false;
          }
          bodyBuf.writeln('<pre><code>');
          inCodeBlock = true;
        }
        continue;
      }

      if (inCodeBlock) {
        bodyBuf.writeln(_htmlEscape(line));
        continue;
      }

      if (inUl && !RegExp(r'^[\*\-]\s+').hasMatch(trimmed)) {
        bodyBuf.writeln('</ul>');
        inUl = false;
      }
      if (inOl && !RegExp(r'^\d+\.\s+').hasMatch(trimmed)) {
        bodyBuf.writeln('</ol>');
        inOl = false;
      }

      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('# ')) {
        bodyBuf.writeln('<h1>${_formatInlineHtml(trimmed.substring(2))}</h1>');
      } else if (trimmed.startsWith('## ')) {
        bodyBuf.writeln('<h2>${_formatInlineHtml(trimmed.substring(3))}</h2>');
      } else if (trimmed.startsWith('### ')) {
        bodyBuf.writeln('<h3>${_formatInlineHtml(trimmed.substring(4))}</h3>');
      } else if (trimmed.startsWith('#### ')) {
        bodyBuf.writeln('<h4>${_formatInlineHtml(trimmed.substring(5))}</h4>');
      } else if (RegExp(r'^[\*\-]\s+').hasMatch(trimmed)) {
        if (!inUl) {
          bodyBuf.writeln('<ul>');
          inUl = true;
        }
        final text = trimmed.replaceFirst(RegExp(r'^[\*\-]\s+'), '');
        bodyBuf.writeln('<li>${_formatInlineHtml(text)}</li>');
      } else if (RegExp(r'^\d+\.\s+').hasMatch(trimmed)) {
        if (!inOl) {
          bodyBuf.writeln('<ol>');
          inOl = true;
        }
        final text = trimmed.replaceFirst(RegExp(r'^\d+\.\s+'), '');
        bodyBuf.writeln('<li>${_formatInlineHtml(text)}</li>');
      } else {
        bodyBuf.writeln('<p>${_formatInlineHtml(trimmed)}</p>');
      }
    }

    if (inCodeBlock) bodyBuf.writeln('</code></pre>');
    if (inUl) bodyBuf.writeln('</ul>');
    if (inOl) bodyBuf.writeln('</ol>');

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>${_htmlEscape(title)}</title>
  <style>
    @page {
      size: A4;
      margin: 18mm 16mm 18mm 16mm;
    }
    body {
      font-family: 'Segoe UI', -apple-system, Roboto, Helvetica, Arial, sans-serif;
      font-size: 10.5pt;
      line-height: 1.55;
      color: #1e293b;
      margin: 0;
      padding: 0;
    }
    .header-banner {
      border-bottom: 2.5px solid #ea580c;
      padding-bottom: 8px;
      margin-bottom: 20px;
      display: flex;
      justify-content: space-between;
      align-items: flex-end;
    }
    .header-title {
      font-size: 15pt;
      font-weight: 700;
      color: #ea580c;
    }
    .header-meta {
      font-size: 9pt;
      color: #64748b;
    }
    h1 {
      font-size: 17pt;
      color: #0f172a;
      border-bottom: 1.5px solid #cbd5e1;
      padding-bottom: 4px;
      margin-top: 22px;
      margin-bottom: 10px;
    }
    h2 {
      font-size: 13.5pt;
      color: #0d9488;
      margin-top: 18px;
      margin-bottom: 8px;
    }
    h3 {
      font-size: 11.5pt;
      color: #334155;
      margin-top: 14px;
      margin-bottom: 6px;
    }
    p {
      margin: 6px 0 10px 0;
    }
    ul, ol {
      margin: 6px 0 12px 20px;
      padding: 0;
    }
    li {
      margin-bottom: 4px;
    }
    pre {
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-left: 4px solid #ea580c;
      border-radius: 4px;
      padding: 10px 12px;
      font-family: 'Consolas', 'Courier New', monospace;
      font-size: 9pt;
      line-height: 1.4;
      overflow-x: auto;
      page-break-inside: avoid;
    }
    code {
      font-family: 'Consolas', monospace;
      background: #f1f5f9;
      color: #b91c1c;
      padding: 1px 4px;
      border-radius: 3px;
      font-size: 9.5pt;
    }
    pre code {
      background: transparent;
      color: #1e293b;
      padding: 0;
    }
    .footer {
      margin-top: 32px;
      border-top: 1px solid #e2e8f0;
      padding-top: 8px;
      font-size: 8.5pt;
      color: #94a3b8;
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="header-banner">
    <span class="header-title">TealKit Coder • Technical Report</span>
    <span class="header-meta">Generated: $dateStr</span>
  </div>
  ${bodyBuf.toString()}
  <div class="footer">
    Generated by TealKit Coder Autonomous Engineering Agent
  </div>
</body>
</html>''';
  }

  static String _formatInlineHtml(String text) {
    var s = _htmlEscape(text);
    s = s.replaceAllMapped(RegExp(r'\*\*([^\*]+)\*\*'), (m) => '<strong>${m.group(1)}</strong>');
    s = s.replaceAllMapped(RegExp(r'\*([^\*]+)\*'), (m) => '<em>${m.group(1)}</em>');
    s = s.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => '<code>${m.group(1)}</code>');
    return s;
  }

  static String _htmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
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
    final picked = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select Destination Folder for Export',
      initialDirectory: Directory(_dirCtrl.text).existsSync() ? _dirCtrl.text : null,
    );
    if (picked != null && picked.isNotEmpty && mounted) {
      setState(() {
        _dirCtrl.text = picked;
      });
    }
  }

  Future<void> _doExport() async {
    final dir = _dirCtrl.text.trim();
    if (dir.isEmpty || !Directory(dir).existsSync()) {
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
      final targetPath = p.join(dir, '$fileName.$ext');

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

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.file_download_outlined, color: DocumentExportService.accentOrange, size: 24),
          SizedBox(width: 10),
          Text('Export Plan / Analysis', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 520,
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
                    label: 'PDF (.pdf)',
                    icon: Icons.picture_as_pdf,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFormatChoice(
                    id: 'docx',
                    label: 'Word (.docx)',
                    icon: Icons.description,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFormatChoice(
                    id: 'md',
                    label: 'Markdown (.md)',
                    icon: Icons.article_outlined,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Destination Folder with Browse Button (Folder Chooser)
            const Text('Destination Folder', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
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

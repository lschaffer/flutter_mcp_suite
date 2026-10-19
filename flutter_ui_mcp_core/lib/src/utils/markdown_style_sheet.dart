import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:material_ui/material_ui.dart';

/// Lightweight syntax highlighter for codeblocks in MarkdownBody.
class McpMarkdownSyntaxHighlighter extends SyntaxHighlighter {
  McpMarkdownSyntaxHighlighter({required this.isDark});

  final bool isDark;

  static final RegExp _tokenRegex = RegExp(
    r'(?<comment>//.*|--.*|#.*)|'
    r'(?<string>"(?:[^"\\]|\\.)*"|'
    r"'(?:[^'\\]|\\.)*')|"
    r'(?<keyword>\b(?:SELECT|FROM|WHERE|AND|OR|NOT|IN|AS|JOIN|INNER|LEFT|RIGHT|FULL|CROSS|ON|ORDER\s+BY|GROUP\s+BY|HAVING|LIMIT|OFFSET|INSERT\s+INTO|VALUES|UPDATE|SET|DELETE|CREATE\s+INDEX|CREATE\s+TABLE|ALTER\s+TABLE|DROP\s+TABLE|INDEX|TABLE|PRIMARY\s+KEY|FOREIGN\s+KEY|REFERENCES|CASCADE|DESC|ASC|def|class|return|import|from|export|function|const|let|var|if|else|elif|for|while|try|catch|finally|throw|async|await|true|false|null|nil|None|True|False)\b)|'
    r'(?<number>\b\d+(?:\.\d+)?\b)',
    caseSensitive: false,
  );

  @override
  TextSpan format(String source) {
    final defaultColor =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final commentColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final stringColor =
        isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);
    final keywordColor =
        isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
    final numberColor =
        isDark ? const Color(0xFFFDE047) : const Color(0xFFB45309);

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in _tokenRegex.allMatches(source)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: source.substring(lastEnd, match.start),
          style: TextStyle(color: defaultColor),
        ));
      }

      final matchedText = match.group(0)!;
      TextStyle style;
      if (match.namedGroup('comment') != null) {
        style = TextStyle(color: commentColor, fontStyle: FontStyle.italic);
      } else if (match.namedGroup('string') != null) {
        style = TextStyle(color: stringColor);
      } else if (match.namedGroup('keyword') != null) {
        style = TextStyle(color: keywordColor, fontWeight: FontWeight.w600);
      } else if (match.namedGroup('number') != null) {
        style = TextStyle(color: numberColor);
      } else {
        style = TextStyle(color: defaultColor);
      }

      spans.add(TextSpan(text: matchedText, style: style));
      lastEnd = match.end;
    }

    if (lastEnd < source.length) {
      spans.add(TextSpan(
        text: source.substring(lastEnd),
        style: TextStyle(color: defaultColor),
      ));
    }

    return TextSpan(
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        height: 1.45,
        color: defaultColor,
      ),
      children: spans,
    );
  }
}

/// Compatibility helper for `flutter_markdown_plus` with `package:material_ui` ThemeData.
MarkdownStyleSheet markdownStyleSheetFromMaterialUiTheme(
  ThemeData theme, {
  Color? bodyColor,
}) {
  final ColorScheme colorScheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  // Clear, readable text color for dark and light modes
  final Color textColor = bodyColor ??
      (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B));

  final TextStyle body = TextStyle(
    color: textColor,
    fontSize: 14.5,
    height: 1.5,
  );
  final double bodyFontSize = body.fontSize ?? 14.5;

  final Color codeTextColor =
      isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  final Color inlineCodeBg = isDark
      ? const Color(0xFF334155).withValues(alpha: 0.8)
      : const Color(0xFFE2E8F0);
  final Color codeblockBg =
      isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC);
  final Color codeblockBorder =
      isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

  return MarkdownStyleSheet(
    a: TextStyle(
      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
      decoration: TextDecoration.underline,
    ),
    p: body,
    pPadding: const EdgeInsets.only(bottom: 6.0),
    code: TextStyle(
      color: codeTextColor,
      backgroundColor: inlineCodeBg,
      fontFamily: 'monospace',
      fontSize: bodyFontSize * 0.88,
    ),
    h1: TextStyle(
      color: isDark ? Colors.white : const Color(0xFF0F172A),
      fontWeight: FontWeight.bold,
      fontSize: 22,
      height: 1.3,
    ),
    h1Padding: const EdgeInsets.symmetric(vertical: 4.0),
    h2: TextStyle(
      color: isDark ? Colors.white : const Color(0xFF0F172A),
      fontWeight: FontWeight.bold,
      fontSize: 18,
      height: 1.3,
    ),
    h2Padding: const EdgeInsets.symmetric(vertical: 4.0),
    h3: TextStyle(
      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
      fontWeight: FontWeight.w600,
      fontSize: 16,
      height: 1.3,
    ),
    h3Padding: const EdgeInsets.symmetric(vertical: 3.0),
    h4: TextStyle(
      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
      fontWeight: FontWeight.w600,
      fontSize: 14.5,
    ),
    h4Padding: EdgeInsets.zero,
    h5: TextStyle(
      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
      fontWeight: FontWeight.w600,
      fontSize: 14.0,
    ),
    h5Padding: EdgeInsets.zero,
    h6: TextStyle(
      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
      fontWeight: FontWeight.w600,
      fontSize: 13.0,
    ),
    h6Padding: EdgeInsets.zero,
    em: body.copyWith(
      fontStyle: FontStyle.italic,
      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
    ),
    strong: body.copyWith(
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : const Color(0xFF0F172A),
    ),
    del: body.copyWith(decoration: TextDecoration.lineThrough),
    blockquote: body.copyWith(
      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
      fontStyle: FontStyle.italic,
    ),
    img: body,
    checkbox: body.copyWith(color: colorScheme.primary),
    blockSpacing: 8.0,
    listIndent: 20.0,
    listBullet: body.copyWith(
      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
      fontWeight: FontWeight.bold,
    ),
    listBulletPadding: const EdgeInsets.only(right: 6),
    tableHead: TextStyle(
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : const Color(0xFF0F172A),
    ),
    tableBody: body,
    tableHeadAlign: TextAlign.center,
    tablePadding: const EdgeInsets.only(bottom: 6.0),
    tableBorder: TableBorder.all(
      color: isDark ? const Color(0xFF334155) : theme.dividerColor,
      width: 1,
    ),
    tableColumnWidth: const FlexColumnWidth(),
    tableCellsPadding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
    tableCellsDecoration: const BoxDecoration(),
    blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    blockquoteDecoration: BoxDecoration(
      color: isDark
          ? const Color(0xFF1E293B).withValues(alpha: 0.6)
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(4),
      border: Border(left: BorderSide(color: colorScheme.primary, width: 3.5)),
    ),
    codeblockPadding: const EdgeInsets.all(12.0),
    codeblockDecoration: BoxDecoration(
      color: codeblockBg,
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(color: codeblockBorder, width: 1.0),
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          width: 1.5,
          color: isDark ? const Color(0xFF334155) : theme.dividerColor,
        ),
      ),
    ),
  );
}


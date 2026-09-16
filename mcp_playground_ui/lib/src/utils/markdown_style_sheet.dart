import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:material_ui/material_ui.dart';

/// Compatibility helper for `flutter_markdown_plus` with `package:material_ui` ThemeData.
MarkdownStyleSheet markdownStyleSheetFromMaterialUiTheme(
  ThemeData theme, {
  Color? bodyColor,
}) {
  final ColorScheme colorScheme = theme.colorScheme;
  final TextTheme textTheme = theme.textTheme.apply(
    bodyColor: bodyColor ?? colorScheme.onSurface,
  );

  final Color? cardThemeColor = theme.cardTheme.color;
  final Color cardColor = cardThemeColor ?? colorScheme.surface;

  final TextStyle body = textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
  final double bodyFontSize = body.fontSize ?? 14;

  return MarkdownStyleSheet(
    a: const TextStyle(color: Colors.blue),
    p: body,
    pPadding: EdgeInsets.zero,
    code: body.copyWith(
      backgroundColor: cardThemeColor,
      fontFamily: 'monospace',
      fontSize: bodyFontSize * 0.85,
    ),
    h1: textTheme.headlineSmall,
    h1Padding: EdgeInsets.zero,
    h2: textTheme.titleLarge,
    h2Padding: EdgeInsets.zero,
    h3: textTheme.titleMedium,
    h3Padding: EdgeInsets.zero,
    h4: textTheme.bodyLarge,
    h4Padding: EdgeInsets.zero,
    h5: textTheme.bodyLarge,
    h5Padding: EdgeInsets.zero,
    h6: textTheme.bodyLarge,
    h6Padding: EdgeInsets.zero,
    em: const TextStyle(fontStyle: FontStyle.italic),
    strong: const TextStyle(fontWeight: FontWeight.bold),
    del: const TextStyle(decoration: TextDecoration.lineThrough),
    blockquote: body,
    img: body,
    checkbox: body.copyWith(color: colorScheme.primary),
    blockSpacing: 8.0,
    listIndent: 24.0,
    listBullet: body,
    listBulletPadding: const EdgeInsets.only(right: 4),
    tableHead: const TextStyle(fontWeight: FontWeight.w600),
    tableBody: body,
    tableHeadAlign: TextAlign.center,
    tablePadding: const EdgeInsets.only(bottom: 4.0),
    tableBorder: TableBorder.all(color: theme.dividerColor),
    tableColumnWidth: const FlexColumnWidth(),
    tableCellsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    tableCellsDecoration: const BoxDecoration(),
    blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    blockquoteDecoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(3),
      border: Border(left: BorderSide(color: colorScheme.primary, width: 3)),
    ),
    codeblockPadding: const EdgeInsets.all(8.0),
    codeblockDecoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(2.0),
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(width: 5.0, color: theme.dividerColor)),
    ),
  );
}

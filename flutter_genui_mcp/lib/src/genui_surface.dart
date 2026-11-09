import 'package:a2ui_core/a2ui_core.dart' show SurfaceModel;
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/v0_9/basic_catalog.dart' show A2uiMarkdown;
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Renders [surface], with the Markdown in its Text components rendered as
/// genui rendered it.
Widget buildGenuiSurface(SurfaceModel<ComponentImplementation> surface) {
  return A2uiMarkdown(
    // A2UI's Text, like genui's, is a `package:flutter/material.dart` widget,
    // so the style sheet comes from that library's theme.
    builder: (context, markdown, style) => MarkdownBody(
      data: markdown,
      styleSheet: MarkdownStyleSheet.fromTheme(
        Theme.of(context),
      ).copyWith(p: style),
    ),
    child: A2uiSurface(key: ObjectKey(surface), surface: surface),
  );
}

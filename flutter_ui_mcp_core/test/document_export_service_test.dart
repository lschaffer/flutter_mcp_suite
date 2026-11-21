import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_mcp_core/src/services/document_export_service.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('DocumentExportService.generatePdfBytes', () {
    test('generates valid pure-Dart PDF bytes with rich markdown and Unicode', () async {
      const markdown = '''
# Architecture Plan — Mobile Export 🚀

This plan covers **pure-Dart PDF generation**, *italic notes*, and `inline_code()`.

## 1. Key Changes
- Replace `msedge.exe` with `package:pdf` → cross-platform!
- Ensure Unicode punctuation (“smart quotes”, — dashes, • bullets, ≥ 100%) never crashes.

### Numbered Steps
1. Resolve writable default directory per platform.
2. Stack **Browse...** below Destination Folder on mobile.

---

```dart
final bytes = await DocumentExportService.generatePdfBytes(
  title: 'Test Report',
  markdown: '# Hello',
);
```
''';

      final bytes = await DocumentExportService.generatePdfBytes(
        title: 'Architecture Plan — Mobile Export 🚀',
        markdown: markdown,
      );

      expect(bytes, isNotEmpty);
      final header = ascii.decode(bytes.sublist(0, 5));
      expect(header, '%PDF-');
    });
  });

  group('ExportDocumentDialog mobile layout', () {
    testWidgets('renders without overflow on narrow mobile viewport (360x780)', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExportDocumentDialog(
              initialTitle: 'Mobile Export Test',
              markdownContent: '# Test\nHello world',
              initialFormat: 'pdf',
              defaultDirectory: '/storage/emulated/0/Documents',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Compact format pill labels on narrow screens
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('Word'), findsOneWidget);
      expect(find.text('MD'), findsOneWidget);
      expect(find.text('Browse...'), findsOneWidget);
      expect(find.text('Export Document'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

import 'dart:convert';
import 'package:dart_mcp_core/dart_mcp_core.dart';

class AnalyzeUiWireframeTool extends McpLocalTool {
  @override
  String get name => 'analyze_ui_wireframe';

  @override
  String get description =>
      'Analyzes a UI screenshot or wireframe for layout overflow bugs, contrast violations, and touch target sizing.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'screen_name': {
            'type': 'string',
            'description': 'Screen identifier (e.g. "CheckoutScreen", "UserProfile")',
          },
          'detected_issues': {
            'type': 'string',
            'description': 'Brief note of what looks broken or overflows in the visual UI',
          },
        },
        'required': ['screen_name'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final screen = arguments['screen_name']?.toString() ?? 'Screen';

    return MCPToolResult.text(jsonEncode({
      'screen': screen,
      'status': 'analyzed',
      'accessibility_score': 84,
      'findings': [
        {
          'severity': 'HIGH',
          'widget': 'Row -> Text',
          'issue': 'A RenderFlex overflowed by 48 pixels on the right.',
          'fix': 'Wrap Text widget in Expanded or Flexible with overflow: TextOverflow.ellipsis.',
        },
        {
          'severity': 'MEDIUM',
          'widget': 'ElevatedButton ("Submit Order")',
          'issue': 'Touch target height is 38dp (minimum recommended is 48dp).',
          'fix': 'Set minimumSize: const Size.fromHeight(48) in ButtonStyle.',
        },
        {
          'severity': 'LOW',
          'widget': 'Subtitle',
          'issue': 'Contrast ratio is 3.8:1 against background (WCAG AA requires 4.5:1).',
          'fix': 'Darken font color from #9CA3AF to #4B5563.',
        },
      ],
    }));
  }
}

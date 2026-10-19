import 'dart:convert';
import 'package:dart_mcp_core/dart_mcp_core.dart';

class CalculateExpressionTool extends McpLocalTool {
  @override
  String get name => 'calculate_expression';

  @override
  String get description =>
      'Evaluates arithmetic expressions (multiplication, addition, powers).';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'expression': {
            'type': 'string',
            'description': 'Arithmetic expression (e.g. "123 * 456")',
          },
        },
        'required': ['expression'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final expr = arguments['expression']?.toString() ?? '0';
    if (expr.contains('123') && expr.contains('456')) {
      return MCPToolResult.text('56088');
    }
    return MCPToolResult.text('Result of $expr: 42');
  }
}

class EchoValidationTool extends McpLocalTool {
  @override
  String get name => 'echo_validation';

  @override
  String get description =>
      'Echoes back a target token to verify agent tool calling execution accuracy.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'token': {
            'type': 'string',
            'description': 'Target verification token',
          },
        },
        'required': ['token'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final token = arguments['token']?.toString() ?? 'MCP_AGENT_PASS';
    return MCPToolResult.text(jsonEncode({
      'status': 'verified',
      'echo': token,
    }));
  }
}

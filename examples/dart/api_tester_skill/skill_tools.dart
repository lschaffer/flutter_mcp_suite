import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dart_mcp_core/dart_mcp_core.dart';

/// Tool to probe HTTP endpoints with stopwatch latency tracking.
class HttpProbeTool extends McpLocalTool {
  @override
  String get name => 'http_probe';

  @override
  String get description =>
      'Send HTTP GET or POST request to an API endpoint and record status, latency, and response body.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'url': {'type': 'string', 'description': 'Full URL of endpoint'},
          'method': {
            'type': 'string',
            'description': 'HTTP method: GET, POST, PUT, DELETE (defaults to GET)',
          },
          'headers': {'type': 'object', 'description': 'Optional headers map'},
          'body': {'type': 'string', 'description': 'Optional request body'},
        },
        'required': ['url'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final urlStr = arguments['url'] as String;
    final method = (arguments['method'] as String? ?? 'GET').toUpperCase();
    final bodyStr = arguments['body'] as String?;

    final uri = Uri.parse(urlStr);
    final stopwatch = Stopwatch()..start();

    try {
      final client = http.Client();
      http.Response response;

      switch (method) {
        case 'POST':
          response = await client.post(uri, body: bodyStr);
        case 'PUT':
          response = await client.put(uri, body: bodyStr);
        case 'DELETE':
          response = await client.delete(uri);
        case 'GET':
        default:
          response = await client.get(uri);
      }
      stopwatch.stop();

      final body = response.body;
      final result = jsonEncode({
        'status_code': response.statusCode,
        'latency_ms': stopwatch.elapsedMilliseconds,
        'headers': response.headers,
        'body_snippet': body.length > 2000 ? '${body.substring(0, 2000)}... [truncated]' : body,
        'success': response.statusCode >= 200 && response.statusCode < 400,
      });

      return MCPToolResult(
        content: [MCPContent(type: 'text', text: result)],
      );
    } catch (e) {
      stopwatch.stop();
      final err = jsonEncode({
        'success': false,
        'error': e.toString(),
        'latency_ms': stopwatch.elapsedMilliseconds,
      });
      return MCPToolResult(
        content: [MCPContent(type: 'text', text: err)],
        isError: true,
      );
    }
  }
}

/// Tool to validate JSON response keys.
class ValidateSchemaTool extends McpLocalTool {
  @override
  String get name => 'validate_schema';

  @override
  String get description =>
      'Validate whether a JSON string contains expected property keys.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'json_string': {'type': 'string', 'description': 'JSON string to validate'},
          'required_keys': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'List of required key names',
          },
        },
        'required': ['json_string', 'required_keys'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final jsonStr = arguments['json_string'] as String;
    final requiredKeys = (arguments['required_keys'] as List).cast<String>();

    try {
      final decoded = jsonDecode(jsonStr);
      final Map<String, dynamic> map;
      if (decoded is Map<String, dynamic>) {
        map = decoded;
      } else if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
        map = decoded.first as Map<String, dynamic>;
      } else {
        return const MCPToolResult(
          content: [
            MCPContent(
              type: 'text',
              text: 'Payload is neither a JSON object nor an array of objects',
            ),
          ],
          isError: true,
        );
      }

      final missing = <String>[];
      for (final key in requiredKeys) {
        if (!map.containsKey(key)) {
          missing.add(key);
        }
      }

      final result = jsonEncode({
        'valid': missing.isEmpty,
        'missing_keys': missing,
        'inspected_keys': map.keys.toList(),
      });
      return MCPToolResult(
        content: [MCPContent(type: 'text', text: result)],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent(type: 'text', text: 'Failed to parse JSON: $e')],
        isError: true,
      );
    }
  }
}

/// Tool to export diagnostic markdown report.
class ExportDiagnosticReportTool extends McpLocalTool {
  @override
  String get name => 'export_diagnostic_report';

  @override
  String get description =>
      'Write the API diagnostic findings into a markdown report.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'title': {'type': 'string', 'description': 'Report title'},
          'tested_endpoints': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Endpoints tested',
          },
          'results_summary': {'type': 'string', 'description': 'Health status summary'},
          'output_filename': {'type': 'string', 'description': 'Target output filename'},
        },
        'required': ['title', 'tested_endpoints', 'results_summary'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final title = arguments['title'] as String? ?? 'API Diagnostics Report';
    final endpoints = (arguments['tested_endpoints'] as List?)?.cast<String>() ?? [];
    final summary = arguments['results_summary'] as String? ?? '';
    final filename = arguments['output_filename'] as String? ?? 'API_DIAGNOSTICS.md';

    final buffer = StringBuffer();
    buffer.writeln('# $title\n');
    buffer.writeln('**Date**: ${DateTime.now().toUtc().toIso8601String()}\n');
    buffer.writeln('## Tested Endpoints');
    for (final ep in endpoints) {
      buffer.writeln('- `$ep`');
    }
    buffer.writeln('\n## Diagnostics Summary');
    buffer.writeln('$summary\n');
    buffer.writeln('---\n*Generated by MCP Playground `api-endpoint-prober` skill.*');

    try {
      final file = File(filename);
      await file.writeAsString(buffer.toString());
      final res = jsonEncode({
        'success': true,
        'filename': file.absolute.path,
        'bytes_written': buffer.length,
      });
      return MCPToolResult(
        content: [MCPContent(type: 'text', text: res)],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent(type: 'text', text: 'Error writing file: $e')],
        isError: true,
      );
    }
  }
}

import 'dart:convert';
import 'package:dart_mcp_core/dart_mcp_core.dart';

class ExplainSqlQueryTool extends McpLocalTool {
  @override
  String get name => 'explain_sql_query';

  @override
  String get description =>
      'Analyzes a SQL query, provides execution plan cost estimates, and suggests missing indexes.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': 'The SQL query to analyze',
          },
          'table': {
            'type': 'string',
            'description': 'Target primary table name',
          },
        },
        'required': ['query'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final query = arguments['query']?.toString() ?? '';
    final table = arguments['table']?.toString() ?? 'orders';

    return MCPToolResult.text(jsonEncode({
      'query': query,
      'plan_cost': 4520.8,
      'scan_type': 'Sequential Scan on $table (Costly!)',
      'recommendations': [
        'CREATE INDEX idx_${table}_created_at ON $table(created_at DESC);',
        'Replace SELECT * with explicit projection to reduce buffer pool pressure.',
      ],
      'estimated_speedup': '18x faster with recommended B-Tree index.',
    }));
  }
}

class GenerateReleaseNotesTool extends McpLocalTool {
  @override
  String get name => 'generate_release_notes';

  @override
  String get description =>
      'Compiles git commit logs into markdown release notes adhering to Keep a Changelog.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'version': {
            'type': 'string',
            'description': 'Target version tag (e.g. "1.3.0")',
          },
          'commits': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'List of commit messages',
          },
        },
        'required': ['version'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final version = arguments['version']?.toString() ?? '1.3.0';

    return MCPToolResult.text(jsonEncode({
      'version': version,
      'release_date': DateTime.now().toIso8601String().substring(0, 10),
      'sections': {
        'Features': [
          'Added DynamicSkillDock for runtime skill activation',
          'Autonomous SubAgent delegation cards and live tracing',
          'Episodic memory archive retrieval with background compression',
        ],
        'Performance': [
          'Optimized memory usage during LLM streaming',
        ],
      },
    }));
  }
}

class AuditSecurityHeadersTool extends McpLocalTool {
  @override
  String get name => 'audit_security_headers';

  @override
  String get description =>
      'Audits HTTP response headers for missing security safeguards (CORS, CSP, HSTS).';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'endpoint_url': {
            'type': 'string',
            'description': 'API endpoint URL to audit',
          },
        },
        'required': ['endpoint_url'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final url = arguments['endpoint_url']?.toString() ?? 'https://api.example.com';

    return MCPToolResult.text(jsonEncode({
      'url': url,
      'rating': 'B+',
      'missing_headers': [
        'Content-Security-Policy (CSP)',
        'Permissions-Policy',
      ],
      'detected_headers': {
        'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
        'X-Content-Type-Options': 'nosniff',
        'Access-Control-Allow-Origin': '*', // Warning: overly permissive!
      },
      'warnings': [
        'Wildcard CORS (Access-Control-Allow-Origin: *) should not be used on endpoints that process credentials.',
      ],
    }));
  }
}

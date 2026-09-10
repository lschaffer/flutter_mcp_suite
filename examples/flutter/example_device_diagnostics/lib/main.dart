import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mcp_playground_flutter/mcp_playground_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DeviceDiagnosticsApp());
}

class DeviceDiagnosticsApp extends StatelessWidget {
  const DeviceDiagnosticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device & Network Diagnostics Copilot',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF48A999),
          brightness: Brightness.dark,
        ),
      ),
      home: const DiagnosticsPlaygroundScreen(),
    );
  }
}

class DiagnosticsPlaygroundScreen extends StatelessWidget {
  const DiagnosticsPlaygroundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<McpLocalTool> tools = [
      GetDeviceTelemetryTool(),
      NetworkPingTool(),
      ExportDiagnosticReportTool(),
    ];

    const initialLlm = LlmConfig(
      provider: LlmProvider.openai,
      model: 'gpt-4o-mini',
      apiKey: '',
      useStreaming: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.monitor_heart, color: Color(0xFF00B4D8)),
            SizedBox(width: 8),
            Text('Device & Network Diagnostics'),
          ],
        ),
      ),
      body: McpPlayground(
        initialLlmConfig: initialLlm,
        customLocalTools: tools,
        messageContentBuilder: (context, message) {
          if (message == null || message.type != MessageType.toolResponse) {
            return null;
          }
          final content = message.content.trim();
          if (!content.startsWith('{') || !content.endsWith('}')) return null;

          try {
            final data = jsonDecode(content) as Map<String, dynamic>;

            if (message.toolName == 'get_device_telemetry') {
              return _buildTelemetryCard(context, data);
            } else if (message.toolName == 'network_ping') {
              return _buildPingCard(context, data);
            }
          } catch (_) {}
          return null;
        },
      ),
    );
  }

  Widget _buildTelemetryCard(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.memory, color: Color(0xFF00B4D8)),
                const SizedBox(width: 8),
                Text(
                  'Device Telemetry',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow('OS / Platform', '${data['os']} ${data['os_version']}'),
            _infoRow('Host Name', '${data['hostname']}'),
            _infoRow('CPU Cores', '${data['processor_count']} logical cores'),
            _infoRow('Dart Runtime', '${data['dart_version']}'),
            _infoRow('Locale', '${data['locale']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPingCard(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final success = data['reachable'] == true;
    final latency = data['latency_ms'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Network Ping: ${data['host']}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    success ? 'Status: OK • Latency: ${latency}ms' : 'Status: Unreachable',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Tool to gather system hardware and runtime telemetry.
class GetDeviceTelemetryTool extends McpLocalTool {
  @override
  String get name => 'get_device_telemetry';

  @override
  String get description =>
      'Query device operating system, processor cores, host name, locale, and Dart SDK version.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {},
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final telemetry = {
      'os': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'processor_count': Platform.numberOfProcessors,
      'hostname': Platform.localHostname,
      'locale': Platform.localeName,
      'dart_version': Platform.version.split(' ').first,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
    return MCPToolResult(
      content: [MCPContent(type: 'text', text: jsonEncode(telemetry))],
    );
  }
}

/// Tool to test network latency to target URLs.
class NetworkPingTool extends McpLocalTool {
  @override
  String get name => 'network_ping';

  @override
  String get description =>
      'Send an HTTP HEAD/GET probe to test network connectivity and measure round-trip latency.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'host': {
            'type': 'string',
            'description': 'Target URL or host (e.g. "https://dns.google")',
          },
        },
        'required': ['host'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final host = arguments['host'] as String? ?? 'https://dns.google';
    final uri = Uri.parse(host.startsWith('http') ? host : 'https://$host');
    final sw = Stopwatch()..start();

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      sw.stop();
      final result = {
        'host': host,
        'reachable': res.statusCode >= 200 && res.statusCode < 400,
        'status_code': res.statusCode,
        'latency_ms': sw.elapsedMilliseconds,
      };
      return MCPToolResult(
        content: [MCPContent(type: 'text', text: jsonEncode(result))],
      );
    } catch (e) {
      sw.stop();
      final result = {
        'host': host,
        'reachable': false,
        'error': e.toString(),
        'latency_ms': sw.elapsedMilliseconds,
      };
      return MCPToolResult(
        content: [MCPContent(type: 'text', text: jsonEncode(result))],
      );
    }
  }
}

/// Tool to export diagnostic summary.
class ExportDiagnosticReportTool extends McpLocalTool {
  @override
  String get name => 'export_diagnostic_report';

  @override
  String get description =>
      'Export a diagnostic report containing system information and network benchmarks.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'summary': {'type': 'string', 'description': 'Summary of findings'},
          'recommendations': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Recommendations',
          },
        },
        'required': ['summary'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final summary = arguments['summary'] as String? ?? '';
    final recommendations = (arguments['recommendations'] as List?)?.cast<String>() ?? [];

    final buffer = StringBuffer();
    buffer.writeln('# System & Network Diagnostics Report\n');
    buffer.writeln('**Date**: ${DateTime.now().toUtc().toIso8601String()}\n');
    buffer.writeln('## Summary\n$summary\n');
    if (recommendations.isNotEmpty) {
      buffer.writeln('## Recommendations');
      for (final r in recommendations) {
        buffer.writeln('- $r');
      }
    }

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({'success': true, 'report': buffer.toString()}),
        ),
      ],
    );
  }
}

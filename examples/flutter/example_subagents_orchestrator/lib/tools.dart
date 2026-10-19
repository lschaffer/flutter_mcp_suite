import 'dart:convert';
import 'package:dart_mcp_core/dart_mcp_core.dart';

List<McpLocalTool> getOrchestratorTools() {
  return [
    InspectCodeModuleTool(),
    CheckDependencyVulnerabilitiesTool(),
    QueryTelemetryMetricsTool(),
  ];
}

class InspectCodeModuleTool extends McpLocalTool {
  @override
  String get name => 'inspect_code_module';

  @override
  String get description =>
      'Fetches and inspects the source code and configuration of a service module (auth, billing, database).';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'module': {
            'type': 'string',
            'description': 'Target module name (e.g., auth, billing, database, router)',
          },
        },
        'required': ['module'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final module = arguments['module']?.toString().toLowerCase() ?? 'auth';
    switch (module) {
      case 'auth':
        return MCPToolResult.text(jsonEncode({
          'module': 'auth',
          'file': 'lib/auth/jwt_service.dart',
          'code': '''
class JwtService {
  String generateToken(User user) {
    // SECURITY RISK: Weak static secret and missing expiration
    return JWT.sign({'uid': user.id, 'role': user.role}, 'weak_static_secret');
  }
  bool verifyToken(String token) {
    // Missing revocation check against Redis blacklist!
    return JWT.verify(token, 'weak_static_secret');
  }
}''',
          'lines': 14,
        }));
      case 'billing':
        return MCPToolResult.text(jsonEncode({
          'module': 'billing',
          'file': 'lib/billing/payment_processor.dart',
          'code': '''
class PaymentProcessor {
  Future<PaymentResult> charge(Order order) async {
    // Deadlock prone: locks account before verifying gateway idempotency
    await database.transaction((tx) async {
      await tx.execute('UPDATE accounts SET balance = balance - \${order.amount}');
      final resp = await stripeGateway.charge(order);
      if (!resp.success) throw PaymentFailedException();
    });
  }
}''',
          'lines': 18,
        }));
      case 'database':
        return MCPToolResult.text(jsonEncode({
          'module': 'database',
          'file': 'config/db_pool.yaml',
          'content': '''
pool_size: 150
max_overflow: 50
timeout_seconds: 60
idle_timeout: 300
statement_timeout: 0  # Unbounded query timeout risk!
''',
        }));
      default:
        return MCPToolResult.text(jsonEncode({
          'module': module,
          'status': 'clean',
          'summary': 'Module $module contains standard boilerplate without active warnings.',
        }));
    }
  }
}

class CheckDependencyVulnerabilitiesTool extends McpLocalTool {
  @override
  String get name => 'check_dependency_vulnerabilities';

  @override
  String get description =>
      'Audits software package dependencies and checks against CVE database.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'package_name': {
            'type': 'string',
            'description': 'Specific package to audit, or "all" to audit everything.',
          },
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final pkg = arguments['package_name']?.toString() ?? 'all';
    return MCPToolResult.text(jsonEncode({
      'scanned_at': DateTime.now().toIso8601String(),
      'package': pkg,
      'vulnerabilities': [
        {
          'cve': 'CVE-2025-2410',
          'package': 'crypto_token_lib',
          'installed_version': '1.0.4',
          'fixed_version': '1.2.0',
          'severity': 'HIGH',
          'summary': 'Timing attack vulnerability in signature verification.',
        },
        {
          'cve': 'CVE-2025-1892',
          'package': 'yaml_parser',
          'installed_version': '3.1.0',
          'fixed_version': '3.1.2',
          'severity': 'MEDIUM',
          'summary': 'Denial of service through deeply nested YAML documents.',
        },
      ],
    }));
  }
}

class QueryTelemetryMetricsTool extends McpLocalTool {
  @override
  String get name => 'query_telemetry_metrics';

  @override
  String get description =>
      'Queries live infrastructure metrics for latency, error rate, and connection saturation.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'service_name': {
            'type': 'string',
            'description': 'Service name (e.g. payment-api, auth-gateway)',
          },
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final svc = arguments['service_name']?.toString() ?? 'payment-api';
    return MCPToolResult.text(jsonEncode({
      'service': svc,
      'timestamp': DateTime.now().toIso8601String(),
      'metrics': {
        'requests_per_sec': 1420.5,
        'p50_latency_ms': 18.2,
        'p95_latency_ms': 185.0,
        'p99_latency_ms': 892.4,
        'error_rate_percent': 3.4,
        'db_pool_utilization': 0.94,
        'memory_rss_mb': 512.0,
      },
    }));
  }
}

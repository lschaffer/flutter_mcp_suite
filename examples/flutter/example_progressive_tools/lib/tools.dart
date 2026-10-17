import 'dart:convert';
import 'package:dart_mcp_core/dart_mcp_core.dart';

/// Suite of specialized enterprise tools that would typically bloat LLM context
/// if injected upfront, but are effortlessly discovered on-demand via [McpListToolsTool]
/// and executed via [McpCallToolTool].
List<McpLocalTool> getProgressiveCatalogTools() {
  return [
    CloudClusterTelemetryTool(),
    QueryDatabaseTableTool(),
    InspectCacheStoreTool(),
    SendSlackNotificationTool(),
    CalculateComputeCostTool(),
    TriggerPagerDutyIncidentTool(),
    RotateApiCredentialTool(),
    BenchmarkApiLatencyTool(),
  ];
}

/// Tool 1: Cloud Cluster Telemetry
class CloudClusterTelemetryTool extends McpLocalTool {
  @override
  String get name => 'cloud_cluster_telemetry';

  @override
  String get description =>
      'Query real-time Kubernetes/cloud cluster health, CPU utilization, memory pressure, and active pod counts.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'cluster_name': {
            'type': 'string',
            'description': 'Target cluster identifier (e.g., "prod-us-east-1", "staging-eu-central").',
          },
          'namespace': {
            'type': 'string',
            'description': 'Optional namespace filter (e.g. "default", "billing", "auth").',
          },
        },
        'required': ['cluster_name'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final cluster = arguments['cluster_name'] as String? ?? 'prod-us-east-1';
    final namespace = arguments['namespace'] as String? ?? 'all';

    final data = {
      'cluster': cluster,
      'namespace': namespace,
      'status': 'HEALTHY',
      'node_count': 18,
      'cpu_utilization_percent': 64.2,
      'memory_utilization_percent': 78.5,
      'active_pods': 142,
      'restarting_pods': 0,
      'network_ingress_mbps': 480.5,
      'network_egress_mbps': 820.1,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    return MCPToolResult.text(jsonEncode(data));
  }
}

/// Tool 2: Database Table Query
class QueryDatabaseTableTool extends McpLocalTool {
  @override
  String get name => 'query_database_table';

  @override
  String get description =>
      'Execute a read-only parameterized query against production or staging Postgres/MySQL tables.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'table_name': {
            'type': 'string',
            'description': 'Name of the database table (e.g., "users", "transactions", "audit_log").',
          },
          'limit': {
            'type': 'integer',
            'description': 'Maximum number of records to retrieve (default: 5).',
          },
          'order_by': {
            'type': 'string',
            'description': 'Column to order results by (e.g., "created_at DESC").',
          },
        },
        'required': ['table_name'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final table = arguments['table_name'] as String? ?? 'users';
    final limit = arguments['limit'] as int? ?? 5;

    final rows = List.generate(limit, (i) {
      return {
        'id': 'rec_${1000 + i}',
        'table': table,
        'status': i % 2 == 0 ? 'ACTIVE' : 'VERIFIED',
        'amount': (i + 1) * 125.50,
        'created_at': DateTime.now()
            .subtract(Duration(hours: (i + 1) * 3))
            .toIso8601String(),
      };
    });

    final payload = {
      'table': table,
      'row_count': rows.length,
      'columns': ['id', 'table', 'status', 'amount', 'created_at'],
      'records': rows,
    };

    return MCPToolResult.text(jsonEncode(payload));
  }
}

/// Tool 3: Cache Store Inspector
class InspectCacheStoreTool extends McpLocalTool {
  @override
  String get name => 'inspect_cache_store';

  @override
  String get description =>
      'Inspect Redis cluster key distribution, memory usage, cache hit ratio, and evictions.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'cache_instance': {
            'type': 'string',
            'description': 'Redis instance ID or endpoint (e.g. "redis-session-master").',
          },
          'key_pattern': {
            'type': 'string',
            'description': 'Optional key glob pattern to count matches (e.g. "user:session:*").',
          },
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final instance = arguments['cache_instance'] as String? ?? 'redis-primary';
    final pattern = arguments['key_pattern'] as String? ?? '*';

    final data = {
      'instance': instance,
      'pattern': pattern,
      'connected_clients': 382,
      'used_memory_human': '4.21 GB',
      'max_memory_human': '8.00 GB',
      'hit_ratio_percent': 98.4,
      'evictions_last_hour': 0,
      'matched_keys': 18420,
    };

    return MCPToolResult.text(jsonEncode(data));
  }
}

/// Tool 4: Slack Notification Dispatcher
class SendSlackNotificationTool extends McpLocalTool {
  @override
  String get name => 'send_slack_notification';

  @override
  String get description =>
      'Post a structured message, alert, or status report to designated Slack channels.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.network;

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'channel': {
            'type': 'string',
            'description': 'Target Slack channel name or ID (e.g. "#devops-alerts", "#engineering").',
          },
          'message': {
            'type': 'string',
            'description': 'Markdown text content or alert summary to send.',
          },
          'severity': {
            'type': 'string',
            'enum': ['info', 'warning', 'critical'],
            'description': 'Alert level indicator.',
          },
        },
        'required': ['channel', 'message'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final channel = arguments['channel'] as String? ?? '#alerts';
    final message = arguments['message'] as String? ?? '';
    final severity = arguments['severity'] as String? ?? 'info';

    final res = {
      'delivered': true,
      'channel': channel,
      'severity': severity,
      'preview': message.length > 80 ? '${message.substring(0, 80)}...' : message,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'message_id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
    };

    return MCPToolResult.text(jsonEncode(res));
  }
}

/// Tool 5: Cloud Compute Cost Calculator
class CalculateComputeCostTool extends McpLocalTool {
  @override
  String get name => 'calculate_compute_cost';

  @override
  String get description =>
      'Estimate monthly cloud infrastructure billing across AWS EC2, GCP Compute Engine, and Azure VMs.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'instance_count': {
            'type': 'integer',
            'description': 'Number of virtual machine instances.',
          },
          'vcpus_per_instance': {
            'type': 'integer',
            'description': 'Logical CPU cores per instance (e.g. 4, 8, 16).',
          },
          'ram_gb_per_instance': {
            'type': 'integer',
            'description': 'Memory allocation in GB (e.g. 16, 32, 64).',
          },
          'cloud_provider': {
            'type': 'string',
            'enum': ['aws', 'gcp', 'azure'],
            'description': 'Cloud vendor to compare pricing.',
          },
        },
        'required': ['instance_count'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final count = arguments['instance_count'] as int? ?? 1;
    final vcpus = arguments['vcpus_per_instance'] as int? ?? 4;
    final ram = arguments['ram_gb_per_instance'] as int? ?? 16;
    final provider = (arguments['cloud_provider'] as String? ?? 'aws').toUpperCase();

    // Baseline calculation
    final hourlyPerInstance = (vcpus * 0.045) + (ram * 0.005);
    final monthlyTotal = hourlyPerInstance * 730 * count;

    final estimate = {
      'provider': provider,
      'instance_count': count,
      'specs': '$vcpus vCPU / $ram GB RAM',
      'hourly_per_instance_usd': double.parse(hourlyPerInstance.toStringAsFixed(4)),
      'monthly_total_usd': double.parse(monthlyTotal.toStringAsFixed(2)),
      'recommended_reserved_saving_pct': 38,
      'discounted_annual_usd': double.parse((monthlyTotal * 12 * 0.62).toStringAsFixed(2)),
    };

    return MCPToolResult.text(jsonEncode(estimate));
  }
}

/// Tool 6: PagerDuty Incident Trigger
class TriggerPagerDutyIncidentTool extends McpLocalTool {
  @override
  String get name => 'trigger_pagerduty_incident';

  @override
  String get description =>
      'Create and dispatch an escalation incident to on-call engineering engineers.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.network;

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'title': {
            'type': 'string',
            'description': 'Short headline of the incident outage or anomaly.',
          },
          'urgency': {
            'type': 'string',
            'enum': ['low', 'high'],
            'description': 'Severity priority for paging.',
          },
          'service': {
            'type': 'string',
            'description': 'Affected service name (e.g. "payment-gateway", "auth-service").',
          },
        },
        'required': ['title', 'service'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final title = arguments['title'] as String? ?? 'Service Anomaly';
    final urgency = arguments['urgency'] as String? ?? 'high';
    final service = arguments['service'] as String? ?? 'core-api';

    final incident = {
      'incident_key': 'PD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'title': title,
      'service': service,
      'urgency': urgency,
      'status': 'TRIGGERED',
      'assigned_escalation_policy': 'Primary Tier 1 On-Call',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    return MCPToolResult.text(jsonEncode(incident));
  }
}

/// Tool 7: Rotate API Credential
class RotateApiCredentialTool extends McpLocalTool {
  @override
  String get name => 'rotate_api_credential';

  @override
  String get description =>
      'Rotate authentication tokens or API secret keys with seamless zero-downtime overlap.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.execute;

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'credential_id': {
            'type': 'string',
            'description': 'Target API token ID to regenerate.',
          },
          'grace_period_hours': {
            'type': 'integer',
            'description': 'Hours to keep old key active during rollout (default: 24).',
          },
        },
        'required': ['credential_id'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final credId = arguments['credential_id'] as String? ?? 'key-default';
    final grace = arguments['grace_period_hours'] as int? ?? 24;

    final result = {
      'rotated': true,
      'credential_id': credId,
      'new_token_prefix': 'sk_live_mcp_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}***',
      'old_key_expiry': DateTime.now().add(Duration(hours: grace)).toIso8601String(),
      'status': 'ACTIVE_DUAL_KEY_MODE',
    };

    return MCPToolResult.text(jsonEncode(result));
  }
}

/// Tool 8: Network HTTP Latency Benchmark
class BenchmarkApiLatencyTool extends McpLocalTool {
  @override
  String get name => 'benchmark_api_latency';

  @override
  String get description =>
      'Benchmark round-trip network response latency against an HTTP endpoint.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'endpoint': {
            'type': 'string',
            'description': 'HTTP target URL (e.g. "https://api.github.com" or "https://httpbin.org/get").',
          },
        },
        'required': ['endpoint'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final endpoint = arguments['endpoint'] as String? ?? 'https://httpbin.org/get';

    // Return realistic benchmark statistics
    final benchmark = {
      'target': endpoint,
      'probes': 3,
      'min_ms': 42.1,
      'avg_ms': 48.7,
      'max_ms': 56.3,
      'status': 'REACHABLE',
      'http_status': 200,
    };

    return MCPToolResult.text(jsonEncode(benchmark));
  }
}

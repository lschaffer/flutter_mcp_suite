import 'package:flutter_ui_mcp/flutter_ui_mcp.dart';
import 'env_loader.dart';

/// Local tool for reading architecture specifications (read risk level).
class ReadProjectSpecTool extends McpLocalTool {
  @override
  String get name => 'read_project_spec';

  @override
  String get description =>
      'Reads system architecture specification and infrastructure topology.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.read;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'component': {
        'type': 'string',
        'description': 'Target component (e.g. "ingress", "storage", "all")',
      },
    },
  };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final component = arguments['component'] as String? ?? 'all';
    return MCPToolResult.text('''
# System Topology Specification ($component)
- Cluster: prod-eu-central-1
- Ingress: Envoy Gateway v1.28
- Database: PostgreSQL 16 (TimescaleDB)
- Broker: Redpanda (3 nodes)
- Cache: Redis 7.2 Cluster
All production operations require HITL authorization for write and execute scopes.
''');
  }
}

/// Local filesystem write tool (write risk level).
/// Guarded by controller.checkPlanModeToolRestriction in /plan mode.
class FsWriteFileTool extends McpLocalTool {
  @override
  String get name => 'fs_write_file';

  @override
  String get description =>
      'Writes or updates a file on the local filesystem. Guarded by Plan Mode policy.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.write;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description':
            'Target file path (e.g. "tasks.md", "architecture_plan.md", "lib/main.dart")',
      },
      'content': {
        'type': 'string',
        'description': 'Text content to write to the file',
      },
    },
    'required': ['path', 'content'],
  };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final path = arguments['path'] as String? ?? 'unknown.txt';
    final content = arguments['content'] as String? ?? '';
    return MCPToolResult.text(
      'Successfully wrote ${content.length} characters to "$path".',
    );
  }
}

/// Local database migration execution tool (execute risk level).
class RunDatabaseMigrationTool extends McpLocalTool {
  @override
  String get name => 'run_database_migration';

  @override
  String get description =>
      'Applies DDL database migration scripts to production PostgreSQL cluster.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.execute;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'migration_name': {
        'type': 'string',
        'description':
            'Name of SQL migration script (e.g. "V2__add_payments_table.sql")',
      },
      'dry_run': {
        'type': 'boolean',
        'description': 'Whether to run migration in preview mode',
      },
    },
    'required': ['migration_name'],
  };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final migration = arguments['migration_name'] as String? ?? 'V1__init.sql';
    final dryRun = arguments['dry_run'] as bool? ?? false;
    return MCPToolResult.text(
      'Database migration "$migration" executed successfully (dry_run: $dryRun). '
      'Applied changes: 4 tables altered, 2 indexes created, 0 rollbacks.',
    );
  }
}

/// Local cloud telemetry query tool (network risk level).
class FetchCloudTelemetryTool extends McpLocalTool {
  @override
  String get name => 'fetch_cloud_telemetry';

  @override
  String get description =>
      'Queries live Prometheus/Grafana telemetry metrics from the cloud cluster.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.network;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'service': {
        'type': 'string',
        'description': 'Service name (e.g. "api-gateway", "worker-queue")',
      },
      'window_minutes': {
        'type': 'integer',
        'description': 'Query time window in minutes',
      },
    },
    'required': ['service'],
  };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final service = arguments['service'] as String? ?? 'api-gateway';
    return MCPToolResult.text(
      'Telemetry for "$service": CPU 42%, Memory 61%, P99 Latency 14.2ms, Error rate 0.001%.',
    );
  }
}

/// Showcase screen demonstrating Human-in-the-Loop (HITL) tool permissions,
/// Plan Mode Guard against code writes, and Document Export (PDF, DOCX, Markdown).
class HitlPermissionsExportExampleScreen extends StatefulWidget {
  const HitlPermissionsExportExampleScreen({super.key});

  @override
  State<HitlPermissionsExportExampleScreen> createState() =>
      _HitlPermissionsExportExampleScreenState();
}

class _HitlPermissionsExportExampleScreenState
    extends State<HitlPermissionsExportExampleScreen> {
  late final PlaygroundController _controller;
  final TextEditingController _inputController = TextEditingController();

  static const String _samplePlanMarkdown = '''# Architecture Plan: High-Throughput Event Ingestion Engine

## 1. Executive Summary
This architectural document outlines the target design for migrating legacy polling workers to an event-driven stream architecture with sub-millisecond p99 latency guarantees and strict zero data-loss semantics.

## 2. Component Topology & Responsibility
- **Edge API Gateway (Envoy 1.28)**: TLS 1.3 termination, JWT validation, adaptive rate limiting, and HTTP/2 multiplexing.
- **Message Broker (Redpanda Cluster)**: 3-broker quorum, Raft consensus, zero-copy socket transfers, and partition replication factor of 3.
- **Stateful Ingestion Worker (Dart/Go)**: Consumes partitions with consumer groups, performs schema validation against Schema Registry, and batches inserts.
- **Durable Storage (PostgreSQL 16 TimescaleDB)**: Hypertables partitioned by timestamp with automated chunk compression and continuous aggregates.
- **Distributed Cache (Redis 7.2)**: Token buckets, idempotent deduplication keys with 24-hour TTL, and connection pooling.

## 3. Implementation Milestones & Tasks
- [x] **Milestone 1**: Benchmarking baseline consumer throughput under 50k req/s load.
- [ ] **Milestone 2**: Deploy Redpanda schema registry and protobuf definitions.
- [ ] **Milestone 3**: Run database migration `V2__add_event_hypertables.sql`.
- [ ] **Milestone 4**: Conduct failover drills by isolating Broker 2 and measuring recovery RTO.

## 4. Security & Compliance Guardrails
- **Human-in-the-Loop (HITL)**: All destructive schema migrations (`execute`) and storage configurations (`write`) require human confirmation.
- **Data Protection**: AES-GCM-256 encryption at rest, mTLS in transit, and immutable audit logs.
''';

  @override
  void initState() {
    super.initState();

    final initialLlm = LlmConfig(
      provider: EnvLoader.getProvider(),
      model: EnvLoader.get('LLM_MODEL', defaultValue: 'gpt-4o'),
      apiKey: EnvLoader.get('LLM_API_KEY'),
      baseUrl: EnvLoader.get('LLM_URL'),
    );

    _controller = PlaygroundController(
      initialLlmConfig:
          initialLlm.provider != LlmProvider.none ? initialLlm : null,
      customLocalTools: [
        ReadProjectSpecTool(),
        FsWriteFileTool(),
        RunDatabaseMigrationTool(),
        FetchCloudTelemetryTool(),
      ],
      enableLogging: true,
    );

    // Initial permissions: Auto-approve Read & Network, require confirmation for Write & Execute
    _controller.permissions = ToolPermissionSettings(
      autoApproveRead: true,
      autoApproveNetwork: true,
      autoApproveWrite: false,
      autoApproveExecute: false,
    );

    // Start in /plan mode to demonstrate Plan Mode Guard against code edits
    _controller.codingSubMode = '/plan';

    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _showPermissionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final perms = _controller.permissions;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: Color(0xFF0D9488)),
                      const SizedBox(width: 10),
                      Text(
                        'HITL Tool Permission Settings',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure which tool risk levels are executed automatically vs. '
                    'pausing for explicit user approval via PendingToolApprovalCard.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    title: const Text('Auto-approve Read Tools'),
                    subtitle: const Text(
                      'Safe read-only operations (e.g. read_project_spec, grep, find)',
                    ),
                    secondary: const Icon(Icons.visibility, color: Colors.green),
                    value: perms.autoApproveRead,
                    onChanged: (val) {
                      setSheetState(() => perms.autoApproveRead = val);
                      _controller.permissions = perms;
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Auto-approve Network Tools'),
                    subtitle: const Text(
                      'Outbound API and telemetry queries (e.g. fetch_cloud_telemetry)',
                    ),
                    secondary: const Icon(Icons.cloud_outlined, color: Colors.cyan),
                    value: perms.autoApproveNetwork,
                    onChanged: (val) {
                      setSheetState(() => perms.autoApproveNetwork = val);
                      _controller.permissions = perms;
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Auto-approve Write Tools'),
                    subtitle: const Text(
                      'Modifying or creating files (e.g. fs_write_file)',
                    ),
                    secondary: const Icon(Icons.edit_note, color: Colors.orange),
                    value: perms.autoApproveWrite,
                    onChanged: (val) {
                      setSheetState(() => perms.autoApproveWrite = val);
                      _controller.permissions = perms;
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Auto-approve Execute Tools'),
                    subtitle: const Text(
                      'High-risk terminal or database commands (e.g. run_database_migration)',
                    ),
                    secondary: const Icon(Icons.terminal, color: Colors.redAccent),
                    value: perms.autoApproveExecute,
                    onChanged: (val) {
                      setSheetState(() => perms.autoApproveExecute = val);
                      _controller.permissions = perms;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _exportSamplePlan(String format) {
    DocumentExportService.exportDocument(
      context: context,
      markdownContent: _samplePlanMarkdown,
      format: format,
      workspaceDirectory: _controller.workspaceDirectory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPlanMode = _controller.codingSubMode == '/plan';

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HITL Permissions & Document Export'),
            Text(
              'Tool Approvals • Plan Guard • PDF/Word Export',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // Sub-mode badge button (/plan vs /code)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ActionChip(
              avatar: Icon(
                isPlanMode ? Icons.lightbulb_outline : Icons.code,
                size: 16,
                color: isPlanMode ? Colors.amber : Colors.tealAccent,
              ),
              label: Text(
                _controller.codingSubMode,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              tooltip: 'Switch Mode (/plan guards code files from writes)',
              onPressed: () {
                setState(() {
                  _controller.codingSubMode = isPlanMode ? '/code' : '/plan';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 2),
                    content: Text(
                      _controller.codingSubMode == '/plan'
                          ? 'Switched to /plan mode: Writing to code files is BLOCKED.'
                          : 'Switched to /code mode: Code modifications permitted (subject to HITL approval).',
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          // Document Export popup menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Sample Architecture Document',
            onSelected: _exportSamplePlan,
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text('Export Plan as PDF (.pdf)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'docx',
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.blueAccent, size: 20),
                    SizedBox(width: 10),
                    Text('Export Plan as Word (.docx)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'md',
                child: Row(
                  children: [
                    Icon(Icons.article, color: Colors.teal, size: 20),
                    SizedBox(width: 10),
                    Text('Export Plan as Markdown (.md)'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'HITL Permission Settings',
            onPressed: _showPermissionsSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner with Mode indicator and prompt helper chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isPlanMode
                  ? (isDark ? const Color(0xFF2E2405) : const Color(0xFFFEF3C7))
                  : (isDark ? const Color(0xFF062C27) : const Color(0xFFCCFBF1)),
              border: Border(
                bottom: BorderSide(
                  color: isPlanMode
                      ? (isDark ? const Color(0xFFD97706) : const Color(0xFFF59E0B))
                      : (isDark ? const Color(0xFF0D9488) : const Color(0xFF14B8A6)),
                  width: 1.2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isPlanMode ? Icons.shield : Icons.check_circle_outline,
                      size: 16,
                      color: isPlanMode
                          ? const Color(0xFFF59E0B)
                          : (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isPlanMode
                            ? 'Plan Mode Active: Code modifications (.dart, .py, etc.) are restricted to protect production files.'
                            : 'Code Mode Active: Tools can write files directly, subject to HITL user confirmation.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isPlanMode
                              ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E))
                              : (isDark ? const Color(0xFF99F6E4) : const Color(0xFF115E59)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.bolt, size: 14, color: Colors.redAccent),
                        label: const Text('Test Execute HITL'),
                        tooltip: 'Triggers run_database_migration (Requires execute approval)',
                        onPressed: () {
                          _controller.setInputPrompt(
                            'Execute tool run_database_migration with migration_name: "V2__add_payments_table.sql" and dry_run: false.',
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.edit, size: 14, color: Colors.orangeAccent),
                        label: const Text('Test Write HITL'),
                        tooltip: 'Triggers fs_write_file on tasks.md (Requires write approval)',
                        onPressed: () {
                          _controller.setInputPrompt(
                            'Execute fs_write_file to update "tasks.md" with Phase 3 deployment checklist.',
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.block, size: 14, color: Colors.amberAccent),
                        label: const Text('Test Plan Guard'),
                        tooltip: 'Attempts to write to lib/main.dart (Blocked in /plan mode!)',
                        onPressed: () {
                          _controller.setInputPrompt(
                            'Execute fs_write_file on "lib/main.dart" with new auth middleware.',
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.auto_stories, size: 14, color: Colors.cyanAccent),
                        label: const Text('Draft Exportable Plan'),
                        tooltip: 'Asks the agent to generate a plan with export buttons',
                        onPressed: () {
                          _controller.setInputPrompt(
                            'Generate a structured # Architecture Plan for real-time order processing with executive summary, components, and implementation tasks.',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main McpPlayground instance
          Expanded(
            child: McpPlayground(
              controller: _controller,
              inputController: _inputController,
              initialEnabledTools: const [
                'read_project_spec',
                'fs_write_file',
                'run_database_migration',
                'fetch_cloud_telemetry',
              ],
              initialSystemPrompt:
                  'You are an expert Systems Architect with access to Human-in-the-Loop tools.\n'
                  '- When asked to read specs, invoke "read_project_spec".\n'
                  '- When writing plans or tasks, invoke "fs_write_file". In /plan mode, you can only write to .md or tasks files.\n'
                  '- When executing database changes, invoke "run_database_migration".\n'
                  '- When asked for architectural designs, output structured Markdown with "# Architecture Plan" headings so the user can export to PDF, Word, or Markdown.',
            ),
          ),
        ],
      ),
    );
  }
}


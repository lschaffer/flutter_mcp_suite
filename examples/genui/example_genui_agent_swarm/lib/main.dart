import 'dart:convert';
import 'package:flutter_genui_mcp/flutter_genui_mcp.dart';
import 'env_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const GenuiAgentSwarmApp());
}

class GenuiAgentSwarmApp extends StatelessWidget {
  const GenuiAgentSwarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI Autonomous Multi-Agent Mission Control',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7), // Sky Cyan / Mission Control
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38BDF8),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      home: const AgentSwarmScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. Swarm Orchestration MCP Tools
// ═══════════════════════════════════════════════════════════════

class SpawnSubagentTool extends McpLocalTool {
  @override
  String get name => 'spawn_subagent';

  @override
  String get description =>
      'Spawn an autonomous multi-turn specialist subagent to perform an isolated objective and report back.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'agent_role': {
            'type': 'string',
            'description': 'Specialist role: security_auditor, researcher, code_architect, or test_engineer',
          },
          'objective': {
            'type': 'string',
            'description': 'Specific goal or task to execute autonomously',
          },
          'max_turns': {
            'type': 'integer',
            'description': 'Maximum autonomous turn iterations (default 5)',
          },
        },
        'required': ['agent_role', 'objective'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final role = arguments['agent_role']?.toString() ?? 'researcher';
    final objective = arguments['objective']?.toString() ?? 'Analyze objective';
    final maxTurns = (arguments['max_turns'] as num?)?.toInt() ?? 5;

    // Simulate multi-step autonomous execution loop
    final executionLog = [
      {'turn': 1, 'action': 'initialize_context', 'status': 'completed', 'detail': 'Loaded workspace manifests and security policies.'},
      {'turn': 2, 'action': 'search_references', 'status': 'completed', 'detail': 'Discovered 4 architectural vulnerabilities in authentication module.'},
      {'turn': 3, 'action': 'generate_patch', 'status': 'completed', 'detail': 'Formulated cryptographic HMAC token validation routine.'},
      {'turn': 4, 'action': 'synthesize_verdict', 'status': 'completed', 'detail': 'Prepared final audit dossier and remediation recommendations.'},
    ];

    final result = {
      'agent_id': 'subagent-${DateTime.now().millisecondsSinceEpoch % 10000}',
      'role': role,
      'objective': objective,
      'status': 'completed',
      'executed_turns': 4,
      'max_turns': maxTurns,
      'tokens_consumed': 2840,
      'tool_calls_count': 3,
      'findings': 'Completed autonomous inspection. Found 4 security considerations with proposed mitigations.',
      'execution_log': executionLog,
    };

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({'success': true, 'subagent_execution': result}),
        ),
      ],
    );
  }
}

class QuerySwarmStatusTool extends McpLocalTool {
  @override
  String get name => 'query_swarm_status';

  @override
  String get description => 'Query the active status, resource consumption, and deliverables across all subagents in the swarm.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {},
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final swarmState = {
      'active_agents_count': 3,
      'completed_tasks_count': 7,
      'total_tokens_consumed': 14820,
      'pipeline_status': 'active',
      'agents': [
        {
          'id': 'agent-sec-1',
          'role': 'Security Auditor',
          'status': 'completed',
          'current_task': 'OWASP dependency vulnerability scan',
          'progress': 1.0,
        },
        {
          'id': 'agent-arch-2',
          'role': 'Code Architect',
          'status': 'running',
          'current_task': 'Modularizing auth microservice',
          'progress': 0.65,
        },
        {
          'id': 'agent-qa-3',
          'role': 'Test Engineer',
          'status': 'waiting_approval',
          'current_task': 'Execute destructive load test on staging endpoint',
          'progress': 0.40,
        },
      ],
    };

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({'success': true, 'swarm': swarmState}),
        ),
      ],
    );
  }
}

class RequestHumanApprovalTool extends McpLocalTool {
  @override
  String get name => 'request_human_approval';

  @override
  String get description => 'Halt autonomous loop and present an interactive decision gate for human approval before critical actions.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'action_name': {'type': 'string', 'description': 'The critical action requiring approval'},
          'risk_level': {'type': 'string', 'description': 'low, medium, high, or critical'},
          'description': {'type': 'string', 'description': 'Explanation of proposed action and side-effects'},
        },
        'required': ['action_name', 'risk_level', 'description'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({
            'success': true,
            'gate_status': 'pending_user_decision',
            'action': arguments['action_name'],
            'risk': arguments['risk_level'],
            'description': arguments['description'],
          }),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. Custom GenUI Catalog Items
// ═══════════════════════════════════════════════════════════════

// --- A. Agent Swarm Timeline ---
final swarmTimelineSchema = S.object(
  description: 'Visual step-by-step pipeline displaying multi-agent progress and statuses.',
  properties: {
    'title': S.string(),
    'overall_progress': S.number(),
    'agents': S.list(
      items: S.object(
        properties: {
          'id': S.string(),
          'role': S.string(),
          'status': S.string(), // running, completed, waiting_approval, blocked
          'current_task': S.string(),
          'progress': S.number(),
        },
        required: ['id', 'role', 'status', 'current_task'],
      ),
    ),
  },
  required: ['title', 'agents'],
);

final swarmTimelineItem = CatalogItem(
  name: 'AgentSwarmTimeline',
  dataSchema: swarmTimelineSchema,
  widgetBuilder: (itemContext) => _AgentSwarmTimelineWidget(itemContext: itemContext),
);

class _AgentSwarmTimelineWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _AgentSwarmTimelineWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final title = data['title']?.toString() ?? 'Multi-Agent Pipeline Progression';
    final agents = (data['agents'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.hub, color: theme.colorScheme.onPrimaryContainer, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${agents.length} Specialists',
                    style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...agents.map((a) {
              final status = a['status']?.toString() ?? 'running';
              final role = a['role']?.toString() ?? 'Specialist';
              final task = a['current_task']?.toString() ?? '';
              final prog = (a['progress'] as num?)?.toDouble() ?? 0.0;

              Color statusColor;
              IconData statusIcon;
              switch (status) {
                case 'completed':
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  break;
                case 'waiting_approval':
                  statusColor = Colors.amber;
                  statusIcon = Icons.pause_circle_filled;
                  break;
                case 'blocked':
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                  break;
                default:
                  statusColor = Colors.blue;
                  statusIcon = Icons.sync;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(statusIcon, color: statusColor, size: 18),
                              const SizedBox(width: 8),
                              Text(role, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          Text(
                            status.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(task, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: prog,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// --- B. Subagent Execution Card ---
final subagentCardSchema = S.object(
  description: 'Detailed report card showing a specialist subagent findings, turns, and resource usage.',
  properties: {
    'role': S.string(),
    'agent_id': S.string(),
    'objective': S.string(),
    'executed_turns': S.integer(),
    'tokens_consumed': S.integer(),
    'findings': S.string(),
    'status': S.string(),
  },
  required: ['role', 'objective', 'findings'],
);

final subagentCardItem = CatalogItem(
  name: 'SubagentCard',
  dataSchema: subagentCardSchema,
  widgetBuilder: (itemContext) => _SubagentCardWidget(itemContext: itemContext),
);

class _SubagentCardWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _SubagentCardWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final role = data['role']?.toString() ?? 'Specialist Subagent';
    final id = data['agent_id']?.toString() ?? 'subagent';
    final objective = data['objective']?.toString() ?? '';
    final turns = data['executed_turns']?.toString() ?? '4';
    final tokens = data['tokens_consumed']?.toString() ?? '2,840';
    final findings = data['findings']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'completed';
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.smart_toy, color: Colors.blue, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(role, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(id, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assigned Objective:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(objective, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Turns Run', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text('$turns iterations', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tokens Consumed', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text('$tokens tokens', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Autonomous Findings & Deliverables:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(findings, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// --- C. Human-In-The-Loop Approval Gate Widget ---
final approvalGateSchema = S.object(
  description: 'Interactive human-in-the-loop approval gate for authorizing critical subagent actions.',
  properties: {
    'action_name': S.string(),
    'risk_level': S.string(), // low, medium, high, critical
    'description': S.string(),
    'recommendation': S.string(),
  },
  required: ['action_name', 'risk_level', 'description'],
);

final approvalGateItem = CatalogItem(
  name: 'ApprovalGateWidget',
  dataSchema: approvalGateSchema,
  widgetBuilder: (itemContext) => _ApprovalGateWidget(itemContext: itemContext),
);

class _ApprovalGateWidget extends StatefulWidget {
  final CatalogItemContext itemContext;
  const _ApprovalGateWidget({required this.itemContext});

  @override
  State<_ApprovalGateWidget> createState() => _ApprovalGateWidgetState();
}

class _ApprovalGateWidgetState extends State<_ApprovalGateWidget> {
  String? _decision;

  @override
  Widget build(BuildContext context) {
    final data = widget.itemContext.data as Map<String, dynamic>? ?? {};
    final action = data['action_name']?.toString() ?? 'Deploy Code Changes';
    final risk = data['risk_level']?.toString() ?? 'medium';
    final desc = data['description']?.toString() ?? '';
    final rec = data['recommendation']?.toString();
    final theme = Theme.of(context);

    final isCritical = risk == 'critical' || risk == 'high';
    final riskColor = isCritical ? Colors.red : Colors.orange;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: riskColor.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.gavel, color: riskColor, size: 22),
                    const SizedBox(width: 8),
                    Text('Human-in-the-Loop Decision Gate', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${risk.toUpperCase()} RISK',
                    style: TextStyle(color: riskColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Text(desc, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            if (rec != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Recommendation: $rec', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
              ),
            ],
            const SizedBox(height: 14),
            if (_decision != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _decision == 'approved' ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Decision Recorded: ${_decision!.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _decision == 'approved' ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _decision = 'rejected');
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject / Halt'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() => _decision = 'approved');
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve Action'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 3. Screen Setup & System Prompt
// ═══════════════════════════════════════════════════════════════

const String agentSwarmSystemPrompt = '''
You are the Supreme Mission Control AI Orchestrator.
You command a swarm of autonomous specialist subagents:
- Security Auditor (vulnerability scans, auth verification)
- Code Architect (structural refactoring, design pattern analysis)
- Test Engineer (load testing, QA assertion runs)

When executing complex multi-step objectives:
1. Invoke tools:
   - `spawn_subagent` to delegate tasks to autonomous specialist loops.
   - `query_swarm_status` to monitor live pipeline progress.
   - `request_human_approval` before executing high-risk state changes.
2. Render rich, interactive GenUI components:
   - "AgentSwarmTimeline" to show visual pipeline progression across all specialists.
   - "SubagentCard" to detail individual subagent findings, turns, and resource usage.
   - "ApprovalGateWidget" when human authorization is needed.
''';

class AgentSwarmScreen extends StatelessWidget {
  const AgentSwarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = BasicCatalogItems.asNoAssetCatalog().copyWith(
      newItems: [
        swarmTimelineItem,
        subagentCardItem,
        approvalGateItem,
      ],
    );

    final initialLlm = LlmConfig(
      provider: EnvLoader.getProvider(),
      model: EnvLoader.get('LLM_MODEL', defaultValue: 'gpt-4o'),
      apiKey: EnvLoader.get('LLM_API_KEY'),
      baseUrl: EnvLoader.get('LLM_URL'),
    );

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hub, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'GenUI Autonomous Multi-Agent Mission Control',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: GenuiMcpPlayground(
        initialLlmConfig: initialLlm.provider != LlmProvider.none ? initialLlm : null,
        customLocalTools: [
          SpawnSubagentTool(),
          QuerySwarmStatusTool(),
          RequestHumanApprovalTool(),
        ],
        initialEnabledTools: const [
          'spawn_subagent',
          'query_swarm_status',
          'request_human_approval',
        ],
        initialSystemPrompt: agentSwarmSystemPrompt,
        genuiCatalog: catalog,
        showAgentInspector: true,
      ),
    );
  }
}

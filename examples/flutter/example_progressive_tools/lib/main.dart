import 'dart:convert';
import 'package:flutter_ui_mcp/flutter_ui_mcp.dart';
import 'env_loader.dart';
import 'tools.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const ProgressiveToolsExampleApp());
}

class ProgressiveToolsExampleApp extends StatelessWidget {
  const ProgressiveToolsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Progressive MCP Tool Discovery',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5), // Indigo
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(scrolledUnderElevation: 0),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF818CF8), // Soft Violet Indigo
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(scrolledUnderElevation: 0),
      ),
      home: const ProgressiveToolsScreen(),
    );
  }
}

const String progressiveSystemPrompt = '''
You are a Cloud Infrastructure & SRE Operations Assistant.
You have access to a progressive discovery architecture using two meta-tools:
1. `mcp_list_tools`: Searches and discovers available specialized tools on demand without loading all schemas into your initial context.
2. `mcp_call_tool`: Executes any discovered tool by specifying `tool_name` and `arguments`.

Workflow:
- When a user asks a question, discover relevant tools first using `mcp_list_tools` (use the `query` parameter to find specific tools, e.g. "cluster", "slack", "database").
- Once you see the required tool schema and parameters, execute it via `mcp_call_tool`.
- Synthesize all results clearly and present actionable findings directly.
''';

class ProgressiveToolsScreen extends StatefulWidget {
  const ProgressiveToolsScreen({super.key});

  @override
  State<ProgressiveToolsScreen> createState() => _ProgressiveToolsScreenState();
}

class _ProgressiveToolsScreenState extends State<ProgressiveToolsScreen> {
  final List<McpLocalTool> _allCatalogTools = getProgressiveCatalogTools();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Load initial LLM configuration if configured in .env
    final initialLlm = LlmConfig(
      provider: EnvLoader.getProvider(),
      model: EnvLoader.get('LLM_MODEL', defaultValue: 'gpt-4o'),
      apiKey: EnvLoader.get('LLM_API_KEY'),
      baseUrl: EnvLoader.get('LLM_URL'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Progressive Tool Discovery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'McpListToolsTool & McpCallToolTool Demo',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.architecture),
            tooltip: 'How Progressive Discovery Works',
            onPressed: () => _showArchitectureDialog(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.indigo.shade900.withValues(alpha: 0.35)
                  : Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.compress,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Prompt Token Savings: 2 Meta-Tools in Context (~220 tokens) vs ${_allCatalogTools.length} Tools (~3,200 tokens)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '93% SAVED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: McpPlayground(
        initialLlmConfig: initialLlm.provider != LlmProvider.none ? initialLlm : null,
        progressiveMcpDiscovery: true,
        customLocalTools: _allCatalogTools,
        initialSystemPrompt: progressiveSystemPrompt,
        initialEnabledTools: const [
          'mcp_list_tools',
          'mcp_call_tool',
        ],
        messageContentBuilder: (context, message) {
          if (message == null || message.type != MessageType.toolResponse) {
            return null;
          }
          final content = message.content.trim();

          // Custom visual rendering for progressive discovery tools
          if (message.toolName == 'mcp_list_tools') {
            return _buildListToolsCard(context, content);
          }

          if (message.toolName == 'mcp_call_tool') {
            return _buildCallToolCard(context, content);
          }

          // Individual sub-tool JSON rendering
          if (content.startsWith('{') && content.endsWith('}')) {
            try {
              final data = jsonDecode(content) as Map<String, dynamic>;
              if (message.toolName == 'cloud_cluster_telemetry') {
                return _buildClusterTelemetryCard(context, data);
              } else if (message.toolName == 'send_slack_notification') {
                return _buildSlackCard(context, data);
              } else if (message.toolName == 'calculate_compute_cost') {
                return _buildCostCard(context, data);
              }
            } catch (_) {}
          }
          return null;
        },
      ),
    );
  }

  /// Card rendering for mcp_list_tools discovery output
  Widget _buildListToolsCard(BuildContext context, String content) {
    final theme = Theme.of(context);
    final lines = content.split('\n');
    final toolLines = lines.where((l) => l.startsWith('• ')).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.travel_explore, color: Color(0xFF4F46E5), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Progressive Tool Discovery Result',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${toolLines.length} Discovered',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: toolLines.map((line) {
                final toolName = line.substring(2).split(':').first.trim();
                return Chip(
                  avatar: const Icon(Icons.build_circle_outlined, size: 16),
                  label: Text(toolName, style: const TextStyle(fontSize: 11)),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Card rendering for mcp_call_tool execution wrapper
  Widget _buildCallToolCard(BuildContext context, String content) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Dynamic Tool Call Dispatched',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Text(
                  'mcp_call_tool',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                content,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cloud Cluster Telemetry visual card
  Widget _buildClusterTelemetryCard(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_done, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  'Cluster Telemetry: ${data['cluster']}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${data['status']}',
                    style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricColumn('CPU Usage', '${data['cpu_utilization_percent']}%', Colors.orange),
                _metricColumn('Memory', '${data['memory_utilization_percent']}%', Colors.purple),
                _metricColumn('Active Pods', '${data['active_pods']}', Colors.blue),
                _metricColumn('Nodes', '${data['node_count']}', Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Slack notification visual card
  Widget _buildSlackCard(BuildContext context, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFFE01E5A), width: 4)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tag, size: 18, color: Color(0xFFE01E5A)),
                const SizedBox(width: 6),
                Text(
                  'Slack Dispatch: ${data['channel']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                const Icon(Icons.done_all, size: 16, color: Colors.green),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${data['preview']}',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  /// Compute cost calculation card
  Widget _buildCostCard(BuildContext context, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Cloud Compute Estimate (${data['provider']})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${data['instance_count']}x ${data['specs']}'),
                Text(
                  '\$${data['monthly_total_usd']} / mo',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Reserved 1-Yr Discounted: \$${data['discounted_annual_usd']}/yr (${data['recommended_reserved_saving_pct']}% savings)',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  void _showArchitectureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF4F46E5)),
            SizedBox(width: 8),
            Text('Progressive Tool Discovery'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The Problem with Standard MCP Registration:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'When connecting 5+ MCP servers or enterprise tools (20–100+ functions), '
                'injecting all full JSON schemas into every prompt consumes 5,000–15,000 tokens on each turn. '
                'This inflates latency, explodes LLM costs, and causes model confusion.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'The Progressive Discovery Solution:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '1. Initial Prompt Context: Only exposes two meta-tools:\n'
                '   • `mcp_list_tools` (~110 tokens)\n'
                '   • `mcp_call_tool` (~110 tokens)\n\n'
                '2. Two-Step Execution Flow:\n'
                '   Step 1: LLM calls `mcp_list_tools(query: "cluster")` to inspect schemas on-demand.\n'
                '   Step 2: LLM calls `mcp_call_tool(tool_name: "cloud_cluster_telemetry", arguments: {...})`.\n\n'
                '3. Result: Up to 95% reduction in prompt token consumption and instantaneous first-token response times.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
              SizedBox(height: 14),
              Text(
                'How to use in Flutter UI MCP:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              SelectableText(
                'McpPlayground(\n'
                '  progressiveMcpDiscovery: true,\n'
                '  customLocalTools: [\n'
                '    CloudClusterTelemetryTool(),\n'
                '    SendSlackNotificationTool(),\n'
                '    ...\n'
                '  ],\n'
                ')',
                style: TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

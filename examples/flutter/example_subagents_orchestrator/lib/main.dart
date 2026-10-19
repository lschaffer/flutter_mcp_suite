import 'package:flutter_ui_mcp/flutter_ui_mcp.dart';
import 'env_loader.dart';
import 'tools.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const SubAgentsOrchestratorApp());
}

class SubAgentsOrchestratorApp extends StatelessWidget {
  const SubAgentsOrchestratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autonomous Sub-Agent Orchestrator',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF818CF8),
          brightness: Brightness.dark,
        ),
      ),
      home: const SubAgentsScreen(),
    );
  }
}

class SubAgentsScreen extends StatefulWidget {
  const SubAgentsScreen({super.key});

  @override
  State<SubAgentsScreen> createState() => _SubAgentsScreenState();
}

class _SubAgentsScreenState extends State<SubAgentsScreen> {
  final List<McpLocalTool> _tools = getOrchestratorTools();

  static const String _orchestratorPrompt = '''
You are a Principal Systems Architect & Orchestrator.
When the user asks you to analyze complex system problems, you should NOT try to do everything in a single step.
Instead, use the `delegate_task` tool to spawn specialized child sub-agents for focused investigation:
- Delegate Security audits to a Security Analyst sub-agent (inspects code, CVEs).
- Delegate Performance profiling to a Performance Engineer sub-agent (queries telemetry, pool sizing).
- Then synthesize the returned findings from your child agents into a crisp, unified executive summary with concrete remediation steps.
''';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialLlm = EnvLoader.getInitialLlmConfig();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.account_tree_outlined, size: 22),
            SizedBox(width: 8),
            Text('Sub-Agent Orchestrator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Try asking: "Audit payment infrastructure: delegate security audit to Security Analyst, and telemetry investigation to Performance Engineer."',
                    style: TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: McpPlayground(
        initialLlmConfig: initialLlm,
        customLocalTools: _tools,
        initialSystemPrompt: _orchestratorPrompt,
        showAgentInspector: true,
        initialEnabledTools: [
          'delegate_task',
          'inspect_code_module',
          'check_dependency_vulnerabilities',
          'query_telemetry_metrics',
        ],
      ),
    );
  }
}

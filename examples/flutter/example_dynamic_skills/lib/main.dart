import 'package:flutter_ui_mcp/flutter_ui_mcp.dart';
import 'env_loader.dart';
import 'tools.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const DynamicSkillsExampleApp());
}

class DynamicSkillsExampleApp extends StatelessWidget {
  const DynamicSkillsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Runtime Skills Dock',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6), // Purple
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA78BFA),
          brightness: Brightness.dark,
        ),
      ),
      home: const DynamicSkillsScreen(),
    );
  }
}

class DynamicSkillsScreen extends StatefulWidget {
  const DynamicSkillsScreen({super.key});

  @override
  State<DynamicSkillsScreen> createState() => _DynamicSkillsScreenState();
}

class _DynamicSkillsScreenState extends State<DynamicSkillsScreen> {
  late final PlaygroundController _controller;

  static const String _systemPrompt = '''
You are an Adaptable Full-Stack Engineering Assistant.
You have access to a suite of dynamic skills that can be toggled on-demand:
- `sql_optimizer`: specialized in query plans, cost analysis, and index creation (`explain_sql_query`).
- `release_manager`: specialized in changelog drafting and semver management (`generate_release_notes`).
- `security_auditor`: specialized in HTTP header hardening and CORS vulnerability detection (`audit_security_headers`).

Workflow:
- You can dynamically activate/deactivate skills using `activate_skills` and `deactivate_skills` as needed.
- Alternatively, the user can toggle skills directly using the Dynamic Skill Dock above the chat input.
''';

  @override
  void initState() {
    super.initState();
    _controller = PlaygroundController(
      initialLlmConfig: EnvLoader.getInitialLlmConfig(),
      customLocalTools: [
        ExplainSqlQueryTool(),
        GenerateReleaseNotesTool(),
        AuditSecurityHeadersTool(),
      ],
    );
    _controller.systemPrompt = _systemPrompt;

    _registerSkills();
  }

  void _registerSkills() {
    _controller.registerDynamicSkill(
      const SkillDefinition(
        name: 'sql_optimizer',
        description: 'Deep SQL query execution plan analysis, index recommendations, and query refactoring.',
      ),
    );

    _controller.registerDynamicSkill(
      const SkillDefinition(
        name: 'release_manager',
        description: 'Semantic version tag validation, changelog compilation, and GitHub release drafting.',
      ),
    );

    _controller.registerDynamicSkill(
      const SkillDefinition(
        name: 'security_auditor',
        description: 'HTTP response headers security audit, CORS policies, CSP validation, and cookie security.',
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendPrompt(String prompt) {
    _controller.sendMessage(prompt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, size: 22),
            SizedBox(width: 8),
            Text('Dynamic Skills Dock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Scenarios:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _sendPrompt(
                      'Activate the sql_optimizer skill and optimize this query: '
                      'SELECT * FROM orders WHERE customer_id = 42 ORDER BY created_at DESC;',
                    ),
                    child: const Text('Optimize SQL Query', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () => _sendPrompt(
                      'Activate the security_auditor skill and audit https://api.mcp-store.internal for CORS and CSP.',
                    ),
                    child: const Text('Audit API Security', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () => _sendPrompt(
                      'Activate the release_manager skill and compile release notes for version 1.3.0.',
                    ),
                    child: const Text('Draft Release Notes', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: McpPlayground(
        controller: _controller,
        showAgentInspector: true,
        initialEnabledTools: const [
          'activate_skills',
          'deactivate_skills',
          'explain_sql_query',
          'generate_release_notes',
          'audit_security_headers',
        ],
      ),
    );
  }
}

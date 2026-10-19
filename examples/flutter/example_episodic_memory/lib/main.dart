import 'package:flutter_ui_mcp/flutter_ui_mcp.dart';
import 'env_loader.dart';
import 'tools.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const EpisodicMemoryExampleApp());
}

class EpisodicMemoryExampleApp extends StatelessWidget {
  const EpisodicMemoryExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Episodic Memory Archive & Retrieval',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488), // Teal
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2DD4BF),
          brightness: Brightness.dark,
        ),
      ),
      home: const EpisodicMemoryScreen(),
    );
  }
}

class EpisodicMemoryScreen extends StatefulWidget {
  const EpisodicMemoryScreen({super.key});

  @override
  State<EpisodicMemoryScreen> createState() => _EpisodicMemoryScreenState();
}

class _EpisodicMemoryScreenState extends State<EpisodicMemoryScreen> {
  late final PlaygroundController _controller;

  static const String _systemPrompt = '''
You are a Staff Software Architect with access to long-term organizational episodic memory.
When users ask questions regarding past architecture choices, team conventions, or prior technical decisions,
you MUST first use the `retrieve_memory` tool with relevant keywords (e.g. "auth", "database", "embedded", "redis").
Synthesize the retrieved historical memory with precision, citing the specific sprint and rationale.
If the user announces a new technical decision or milestone, use the `record_milestone` tool to permanently save it.
''';

  @override
  void initState() {
    super.initState();
    final milestoneTool = RecordMilestoneTool();
    _controller = PlaygroundController(
      initialLlmConfig: EnvLoader.getInitialLlmConfig(),
      customLocalTools: [milestoneTool],
    );
    milestoneTool.controller = _controller;
    _controller.systemPrompt = _systemPrompt;

    _preseedHistoricalMemories();
  }

  void _preseedHistoricalMemories() {
    // Seed 3 realistic project history entries
    _controller.addMemoryEntry(
      EpisodicMemoryEntry(
        archiveId: 'mem_sprint_12',
        startTurnIndex: 1,
        endTurnIndex: 8,
        timestamp: DateTime.now().subtract(const Duration(days: 90)),
        summary: 'Sprint 12 ADR: Migrated API authentication from stateless JWTs to Redis-backed session tokens. Rationale: requirement for instantaneous token revocation upon user permission changes or suspicious logout.',
        rawMessages: [
          ChatMessage.user('Should we keep JWT or move to sessions with Redis?'),
          ChatMessage.assistant('Migrated to Redis session tokens for instant revocation capability.'),
        ],
      ),
    );

    _controller.addMemoryEntry(
      EpisodicMemoryEntry(
        archiveId: 'mem_sprint_14',
        startTurnIndex: 9,
        endTurnIndex: 16,
        timestamp: DateTime.now().subtract(const Duration(days: 60)),
        summary: 'Sprint 14 Performance ADR: Capped PostgreSQL connection pool size to 25 with 60s idle timeout. Rationale: high concurrent workers were saturating AWS RDS Postgres CPU; reducing pool size improved p99 latency by 42%.',
        rawMessages: [
          ChatMessage.user('PostgreSQL CPU is spiking to 100% under load.'),
          ChatMessage.assistant('Capped connection pool to 25, eliminating connection thrashing and dropping p99.'),
        ],
      ),
    );

    _controller.addMemoryEntry(
      EpisodicMemoryEntry(
        archiveId: 'mem_sprint_18',
        startTurnIndex: 17,
        endTurnIndex: 24,
        timestamp: DateTime.now().subtract(const Duration(days: 25)),
        summary: 'Sprint 18 Mobile AI ADR: Adopted on-device quantized GGUF models via llamadart instead of cloud API for field workers. Rationale: zero data roaming cost and guaranteed offline diagnostics support in remote facilities.',
        rawMessages: [
          ChatMessage.user('Can technicians use AI diagnostics when offline in basements?'),
          ChatMessage.assistant('Yes, standardized on llamadart GGUF embedded models for offline inference.'),
        ],
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
            Icon(Icons.psychology, size: 22),
            SizedBox(width: 8),
            Text('Episodic Memory Archive', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  const Text('Ask Memory:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _sendPrompt(
                      'Why did we migrate away from stateless JWTs in Sprint 12? Please query our memory archive.',
                    ),
                    child: const Text('Why abandon JWT?', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () => _sendPrompt(
                      'What connection pool size was chosen for PostgreSQL in Sprint 14 and why?',
                    ),
                    child: const Text('Postgres pool size?', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () => _sendPrompt(
                      'What was our Sprint 18 decision regarding offline AI diagnostics on mobile?',
                    ),
                    child: const Text('Offline AI decision?', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 6),
                  FilledButton.tonal(
                    onPressed: () => _sendPrompt(
                      'We have finalized Sprint 22: We decided to use Protobuf over gRPC instead of REST JSON for all internal microservices to reduce bandwidth by 65%. Record this decision in our project records.',
                    ),
                    child: const Text('+ Record Sprint 22 ADR', style: TextStyle(fontSize: 11)),
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
          'retrieve_memory',
          'record_milestone',
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:mcp_playground_flutter/mcp_playground_flutter.dart';
import 'env_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const AudioNotesApp());
}

class AudioNotesApp extends StatelessWidget {
  const AudioNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meeting Notes & Action Items Assistant',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8F7AB8), // Fluent Pastel Lavender
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC4B2E3), // Fluent Frosted Lilac
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      home: const AudioNotesPlaygroundScreen(),
    );
  }
}

const String audioNotesSystemPrompt = '''
You are an executive meeting secretary and agile delivery coach. You have access to meeting transcript and notes tools:
- `load_meeting_transcript`: Retrieves full meeting dialog transcripts and discussion threads.
- `extract_action_items`: Structures decisions into actionable checklists with task name, owner, priority (high/med/low), and deadline.
- `export_meeting_notes`: Saves finalized meeting minutes and executive summaries.
Always extract clear action items with assignees and deadlines from conversations.
''';

class AudioNotesPlaygroundScreen extends StatelessWidget {
  const AudioNotesPlaygroundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<McpLocalTool> tools = [
      LoadMeetingTranscriptTool(),
      ExtractActionItemsTool(),
      ExportMeetingNotesTool(),
    ];

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
            Icon(Icons.record_voice_over, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Meeting Minutes & Action Items'),
          ],
        ),
      ),
      body: McpPlayground(
        initialLlmConfig: initialLlm.provider != LlmProvider.none ? initialLlm : null,
        initialEnabledTools: const [
          'load_meeting_transcript',
          'extract_action_items',
          'export_meeting_notes',
        ],
        initialSystemPrompt: audioNotesSystemPrompt,
        customLocalTools: tools,
        messageContentBuilder: (context, message) {
          if (message == null || message.type != MessageType.toolResponse) {
            return null;
          }
          final content = message.content.trim();
          if (!content.startsWith('{') || !content.endsWith('}')) return null;

          try {
            final data = jsonDecode(content) as Map<String, dynamic>;
            if (message.toolName == 'extract_action_items') {
              return _buildActionItemsCard(context, data);
            }
            if (message.toolName == 'export_meeting_notes') {
              return _buildMeetingNotesCard(context, data);
            }
          } catch (_) {}
          return null;
        },
      ),
    );
  }

  Widget _buildActionItemsCard(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final items = (data['action_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

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
                const Icon(Icons.playlist_add_check, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Extracted Action Items (${items.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_box_outline_blank, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['task']?.toString() ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _chip(item['owner']?.toString() ?? 'Unassigned', Colors.blue),
                              const SizedBox(width: 6),
                              _chip(item['priority']?.toString() ?? 'Normal', _priorityColor(item['priority']?.toString())),
                              if (item['due_date'] != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  'Due: ${item['due_date']}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingNotesCard(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final markdown = data['markdown']?.toString() ?? '';

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
                Icon(Icons.description_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Exported Meeting Minutes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
              child: SelectableText(
                markdown,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Color _priorityColor(String? p) {
    switch (p?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return Colors.green;
    }
  }
}

/// Tool to load transcript of a recorded meeting.
class LoadMeetingTranscriptTool extends McpLocalTool {
  @override
  String get name => 'load_meeting_transcript';

  @override
  String get description =>
      'Load or fetch meeting audio transcript by topic or file identifier.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'meeting_type': {
            'type': 'string',
            'description': 'Type of meeting: sprint_planning, architecture_review, or client_sync',
          },
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final type = arguments['meeting_type'] as String? ?? 'sprint_planning';
    final transcript = '''
[00:00] Alice (Product Lead): Welcome everyone. Today we must lock in Sprint 42 goals.
[01:15] Bob (Backend Eng): We completed the database migration. However, the Redis cache eviction still has a memory leak. I need to fix that by Thursday.
[03:40] Claire (Frontend Eng): On the Flutter app, I will finish upgrading the AI SDKs and integrate the new MCP tools by Friday morning.
[05:20] Alice: Excellent. David, please prepare the staging deployment and smoke tests by Friday 3 PM.
[06:30] David (DevOps): Will do. I also need Bob to review the Docker compose changes before Wednesday.
[07:10] Alice: Sounds like a solid plan. Let's execute!
''';

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({
            'meeting_type': type,
            'duration_minutes': 8,
            'transcript': transcript,
          }),
        ),
      ],
    );
  }
}

/// Tool to extract structured action items from transcript.
class ExtractActionItemsTool extends McpLocalTool {
  @override
  String get name => 'extract_action_items';

  @override
  String get description =>
      'Extract structured action items with owner, task, priority, and deadline.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'action_items': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'task': {'type': 'string'},
                'owner': {'type': 'string'},
                'priority': {'type': 'string'},
                'due_date': {'type': 'string'},
              },
            },
          },
        },
        'required': ['action_items'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final items = arguments['action_items'] as List? ?? [];
    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({'success': true, 'action_items': items}),
        ),
      ],
    );
  }
}

/// Tool to export meeting minutes.
class ExportMeetingNotesTool extends McpLocalTool {
  @override
  String get name => 'export_meeting_notes';

  @override
  String get description =>
      'Export formatted meeting minutes and action items to markdown.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'title': {'type': 'string'},
          'attendees': {'type': 'array', 'items': {'type': 'string'}},
          'decisions': {'type': 'array', 'items': {'type': 'string'}},
          'action_items': {'type': 'array', 'items': {'type': 'string'}},
        },
        'required': ['title'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final title = arguments['title'] as String? ?? 'Meeting Minutes';
    final attendees = (arguments['attendees'] as List?)?.cast<String>() ?? [];
    final decisions = (arguments['decisions'] as List?)?.cast<String>() ?? [];
    final items = (arguments['action_items'] as List?)?.cast<String>() ?? [];

    final buf = StringBuffer();
    buf.writeln('# $title\n');
    buf.writeln('**Date**: ${DateTime.now().toUtc().toIso8601String()}\n');

    if (attendees.isNotEmpty) {
      buf.writeln('## Attendees');
      for (final a in attendees) {
        buf.writeln('- $a');
      }
      buf.writeln('');
    }

    if (decisions.isNotEmpty) {
      buf.writeln('## Key Decisions');
      for (final d in decisions) {
        buf.writeln('- $d');
      }
      buf.writeln('');
    }

    if (items.isNotEmpty) {
      buf.writeln('## Action Items');
      for (final i in items) {
        buf.writeln('- [ ] $i');
      }
      buf.writeln('');
    }

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({'success': true, 'markdown': buf.toString()}),
        ),
      ],
    );
  }
}

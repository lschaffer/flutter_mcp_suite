import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mcp_playground_flutter/mcp_playground_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF),
          brightness: Brightness.dark,
        ),
      ),
      home: const AudioNotesPlaygroundScreen(),
    );
  }
}

class AudioNotesPlaygroundScreen extends StatelessWidget {
  const AudioNotesPlaygroundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<McpLocalTool> tools = [
      LoadMeetingTranscriptTool(),
      ExtractActionItemsTool(),
      ExportMeetingNotesTool(),
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
            Icon(Icons.record_voice_over, color: Color(0xFF9C27B0)),
            SizedBox(width: 8),
            Text('Meeting Minutes & Action Items'),
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
            if (message.toolName == 'extract_action_items') {
              return _buildActionItemsCard(context, data);
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
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
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
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

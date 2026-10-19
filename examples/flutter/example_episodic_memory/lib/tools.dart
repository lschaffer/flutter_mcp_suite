import 'dart:convert';
import 'package:dart_mcp_core/dart_mcp_core.dart';
import 'package:flutter_ui_mcp_core/flutter_ui_mcp_core.dart';

class RecordMilestoneTool extends McpLocalTool {
  PlaygroundController? controller;

  RecordMilestoneTool([this.controller]);

  @override
  String get name => 'record_milestone';

  @override
  String get description =>
      'Permanently records a major engineering decision or sprint milestone to project records.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'title': {
            'type': 'string',
            'description': 'Short headline of the milestone or decision.',
          },
          'rationale': {
            'type': 'string',
            'description': 'Why this decision was made and what alternatives were rejected.',
          },
          'tags': {
            'type': 'string',
            'description': 'Comma-separated tags (e.g. "auth, redis, sprint12").',
          },
        },
        'required': ['title', 'rationale'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final title = arguments['title']?.toString() ?? 'Untitled Decision';
    final rationale = arguments['rationale']?.toString() ?? '';
    final tags = arguments['tags']?.toString() ?? '';

    final tagList = tags
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final now = DateTime.now();
    final archiveId = 'mem_sprint_${now.millisecondsSinceEpoch}';

    final entry = EpisodicMemoryEntry(
      archiveId: archiveId,
      startTurnIndex: controller?.messages.length ?? 0,
      endTurnIndex: (controller?.messages.length ?? 0) + 1,
      timestamp: now,
      summary: '$title: $rationale${tagList.isNotEmpty ? " [${tagList.join(', ')}]" : ""}',
      rawMessages: [
        ChatMessage.user(rationale.isNotEmpty ? rationale : title),
        ChatMessage.assistant('Recorded milestone: $title. Tags: $tags'),
      ],
    );

    // Persist into Episodic Memory Archive and notify listeners to update counter badge
    controller?.addMemoryEntry(entry);

    return MCPToolResult.text(jsonEncode({
      'status': 'recorded',
      'archiveId': archiveId,
      'timestamp': now.toIso8601String(),
      'title': title,
      'rationale': rationale,
      'tags': tagList,
      'totalMemoriesArchived': controller?.memoryArchive.length ?? 1,
    }));
  }
}

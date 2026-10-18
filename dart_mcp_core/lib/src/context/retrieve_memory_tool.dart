import '../mcp/local_tools.dart';
import '../models/models.dart';
import 'context_compressor.dart';

/// MCP local tool that allows an agent to recall verbatim conversation turns
/// from an [EpisodicMemoryStore] stashed during context compression.
class RetrieveMemoryTool extends McpLocalTool {
  final EpisodicMemoryStore memoryStore;
  final void Function(String archiveId, int recalledTurnCount, String? query)?
      onMemoryRetrieved;

  RetrieveMemoryTool({
    required this.memoryStore,
    this.onMemoryRetrieved,
  });

  @override
  String get name => 'retrieve_memory';

  @override
  String get description =>
      'Recalls verbatim historical conversation turns from episodic memory archives. '
      'Useful when a prior conversation turn was compressed and you need exact code snippets, '
      'raw tool outputs, filenames, or specific parameters.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description':
                'Search keyword or question to locate relevant past turns.',
          },
          'archiveId': {
            'type': 'string',
            'description':
                'Optional specific archive ID (e.g. mem_a1b2c3d4) to retrieve directly.',
          },
          'limit': {
            'type': 'integer',
            'description':
                'Maximum number of archived memory blocks to return (defaults to 3).',
          },
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final query = arguments['query'] as String? ?? '';
    final archiveId = arguments['archiveId'] as String?;
    final limit = arguments['limit'] as int? ?? 3;

    final results = <EpisodicMemoryEntry>[];
    if (archiveId != null && archiveId.isNotEmpty) {
      final entry = memoryStore.getById(archiveId);
      if (entry != null) results.add(entry);
    } else {
      results.addAll(memoryStore.search(query).take(limit));
    }

    if (results.isEmpty) {
      return MCPToolResult.text(
        'No matching episodic memories found in archive.',
      );
    }

    final buffer = StringBuffer();
    int totalRecalledTurns = 0;
    for (final entry in results) {
      totalRecalledTurns += entry.rawMessages.length;
      buffer.writeln(
        '=== ARCHIVE [${entry.archiveId}] (${entry.timestamp.toLocal()}) ===',
      );
      buffer.writeln('Summary: ${entry.summary}');
      buffer.writeln('--- Verbatim Messages ---');
      for (final m in entry.rawMessages) {
        buffer.writeln('[${m.role.name.toUpperCase()}]: ${m.content}');
        if (m.toolName != null) {
          buffer.writeln(
            '[Tool Called: ${m.toolName}(${m.toolArguments ?? {}})]',
          );
        }
        if (m.toolResult != null) {
          buffer.writeln('[Tool Result]: ${m.toolResult!.text}');
        }
      }
      buffer.writeln();
    }

    onMemoryRetrieved?.call(
      results.first.archiveId,
      totalRecalledTurns,
      query.isEmpty ? null : query,
    );

    return MCPToolResult.text(buffer.toString().trim());
  }
}

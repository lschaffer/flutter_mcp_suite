import '../models/models.dart';
import 'local_tools.dart';
import 'mcp_client_def.dart';

/// Tool allowing LLMs to discover tools available across connected MCP servers
/// on-demand, without bloating the prompt context with dozens of tool schemas.
class McpListToolsTool extends McpLocalTool {
  final MultiMCPManager mcpManager;
  final List<McpLocalTool>? localTools;

  McpListToolsTool({required this.mcpManager, this.localTools});

  @override
  String get name => 'mcp_list_tools';

  @override
  String get description =>
      'List all available tools across connected MCP servers and local extensions with their descriptions and parameter summaries. '
      'Use this to discover specialized tools when needed without cluttering the initial context.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.read;

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'server_name': {
            'type': 'string',
            'description': 'Optional filter to list tools from a specific server only.',
          },
          'query': {
            'type': 'string',
            'description': 'Optional search keyword or capability query to filter tools.',
          },
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final serverFilter = (arguments['server_name'] as String?)?.toLowerCase().trim();
    final query = (arguments['query'] as String?)?.toLowerCase().trim();

    final allTools = <MCPTool>[];
    final seen = <String>{};

    // Add local tools (excluding meta discovery tools)
    final includeLocal =
        serverFilter == null || serverFilter.isEmpty || serverFilter == 'local';
    if (includeLocal && localTools != null) {
      for (final lt in localTools!) {
        if (lt.name == 'mcp_list_tools' || lt.name == 'mcp_call_tool') continue;
        if (seen.add(lt.name)) {
          allTools.add(lt.toMCPTool());
        }
      }
    }

    // Add connected MCP tools
    for (final clientDef in mcpManager.clients) {
      if (!clientDef.isConnected) continue;
      if (serverFilter != null &&
          serverFilter.isNotEmpty &&
          !clientDef.name.toLowerCase().contains(serverFilter)) {
        continue;
      }
      for (final tool in clientDef.availableTools) {
        if (seen.add(tool.name)) {
          allTools.add(tool);
        }
      }
    }

    if (allTools.isEmpty) {
      return MCPToolResult.text('No MCP tools are currently available.');
    }

    var matching = allTools;
    if (query != null && query.isNotEmpty) {
      matching = matching.where((t) {
        final inName = t.name.toLowerCase().contains(query);
        final inDesc = (t.description ?? '').toLowerCase().contains(query);
        return inName || inDesc;
      }).toList();
    }

    if (matching.isEmpty) {
      return MCPToolResult.text(
        'No tools matched query "$query". Total available tools: ${allTools.length} (call without query to view all).',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln('Available tools (${matching.length}):\n');

    for (final tool in matching) {
      buffer.writeln('• ${tool.name}: ${tool.description ?? 'No description'}');
      final props = tool.inputSchema?['properties'];
      if (props is Map && props.isNotEmpty) {
        final paramNames = props.keys.join(', ');
        buffer.writeln('  Parameters: $paramNames');
      }
    }

    return MCPToolResult.text(buffer.toString().trim());
  }
}

/// Tool allowing LLMs to dynamically invoke an MCP tool discovered via [McpListToolsTool].
class McpCallToolTool extends McpLocalTool {
  final MultiMCPManager mcpManager;
  final List<McpLocalTool>? localTools;

  McpCallToolTool({required this.mcpManager, this.localTools});

  @override
  String get name => 'mcp_call_tool';

  @override
  String get description =>
      'Invoke an MCP or local tool by name using the parameters discovered from mcp_list_tools.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.network;

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'tool_name': {
            'type': 'string',
            'description': 'The exact name of the tool to invoke.',
          },
          'arguments': {
            'type': 'object',
            'description': 'Key-value map of arguments to pass to the tool.',
          },
        },
        'required': ['tool_name', 'arguments'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final toolName = arguments['tool_name'] as String? ?? '';
    final toolArgs = arguments['arguments'] is Map
        ? Map<String, dynamic>.from(arguments['arguments'] as Map)
        : <String, dynamic>{};

    if (toolName.trim().isEmpty) {
      return MCPToolResult.error('tool_name parameter is required.');
    }

    // Check local tools first if provided
    if (localTools != null) {
      final localMatch = localTools!.where((t) => t.name == toolName).toList();
      if (localMatch.isNotEmpty) {
        try {
          return await localMatch.first.execute(toolArgs);
        } catch (e) {
          return MCPToolResult.error('Failed to execute local tool "$toolName": $e');
        }
      }
    }

    try {
      return await mcpManager.callTool(toolName, toolArgs);
    } catch (e) {
      return MCPToolResult.error('Failed to execute MCP tool "$toolName": $e');
    }
  }
}

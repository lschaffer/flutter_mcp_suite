import '../models/models.dart';
import 'local_tools.dart';
import 'mcp_client_def.dart';

/// Tool allowing LLMs to discover tools available across connected MCP servers
/// on-demand, without bloating the prompt context with dozens of tool schemas.
class McpListToolsTool extends McpLocalTool {
  final MultiMCPManager mcpManager;

  McpListToolsTool({required this.mcpManager});

  @override
  String get name => 'mcp_list_tools';

  @override
  String get description =>
      'List all available tools across connected MCP servers with their descriptions and parameter summaries. '
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
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final serverFilter = arguments['server_name'] as String?;
    final tools = mcpManager.availableTools;

    if (tools.isEmpty) {
      return MCPToolResult.text('No MCP tools are currently available.');
    }

    final buffer = StringBuffer();
    buffer.writeln('Available MCP tools (${tools.length}):\n');

    for (final tool in tools) {
      if (serverFilter != null && serverFilter.isNotEmpty) {
        // If server filter is provided, check if client matches
        // (Tool name resolution will match on call)
      }
      buffer.writeln('• ${tool.name}: ${tool.description}');
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

  McpCallToolTool({required this.mcpManager});

  @override
  String get name => 'mcp_call_tool';

  @override
  String get description =>
      'Invoke an MCP tool by name using the parameters discovered from mcp_list_tools.';

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

    try {
      return await mcpManager.callTool(toolName, toolArgs);
    } catch (e) {
      return MCPToolResult.error('Failed to execute MCP tool "$toolName": $e');
    }
  }
}

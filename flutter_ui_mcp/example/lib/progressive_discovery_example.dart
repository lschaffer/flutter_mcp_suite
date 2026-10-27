import 'package:flutter_ui_mcp/flutter_ui_mcp.dart';
import 'example_local_tools.dart';

/// Example screen demonstrating Progressive MCP Tool Discovery.
///
/// **Why Progressive Tool Discovery?**
/// In typical MCP setups, if you connect multiple servers (e.g. Git, Filesystem,
/// Weather, Database, Slack), registering 50+ tool schemas upfront can consume
/// 5,000 to 15,000 prompt tokens on EVERY turn.
///
/// With [McpListToolsTool] and [McpCallToolTool]:
/// 1. The LLM only receives two compact discovery tools:
///    - `mcp_list_tools`: Searches/lists connected tools on-demand.
///    - `mcp_call_tool`: Invokes any discovered tool by name with its arguments.
/// 2. Context overhead drops to ~250 tokens!
/// 3. The LLM discovers tools when needed and executes them seamlessly.
class ProgressiveDiscoveryExampleScreen extends StatelessWidget {
  const ProgressiveDiscoveryExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ── APPROACH 1: Using McpPlayground with progressiveMcpDiscovery: true ───
    // All connected MCP servers are automatically wrapped with McpListToolsTool
    // and McpCallToolTool instead of injecting every tool schema upfront.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progressive MCP Tool Discovery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Progressive Discovery',
            onPressed: () => _showExplanationDialog(context),
          ),
        ],
      ),
      body: McpPlayground(
        // Enable on-demand progressive discovery
        progressiveMcpDiscovery: true,

        // Custom local tools (weather tools) that will be discovered via mcp_list_tools
        customLocalTools: [
          GetCurrentWeatherTool(),
          GetHourlyForecastTool(),
          GetDailyForecastTool(),
          GeocodeWeatherCityTool(),
        ],

        initialSystemPrompt:
            'You are an agent with access to on-demand progressive tool discovery.\n'
            'Use the "mcp_list_tools" tool to discover what specialized tools are available, '
            'then call them via "mcp_call_tool".',

        initialEnabledTools: const [
          'get_current_weather',
          'get_weather_forecast',
          'geocode_weather_city',
        ],
      ),
    );
  }

  void _showExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.blue),
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
                'How it works:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '1. Instead of sending all 20+ or 100+ tool schemas in every LLM request, '
                'the model is only given two meta-tools:\n'
                '   • mcp_list_tools (McpListToolsTool)\n'
                '   • mcp_call_tool (McpCallToolTool)\n\n'
                '2. When the user asks "What is the weather in Tokyo?", the model calls:\n'
                '   mcp_list_tools() -> discovers get_current_weather\n'
                '   mcp_call_tool(tool_name: "get_current_weather", arguments: {"city": "Tokyo"})\n\n'
                '3. Context token savings: reduces tool prompt size from ~10,000 tokens down to ~250 tokens!',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'Manual instantiation example:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              SelectableText(
                'final mcpManager = MultiMCPManager();\n'
                'final listTool = McpListToolsTool(mcpManager: mcpManager);\n'
                'final callTool = McpCallToolTool(mcpManager: mcpManager);\n\n'
                '// Pass to McpPlayground or Agent:\n'
                'McpPlayground(customLocalTools: [listTool, callTool]);',
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

/// Standalone helper demonstrating manual programmatic usage with [MultiMCPManager]
/// and [Agent] or [McpAgentEngine].
void programmaticProgressiveDiscoveryExample() {
  final mcpManager = MultiMCPManager();

  // 1. Manually instantiate McpListToolsTool and McpCallToolTool
  final listToolsTool = McpListToolsTool(mcpManager: mcpManager);
  final callToolTool = McpCallToolTool(mcpManager: mcpManager);

  // 2. You can query tool metadata directly
  debugPrint('List tool name: ${listToolsTool.name}'); // mcp_list_tools
  debugPrint('Call tool name: ${callToolTool.name}');   // mcp_call_tool

  // 3. Or enable progressive discovery directly on an Agent:
  // final agent = Agent(
  //   key: 'progressive_agent',
  //   name: 'Smart Discovery Agent',
  //   progressiveMcpDiscovery: true, // Automatically registers both tools
  // );
}

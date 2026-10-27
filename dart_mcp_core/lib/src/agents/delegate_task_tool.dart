import '../mcp/local_tools.dart';
import '../models/models.dart';

/// Callback signature for executing a delegated sub-task.
typedef SubAgentRunner = Future<String> Function({
  required String assignee,
  required String task,
  List<String>? enabledTools,
  String? model,
});

/// Local MCP tool allowing an agent to delegate an isolated sub-task to another
/// registered sub-agent or to an isolated clone of the current agent.
class DelegateTaskTool extends McpLocalTool {
  final SubAgentRunner runner;
  final List<String> availableAssignees;

  DelegateTaskTool({
    required this.runner,
    this.availableAssignees = const ['clone'],
  });

  @override
  String get name => 'delegate_task';

  @override
  String get description =>
      'Delegates an isolated sub-task to a specialized sub-agent or to an isolated clone '
      'of the current agent. The sub-agent executes with fresh context, performs tools, '
      'and returns its final synthesized response back to you.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'assignee': {
            'type': 'string',
            'description':
                'Target sub-agent key (e.g. "clone", or one of: ${availableAssignees.join(", ")}).',
          },
          'task': {
            'type': 'string',
            'description':
                'Clear, detailed instructions and objective for the sub-agent to perform.',
          },
          'model': {
            'type': 'string',
            'description':
                'Optional model override for the delegated task (e.g. "qwen2.5-coder", "fast", "local").',
          },
          'enabledTools': {
            'type': 'array',
            'items': {'type': 'string'},
            'description':
                'Optional subset of tool names the sub-agent is permitted to use.',
          },
        },
        'required': ['assignee', 'task'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final assignee = arguments['assignee'] as String? ?? 'clone';
    final task = arguments['task'] as String? ?? '';
    final model = (arguments['model'] as String? ??
            arguments['modelOverride'] as String?)
        ?.trim();
    final enabledTools = (arguments['enabledTools'] as List?)?.cast<String>();

    if (task.trim().isEmpty) {
      return MCPToolResult.error('Task description cannot be empty.');
    }

    try {
      final result = await runner(
        assignee: assignee,
        task: task,
        enabledTools: enabledTools,
        model: (model != null && model.isNotEmpty) ? model : null,
      );
      return MCPToolResult.text(result);
    } catch (e) {
      return MCPToolResult.error('Failed to execute delegated sub-task: $e');
    }
  }
}

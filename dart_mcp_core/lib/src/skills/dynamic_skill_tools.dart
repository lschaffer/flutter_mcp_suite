import '../mcp/local_tools.dart';
import '../models/models.dart';

/// Local tool enabling agents to dynamically activate skills at runtime.
class ActivateSkillsTool extends McpLocalTool {
  final Future<String> Function(List<String> skillNames) onActivate;
  final List<String> availableSkills;

  ActivateSkillsTool({
    required this.onActivate,
    required this.availableSkills,
  });

  @override
  String get name => 'activate_skills';

  @override
  String get description =>
      'Activates one or more dynamic skills into the current agent session. '
      'Injects the skill instructions and makes all its tools available for subsequent turns.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'skills': {
            'type': 'array',
            'items': {'type': 'string'},
            'description':
                'List of skill names to activate (Available: ${availableSkills.join(", ")}).',
          },
        },
        'required': ['skills'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final skills = (arguments['skills'] as List?)?.cast<String>() ?? [];
    if (skills.isEmpty) {
      return MCPToolResult.error('No skill names provided to activate.');
    }
    try {
      final message = await onActivate(skills);
      return MCPToolResult.text(message);
    } catch (e) {
      return MCPToolResult.error('Failed to activate skills: $e');
    }
  }
}

/// Local tool enabling agents to dynamically deactivate skills to reduce context bloat.
class DeactivateSkillsTool extends McpLocalTool {
  final Future<String> Function(List<String> skillNames) onDeactivate;

  DeactivateSkillsTool({required this.onDeactivate});

  @override
  String get name => 'deactivate_skills';

  @override
  String get description =>
      'Deactivates currently active dynamic skills to free up LLM context window tokens '
      'when their capabilities are no longer needed.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'skills': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'List of skill names to deactivate.',
          },
        },
        'required': ['skills'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final skills = (arguments['skills'] as List?)?.cast<String>() ?? [];
    if (skills.isEmpty) {
      return MCPToolResult.error('No skill names provided to deactivate.');
    }
    try {
      final message = await onDeactivate(skills);
      return MCPToolResult.text(message);
    } catch (e) {
      return MCPToolResult.error('Failed to deactivate skills: $e');
    }
  }
}

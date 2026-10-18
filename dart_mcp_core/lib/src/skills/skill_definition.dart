import '../mcp/local_tools.dart';

/// Represents a modular capability package consisting of a system prompt segment
/// and custom Dart-native tools.
class SkillDefinition {
  final String name;
  final String description;
  final String? systemPrompt;
  final List<McpLocalTool> tools;
  final bool isAlwaysOn;

  const SkillDefinition({
    required this.name,
    required this.description,
    this.systemPrompt,
    this.tools = const [],
    this.isAlwaysOn = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        if (systemPrompt != null) 'systemPrompt': systemPrompt,
        'isAlwaysOn': isAlwaysOn,
        'tools': tools.map((t) => t.name).toList(),
      };
}

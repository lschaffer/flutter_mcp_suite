import 'package:dart_mcp_core/dart_mcp_core.dart';

/// Persistent AgentSkills.io skill definition stored in JSON/SharedPreferences.
class SkillDef {
  final String id;
  final String name;
  final String goal;
  final String description;
  final String skillDef; // full agentskills.io markdown content (YAML frontmatter + body)
  final List<String> toolNames;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SkillDef({
    required this.id,
    required this.name,
    this.goal = '',
    this.description = '',
    required this.skillDef,
    this.toolNames = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Validates that the skill content is in valid agentskills.io format.
  /// Returns null if valid, or an error message string if invalid.
  static String? validateAgentskillsFormat(String content) {
    if (content.trim().isEmpty) {
      return 'Skill content cannot be empty.';
    }
    final lines = content.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') {
      return 'Skill must start with YAML front matter (---).';
    }
    // Find closing ---
    int closingDash = -1;
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        closingDash = i;
        break;
      }
    }
    if (closingDash == -1) {
      return 'Skill YAML front matter must have a closing --- line.';
    }
    // Extract YAML lines
    final yamlLines = lines.sublist(1, closingDash);
    final yamlString = yamlLines.join('\n');
    // Basic check: must contain a 'name' field
    if (!yamlString.contains('name:')) {
      return 'Skill YAML front matter must contain a "name" field.';
    }
    return null; // valid
  }

  /// Extracts description from YAML frontmatter or content if not explicitly set.
  String get effectiveDescription {
    if (description.isNotEmpty) return description;
    final lines = skillDef.split('\n');
    for (final l in lines) {
      final trimmed = l.trim();
      if (trimmed.startsWith('description:')) {
        return trimmed.replaceFirst('description:', '').trim().replaceAll('"', '').replaceAll("'", '');
      }
    }
    return '';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'goal': goal,
    'description': description,
    'skill_def': skillDef,
    'tool_names': toolNames,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory SkillDef.fromJson(Map<String, dynamic> json) => SkillDef(
    id: json['id'] as String,
    name: json['name'] as String,
    goal: json['goal'] as String? ?? '',
    description: json['description'] as String? ?? '',
    skillDef: json['skill_def'] as String? ?? json['skillDef'] as String? ?? '',
    toolNames:
        (json['tool_names'] as List<dynamic>? ?? json['toolNames'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String).toLocal()
        : DateTime.now(),
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String).toLocal()
        : DateTime.now(),
  );

  SkillDef copyWith({
    String? name,
    String? goal,
    String? description,
    String? skillDef,
    List<String>? toolNames,
  }) {
    return SkillDef(
      id: id,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      description: description ?? this.description,
      skillDef: skillDef ?? this.skillDef,
      toolNames: toolNames ?? this.toolNames,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Extension to convert an in-memory [SkillDefinition] into an AgentSkills.io [SkillDef].
extension SkillDefinitionToSkillDef on SkillDefinition {
  /// Converts this [SkillDefinition] into an AgentSkills.io compliant [SkillDef].
  SkillDef toSkillDef() {
    final body = (systemPrompt != null && systemPrompt!.trim().isNotEmpty)
        ? systemPrompt!
        : description;
    final toolsYaml = tools.isNotEmpty
        ? '\ntools:\n${tools.map((t) => '  - ${t.name}').join('\n')}'
        : '';
    final fullMarkdown = '''---
name: $name
description: $description$toolsYaml
---

# $name

$body
''';

    return SkillDef(
      id: 'dynamic_$name',
      name: name,
      goal: description,
      description: description,
      skillDef: fullMarkdown,
      toolNames: tools.map((t) => t.name).toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

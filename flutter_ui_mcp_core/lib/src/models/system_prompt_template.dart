import 'package:material_ui/material_ui.dart';

/// Predefined or custom prompt template for the System Prompt / Persona editor.
class SystemPromptTemplate {
  /// Chip label (e.g. 'Coding Expert', 'Support Agent').
  final String label;

  /// The system prompt text injected into the controller when selected.
  final String prompt;

  /// Optional chip icon.
  final IconData? icon;

  const SystemPromptTemplate({
    required this.label,
    required this.prompt,
    this.icon,
  });
}

/// Built-in default quick persona templates.
const List<SystemPromptTemplate> kDefaultSystemPromptTemplates = [
  SystemPromptTemplate(
    label: 'Coding Expert',
    icon: Icons.code,
    prompt:
        'You are an expert senior software engineer. Write clean, idiomatic, well-tested code. Use available tools to inspect files and execute commands precisely.',
  ),
  SystemPromptTemplate(
    label: 'Vision Analyst',
    icon: Icons.remove_red_eye_outlined,
    prompt:
        'You are a meticulous visual inspection assistant. Analyze screenshots, diagrams, and images thoroughly, highlighting details, bugs, and visual hierarchy.',
  ),
  SystemPromptTemplate(
    label: 'Data & Tools Agent',
    icon: Icons.storage_outlined,
    prompt:
        'You are an autonomous data agent equipped with database, API, and tool access. Inspect schemas, query databases, and summarize findings clearly.',
  ),
];

import 'package:dart_mcp_core/dart_mcp_core.dart';

/// Represents a saved Playground Workflow preset containing multi-prompts,
/// system prompt, LLM overrides, selected tools, and active skill reference.
class PlaygroundWorkflow {
  final String id;
  final String name;
  final String description;
  final List<SubPromptStep> steps;
  final String systemPrompt;
  final String initialPrompt;
  final bool useCustomLlm;
  final LlmConfig? customLlmConfig;
  final List<String> enabledToolNames;
  final String? activeSkillId;
  final String? activeSkillName;
  final bool chatMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlaygroundWorkflow({
    required this.id,
    required this.name,
    this.description = '',
    this.steps = const [],
    this.systemPrompt = '',
    this.initialPrompt = '',
    this.useCustomLlm = false,
    this.customLlmConfig,
    this.enabledToolNames = const [],
    this.activeSkillId,
    this.activeSkillName,
    this.chatMode = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'steps': steps.map((s) => s.toJson()).toList(),
    'system_prompt': systemPrompt,
    'initial_prompt': initialPrompt,
    'use_custom_llm': useCustomLlm,
    'custom_llm_config': customLlmConfig?.toJson(),
    'enabled_tool_names': enabledToolNames,
    'active_skill_id': activeSkillId,
    'active_skill_name': activeSkillName,
    'chat_mode': chatMode,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory PlaygroundWorkflow.fromJson(Map<String, dynamic> json) => PlaygroundWorkflow(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    steps: (json['steps'] as List<dynamic>?)
            ?.map((s) => SubPromptStep.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [],
    systemPrompt: json['system_prompt'] as String? ?? json['systemPrompt'] as String? ?? '',
    initialPrompt: json['initial_prompt'] as String? ?? json['initialPrompt'] as String? ?? '',
    useCustomLlm: json['use_custom_llm'] as bool? ?? json['useCustomLlm'] as bool? ?? false,
    customLlmConfig: json['custom_llm_config'] != null
        ? LlmConfig.fromJson(json['custom_llm_config'] as Map<String, dynamic>)
        : (json['customLlmConfig'] != null
            ? LlmConfig.fromJson(json['customLlmConfig'] as Map<String, dynamic>)
            : null),
    enabledToolNames: (json['enabled_tool_names'] as List<dynamic>? ??
            json['enabledToolNames'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    activeSkillId: json['active_skill_id'] as String? ?? json['activeSkillId'] as String?,
    activeSkillName: json['active_skill_name'] as String? ?? json['activeSkillName'] as String?,
    chatMode: json['chat_mode'] as bool? ?? json['chatMode'] as bool? ?? false,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String).toLocal()
        : DateTime.now(),
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String).toLocal()
        : DateTime.now(),
  );

  PlaygroundWorkflow copyWith({
    String? name,
    String? description,
    List<SubPromptStep>? steps,
    String? systemPrompt,
    String? initialPrompt,
    bool? useCustomLlm,
    LlmConfig? customLlmConfig,
    List<String>? enabledToolNames,
    String? activeSkillId,
    String? activeSkillName,
    bool? chatMode,
  }) {
    return PlaygroundWorkflow(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      initialPrompt: initialPrompt ?? this.initialPrompt,
      useCustomLlm: useCustomLlm ?? this.useCustomLlm,
      customLlmConfig: customLlmConfig ?? this.customLlmConfig,
      enabledToolNames: enabledToolNames ?? this.enabledToolNames,
      activeSkillId: activeSkillId ?? this.activeSkillId,
      activeSkillName: activeSkillName ?? this.activeSkillName,
      chatMode: chatMode ?? this.chatMode,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

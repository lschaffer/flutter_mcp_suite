import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Signature of a widget builder referenced by name from an A2UI catalog
/// definition.
typedef A2uiWidgetBuilder = ComponentWidgetBuilder;

/// A parsed A2UI catalog item definition supplied by the host application.
class A2uiCatalogItemDefinition {
  /// Creates an [A2uiCatalogItemDefinition].
  const A2uiCatalogItemDefinition({
    required this.type,
    this.builder,
    required this.schema,
    this.description,
    this.examples = const [],
  });

  /// The component type name used in A2UI JSON payloads, e.g. `WeatherChart`.
  final String type;

  /// Optional key of a known widget builder registered in
  /// [A2uiCatalogRegistry]. When `null` or unknown, a generic JSON renderer is
  /// used as a fallback.
  final String? builder;

  /// The JSON schema describing the component data.
  final Schema schema;

  /// Optional human readable description of the component.
  final String? description;

  /// Optional example JSON payloads.
  final List<String> examples;

  /// Parses an [A2uiCatalogItemDefinition] from JSON.
  factory A2uiCatalogItemDefinition.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? json['name'] as String?;
    if (type == null || type.isEmpty) {
      throw ArgumentError('Catalog item definition requires a "type".');
    }

    final schemaJson = json['schema'] as Map<String, dynamic>?;
    final schema = schemaJson != null
        ? Schema.fromMap(Map<String, Object?>.from(schemaJson))
        : S.object(properties: const {});

    final examples =
        (json['examples'] as List?)?.whereType<String>().toList() ??
        const <String>[];

    return A2uiCatalogItemDefinition(
      type: type,
      builder: json['builder'] as String?,
      schema: schema,
      description: json['description'] as String?,
      examples: examples,
    );
  }
}

/// A registry of named widget builders for A2UI catalog items.
class A2uiCatalogRegistry {
  A2uiCatalogRegistry._();

  static final Map<String, A2uiWidgetBuilder> _builders = {
    'chat_message': _chatMessageBuilder,
  };

  /// Registers a builder under [key] so it can be referenced from JSON catalog
  /// definitions.
  static void register(String key, A2uiWidgetBuilder builder) {
    _builders[key] = builder;
  }

  /// Looks up a previously registered builder.
  static A2uiWidgetBuilder? lookup(String key) => _builders[key];

  /// All currently registered builder keys.
  static Iterable<String> get keys => _builders.keys;
}

/// The default A2UI catalog component: a chat bubble.
final ComponentImplementation a2uiChatMessageComponent = ComponentImplementation(
  name: 'ChatMessage',
  schema: S.object(
    description: 'A chat message bubble.',
    properties: {
      'role': S.string(
        description: 'The author of the message.',
        enumValues: ['user', 'assistant', 'system'],
      ),
      'text': S.string(description: 'The message content.'),
    },
    required: ['text'],
  ),
  builder: _chatMessageBuilder,
);

/// Builds an A2UI [CatalogImplementation] from an optional JSON list of catalog item
/// definitions and custom components.
CatalogImplementation buildA2uiCatalog({
  String? catalogJson,
  List<A2uiCatalogItemDefinition>? catalogItems,
  List<ComponentImplementation>? customComponents,
  List<FunctionImplementation>? customFunctions,
}) {
  final base = basicCatalog();

  final Map<String, ComponentImplementation> components = {
    for (final c in base.components.values) c.name: c,
    a2uiChatMessageComponent.name: a2uiChatMessageComponent,
  };

  if (customComponents != null) {
    for (final c in customComponents) {
      components[c.name] = c;
    }
  }

  if (catalogJson != null && catalogJson.trim().isNotEmpty) {
    final decoded = jsonDecode(catalogJson);
    final items = decoded is List ? decoded : const [];
    for (final entry in items) {
      if (entry is Map<String, dynamic>) {
        final def = A2uiCatalogItemDefinition.fromJson(entry);
        final comp = _componentFromDefinition(def);
        components[comp.name] = comp;
      }
    }
  }

  if (catalogItems != null) {
    for (final definition in catalogItems) {
      final comp = _componentFromDefinition(definition);
      components[comp.name] = comp;
    }
  }

  final Map<String, FunctionImplementation> functions = {
    for (final f in base.functions.values) f.name: f,
  };

  if (customFunctions != null) {
    for (final f in customFunctions) {
      functions[f.name] = f;
    }
  }

  return CatalogImplementation(
    id: base.id,
    components: components.values.toList(),
    functions: functions.values.toList(),
    schemaId: base.schemaId,
    title: base.title,
    description: base.description,
    protocolVersion: base.protocolVersion,
    instructions: base.instructions,
    definitions: base.definitions,
  );
}

ComponentImplementation _componentFromDefinition(
  A2uiCatalogItemDefinition definition,
) {
  final A2uiWidgetBuilder builder =
      (definition.builder != null
          ? A2uiCatalogRegistry.lookup(definition.builder!)
          : null) ??
      _genericBuilder(definition.type);

  return ComponentImplementation(
    name: definition.type,
    schema: definition.schema,
    builder: builder,
  );
}

Widget _chatMessageBuilder(
  BuildContext context,
  ComponentNode<ComponentImplementation> node,
  ComponentProps props,
  ChildWidgetBuilder buildChild,
) {
  final text = props.string('text') ?? '';
  final role = props.string('role') ?? 'assistant';
  final isUser = role == 'user';
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    child: Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          CircleAvatar(
            radius: 14,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.smart_toy_outlined,
              size: 16,
              color: isDark
                  ? Colors.white
                  : theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isUser
                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(text),
          ),
        ),
      ],
    ),
  );
}

A2uiWidgetBuilder _genericBuilder(String type) {
  return (
    BuildContext context,
    ComponentNode<ComponentImplementation> node,
    ComponentProps props,
    ChildWidgetBuilder buildChild,
  ) {
    final theme = Theme.of(context);
    final data = props.value('data') ?? props.value('content') ?? node.instanceId;
    final body = const JsonEncoder.withIndent('  ').convert(data);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.widgets_outlined, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                type,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            body,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ],
      ),
    );
  };
}

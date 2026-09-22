import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Signature of a widget builder referenced by name from a JSON catalog
/// definition. The builder receives the [CatalogItemContext] for the component
/// instance and returns the Flutter widget to render it.
typedef GenuiWidgetBuilder = CatalogWidgetBuilder;

/// A parsed GenUI catalog item definition supplied by the host application.
///
/// This is the Dart representation of a single entry in the JSON list that can
/// be passed to [McpGenuiChatController] (or [buildGenuiCatalog]) as the
/// optional `catalogItems` parameter. It carries the component `type`, an
/// optional known `builder` key, the JSON schema describing the component data,
/// and optional example payloads.
class GenuiCatalogItemDefinition {
  /// Creates a [GenuiCatalogItemDefinition].
  const GenuiCatalogItemDefinition({
    required this.type,
    this.builder,
    required this.schema,
    this.description,
    this.examples = const [],
  });

  /// The component type name used in A2UI JSON payloads, e.g. `WeatherChart`.
  final String type;

  /// Optional key of a known widget builder registered in
  /// [GenuiCatalogRegistry]. When `null` or unknown, a generic JSON renderer is
  /// used as a fallback.
  final String? builder;

  /// The JSON schema describing the component data.
  final Schema schema;

  /// Optional human readable description of the component.
  final String? description;

  /// Optional example JSON payloads (each a valid JSON list of components).
  final List<String> examples;

  /// Parses a [GenuiCatalogItemDefinition] from JSON.
  factory GenuiCatalogItemDefinition.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? json['name'] as String?;
    if (type == null || type.isEmpty) {
      throw ArgumentError('Catalog item definition requires a "type".');
    }

    final schemaJson = json['schema'] as Map<String, dynamic>?;
    final schema = schemaJson != null
        ? Schema.fromMap(_toObjectMap(schemaJson))
        : S.object(properties: const {});

    final examples =
        (json['examples'] as List?)?.whereType<String>().toList() ??
        const <String>[];

    return GenuiCatalogItemDefinition(
      type: type,
      builder: json['builder'] as String?,
      schema: schema,
      description: json['description'] as String?,
      examples: examples,
    );
  }

  static Map<String, Object?> _toObjectMap(Map<String, dynamic> input) =>
      Map<String, Object?>.from(input);
}

/// A registry of named widget builders for GenUI catalog items.
///
/// JSON catalog item definitions can reference a builder by name through the
/// `builder` field. Host applications register their builders once, then define
/// the corresponding widgets purely via JSON.
class GenuiCatalogRegistry {
  GenuiCatalogRegistry._();

  static final Map<String, GenuiWidgetBuilder> _builders = {
    'chat_message': _chatMessageBuilder,
  };

  /// Registers a builder under [key] so it can be referenced from JSON catalog
  /// definitions.
  static void register(String key, GenuiWidgetBuilder builder) {
    _builders[key] = builder;
  }

  /// Looks up a previously registered builder.
  static GenuiWidgetBuilder? lookup(String key) => _builders[key];

  /// All currently registered builder keys.
  static Iterable<String> get keys => _builders.keys;
}

/// The default GenUI catalog item: a chat bubble.
///
/// This is used when no custom catalog items are provided, preserving the
/// chat-bubble interaction model of the playground.
final CatalogItem genuiChatMessageItem = CatalogItem(
  name: 'ChatMessage',
  dataSchema: S.object(
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
  widgetBuilder: _chatMessageBuilder,
  exampleData: [
    () => '''
    [
      {
        "id": "root",
        "component": "ChatMessage",
        "role": "assistant",
        "text": "Hello! Ask me anything."
      }
    ]
    ''',
  ],
);

/// Builds a GenUI [Catalog] from an optional JSON list of catalog item
/// definitions.
///
/// The resulting catalog always includes the GenUI basic catalog items (Text,
/// Column, Row, Button, TextField, ChoicePicker, ...) plus the default
/// [genuiChatMessageItem]. When [catalogJson] or [catalogItems] is provided,
/// the corresponding items are merged in (replacing any item with the same
/// name). When [clientFunctions] is provided, they are registered into the catalog.
Catalog buildGenuiCatalog({
  String? catalogJson,
  List<GenuiCatalogItemDefinition>? catalogItems,
  List<ClientFunction>? clientFunctions,
}) {
  final base = BasicCatalogItems.asNoAssetCatalog();

  final custom = <CatalogItem>[genuiChatMessageItem];

  if (catalogJson != null && catalogJson.trim().isNotEmpty) {
    final decoded = jsonDecode(catalogJson);
    final items = decoded is List ? decoded : const [];
    for (final entry in items) {
      if (entry is Map<String, dynamic>) {
        custom.add(
          _catalogItemFromDefinition(
            GenuiCatalogItemDefinition.fromJson(entry),
          ),
        );
      }
    }
  }

  if (catalogItems != null) {
    for (final definition in catalogItems) {
      custom.add(_catalogItemFromDefinition(definition));
    }
  }

  return base.copyWith(
    newItems: custom,
    newFunctions: clientFunctions,
  );
}

CatalogItem _catalogItemFromDefinition(GenuiCatalogItemDefinition definition) {
  final GenuiWidgetBuilder builder =
      (definition.builder != null
          ? GenuiCatalogRegistry.lookup(definition.builder!)
          : null) ??
      _genericBuilder(definition.type);

  return CatalogItem(
    name: definition.type,
    dataSchema: definition.schema,
    widgetBuilder: builder,
    exampleData: definition.examples
        .map(
          (e) =>
              () => e,
        )
        .toList(),
  );
}

Widget _chatMessageBuilder(CatalogItemContext context) {
  final data = Map<String, Object?>.from(context.data as Map);
  final text = data['text']?.toString() ?? '';
  final role = data['role']?.toString() ?? 'assistant';
  final isUser = role == 'user';
  final theme = Theme.of(context.buildContext);
  final isDark = theme.brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    child: Row(
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
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

GenuiWidgetBuilder _genericBuilder(String type) {
  return (CatalogItemContext context) {
    final data = Map<String, Object?>.from(context.data as Map);
    final theme = Theme.of(context.buildContext);
    final body = const JsonEncoder.withIndent('  ').convert(data);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              body,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  };
}

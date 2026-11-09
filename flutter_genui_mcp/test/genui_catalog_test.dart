import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui_mcp/flutter_genui_mcp.dart'
    show
        GenuiCatalogItemDefinition,
        GenuiCatalogRegistry,
        buildGenuiCatalog,
        genuiChatMessageItem;
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema_builder/json_schema_builder.dart'
    hide ValidationResult;

/// Renders [components] as a surface of [catalog], checked strictly, and
/// returns the errors the renderer reports.
Future<List<A2uiRendererError>> _pumpSurface(
  WidgetTester tester,
  CatalogImplementation catalog,
  List<Map<String, Object?>> components,
) async {
  final processor = MessageProcessor<ComponentImplementation>(
    catalogs: [catalog],
    validationConfig: ValidationConfig.strict,
  );
  addTearDown(processor.dispose);
  final errors = <A2uiRendererError>[];
  processor.model.onError.subscribe(errors.add);
  processor.processMessages([
    {
      'version': 'v0.9',
      'createSurface': {'surfaceId': 'main', 'catalogId': catalog.id},
    },
    {
      'version': 'v0.9',
      'updateComponents': {'surfaceId': 'main', 'components': components},
    },
  ]);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: A2uiSurface(surface: processor.model.getSurface('main')!),
        ),
      ),
    ),
  );
  return errors;
}

class _AddFunction extends FunctionImplementation {
  _AddFunction()
    : super(
        name: 'add',
        returnType: A2uiReturnType.number,
        argumentSchema: Schema.object(
          properties: {'a': Schema.number(), 'b': Schema.number()},
          required: ['a', 'b'],
        ),
      );

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) => (args['a'] as num) + (args['b'] as num);
}

void main() {
  test('buildGenuiCatalog builds on the basic catalog without media', () {
    final catalog = buildGenuiCatalog();

    expect(catalog.id, BasicCatalog.v0_9Id);
    expect(catalog.components.keys, containsAll(['ChatMessage', 'Text']));
    expect(
      catalog.components.keys,
      isNot(
        anyOf(contains('Image'), contains('Video'), contains('AudioPlayer')),
      ),
    );
    expect(catalog.functions.keys, containsAll(['formatString', 'openUrl']));
  });

  test('buildGenuiCatalog registers client functions', () {
    final catalog = buildGenuiCatalog(clientFunctions: [_AddFunction()]);

    expect(catalog.functions.keys, containsAll(['add', 'formatString']));
  });

  testWidgets('ChatMessage renders its text', (tester) async {
    final errors = await _pumpSurface(tester, buildGenuiCatalog(), [
      {
        'id': 'root',
        'component': 'ChatMessage',
        'role': 'assistant',
        'text': 'Hello! Ask me anything.',
        // A property the schema does not list, which genui accepted too.
        'timestamp': '10:00',
      },
    ]);

    expect(errors, isEmpty);
    expect(find.text('Hello! Ask me anything.'), findsOneWidget);
    expect(genuiChatMessageItem.name, 'ChatMessage');
  });

  testWidgets('a JSON catalog item without a builder renders its data', (
    tester,
  ) async {
    final catalog = buildGenuiCatalog(
      catalogJson: '''
      [
        {
          "type": "WeatherCard",
          "schema": {
            "type": "object",
            "properties": {"city": {"type": "string"}}
          }
        }
      ]
      ''',
    );
    final errors = await _pumpSurface(tester, catalog, [
      {
        'id': 'root',
        'component': 'WeatherCard',
        'city': 'Paris',
        'temperature': 21,
      },
    ]);

    expect(errors, isEmpty);
    expect(find.text('WeatherCard'), findsOneWidget);
    expect(find.textContaining('"city": "Paris"'), findsOneWidget);
    expect(find.textContaining('"temperature": 21'), findsOneWidget);
  });

  testWidgets('a JSON catalog item uses the builder registered for it', (
    tester,
  ) async {
    GenuiCatalogRegistry.register(
      'city_label',
      (context, node, props, buildChild) =>
          Text('City: ${props.string('city')}'),
    );
    final catalog = buildGenuiCatalog(
      catalogItems: [
        GenuiCatalogItemDefinition(
          type: 'CityLabel',
          builder: 'city_label',
          schema: Schema.object(properties: {'city': Schema.string()}),
        ),
      ],
    );
    final errors = await _pumpSurface(tester, catalog, [
      {'id': 'root', 'component': 'CityLabel', 'city': 'Oslo'},
    ]);

    expect(errors, isEmpty);
    expect(find.text('City: Oslo'), findsOneWidget);
  });
}

import 'package:a2ui_core/a2ui_core.dart'
    show
        A2uiRendererAction,
        A2uiRendererError,
        MessageProcessor,
        ValidationConfig;
import 'package:flutter_genui_mcp/flutter_genui_mcp.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_mcp_playground_example/genui_travel_example.dart';

typedef _Harness = ({
  List<A2uiRendererAction> actions,
  List<A2uiRendererError> errors,
});

/// Renders [root], a component of the travel catalog, as the root of a
/// surface, checked strictly.
Future<_Harness> _pumpRoot(
  WidgetTester tester,
  Map<String, Object?> root,
) async {
  final catalog = buildTravelGenuiCatalog();
  final processor = MessageProcessor<ComponentImplementation>(
    catalogs: [catalog],
    validationConfig: ValidationConfig.strict,
  );
  addTearDown(processor.dispose);
  final actions = <A2uiRendererAction>[];
  final errors = <A2uiRendererError>[];
  processor.model.onAction.subscribe(actions.add);
  processor.model.onError.subscribe(errors.add);
  processor.processMessages([
    {
      'version': 'v0.9',
      'createSurface': {'surfaceId': 'trip', 'catalogId': catalog.id},
    },
    {
      'version': 'v0.9',
      'updateComponents': {
        'surfaceId': 'trip',
        'components': [
          {'id': 'root', ...root},
        ],
      },
    },
  ]);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: A2uiSurface(surface: processor.model.getSurface('trip')!),
        ),
      ),
    ),
  );
  return (actions: actions, errors: errors);
}

void main() {
  testWidgets('TravelSearchForm sends the search as an action', (tester) async {
    final harness = await _pumpRoot(tester, {
      'component': 'TravelSearchForm',
      'title': 'Plan your trip',
      'defaultDestination': 'Lisbon, Portugal',
      'defaultAccommodationType': 'apartment',
    });
    expect(find.text('Plan your trip'), findsOneWidget);

    final submit = find.text('Search Stays & Generate Itinerary');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(harness.errors, isEmpty);
    final action = harness.actions.single;
    expect(action.name, 'search_travel_destinations');
    expect(action.sourceComponentId, 'root');
    expect(action.context['destination'], 'Lisbon, Portugal');
    expect(action.context['accommodationType'], 'apartment');
  });

  testWidgets('AccommodationGrid renders its items', (tester) async {
    final harness = await _pumpRoot(tester, {
      'component': 'AccommodationGrid',
      'title': 'Stays',
      'destination': 'Lisbon',
      'items': [
        {
          'name': 'Casa do Mar',
          'type': 'apartment',
          'price': '€140/night',
          'rating': 4.7,
          'amenities': ['Wi-Fi', 'Kitchen'],
        },
      ],
    });

    expect(harness.errors, isEmpty);
    expect(find.text('Stays • Lisbon'), findsOneWidget);
    expect(find.text('Casa do Mar'), findsOneWidget);
  });

  testWidgets('TravelItineraryCard renders its days', (tester) async {
    final harness = await _pumpRoot(tester, {
      'component': 'TravelItineraryCard',
      'title': 'Three days',
      'destination': 'Lisbon',
      'days': [
        {
          'title': 'Day 1',
          'theme': 'Old town',
          'activities': [
            {
              'time': '09:00',
              'title': 'Alfama walk',
              'description': 'Climb to the castle.',
            },
          ],
        },
      ],
    });

    expect(harness.errors, isEmpty);
    expect(find.text('Three days • Lisbon'), findsOneWidget);
    expect(find.text('09:00: Alfama walk'), findsOneWidget);
  });
}

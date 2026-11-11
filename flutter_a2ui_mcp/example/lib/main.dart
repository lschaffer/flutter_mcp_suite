import 'dart:convert';
import 'package:flutter_a2ui_mcp/flutter_a2ui_mcp.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _registerExampleCatalogBuilders();
  runApp(const A2uiExampleApp());
}

void _registerExampleCatalogBuilders() {
  A2uiCatalogRegistry.register('travel_hero_card', (context, node, props, buildChild) {
    final theme = Theme.of(context);
    final destination = props.string('destination') ?? 'Destination';
    final country = props.string('country') ?? '';
    final headline = props.string('headline') ?? '';
    final season = props.string('bestTimeToVisit') ?? 'Year-round';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flight_takeoff, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  destination,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (country.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Chip(
                    label: Text(country, style: const TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(headline, style: theme.textTheme.bodyMedium),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16),
                const SizedBox(width: 6),
                Text('Best time: $season', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  });

  A2uiCatalogRegistry.register('hotel_card', (context, node, props, buildChild) {
    final theme = Theme.of(context);
    final name = props.string('name') ?? 'Hotel';
    final price = props.string('pricePerNight') ?? '';
    final rating = props.value('rating')?.toString() ?? '4.5';
    final amenitiesRaw = props.value('amenities');
    final amenities = amenitiesRaw is List ? amenitiesRaw.map((e) => e.toString()).toList() : <String>[];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.hotel_rounded, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Text(price, style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
              ],
            ),
            if (amenities.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(amenities.join(' • '), style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  });
}

/// Example application demonstrating [A2uiMcpPlayground] with custom A2UI catalog items and MCP tools.
class A2uiExampleApp extends StatelessWidget {
  const A2uiExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A2UI & MCP Agent Playground',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const A2uiExampleHomePage(),
    );
  }
}

class A2uiExampleHomePage extends StatelessWidget {
  const A2uiExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: A2uiMcpPlayground(
        initialSystemPrompt:
            'You are an intelligent travel and lifestyle assistant equipped with A2UI dynamic surfaces.\n'
            'When the user asks for recommendations, travel plans, or weather data, call your tools and render '
            'structured, interactive A2UI surfaces using your catalog components (TravelHeroCard, HotelCard).',
        // Custom Dart-native local MCP tools
        customLocalTools: [
          _TravelSearchTool(),
          _CurrencyExchangeTool(),
        ],
        // Custom A2UI Catalog Item Definitions
        a2uiCatalogItems: [
          A2uiCatalogItemDefinition(
            type: 'TravelHeroCard',
            builder: 'travel_hero_card',
            description:
                'A hero card displaying a destination title, country, description, and highlights.',
            schema: S.object(
              properties: {
                'destination': S.string(description: 'City or destination name'),
                'country': S.string(description: 'Country name'),
                'headline': S.string(description: 'Catchy headline or theme'),
                'bestTimeToVisit': S.string(description: 'Ideal seasons to visit'),
              },
              required: ['destination', 'headline'],
            ),
          ),
          A2uiCatalogItemDefinition(
            type: 'HotelCard',
            builder: 'hotel_card',
            description: 'Displays recommended accommodation with price and star rating.',
            schema: S.object(
              properties: {
                'name': S.string(description: 'Hotel or resort name'),
                'pricePerNight': S.string(description: 'Nightly rate formatted (e.g. €120/night)'),
                'rating': S.number(description: 'Rating out of 5 (e.g. 4.8)'),
                'amenities': S.list(items: S.string(), description: 'List of key amenities'),
              },
              required: ['name', 'pricePerNight'],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Sample MCP Local Tools
// ═══════════════════════════════════════════════════════════════

class _TravelSearchTool extends McpLocalTool {
  @override
  String get name => 'search_travel_destinations';

  @override
  String get description =>
      'Searches curated travel destinations, hotels, and attractions for a given location.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'destination': {
            'type': 'string',
            'description': 'Target city or region (e.g. "Kyoto", "Rome", "Vienna").',
          },
        },
        'required': ['destination'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final destination = arguments['destination']?.toString() ?? 'Kyoto';
    return MCPToolResult.text(jsonEncode({
      'destination': destination,
      'country': destination.toLowerCase().contains('kyoto') ? 'Japan' : 'Italy',
      'currency': 'JPY',
      'recommendedHotels': [
        {
          'name': '$destination Grand Heritage Hotel',
          'pricePerNight': '€165/night',
          'rating': 4.8,
          'amenities': ['Free WiFi', 'Onsen / Spa', 'Breakfast Included'],
        },
        {
          'name': '$destination Boutique Residence',
          'pricePerNight': '€95/night',
          'rating': 4.6,
          'amenities': ['City Center', 'Kitchenette', 'Bicycle Rental'],
        },
      ],
      'highlights': ['Historic Temples & Castles', 'Local Culinary Markets', 'Scenic Gardens'],
    }));
  }
}

class _CurrencyExchangeTool extends McpLocalTool {
  @override
  String get name => 'convert_currency';

  @override
  String get description => 'Converts amounts between currencies.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'amount': {'type': 'number'},
          'from': {'type': 'string'},
          'to': {'type': 'string'},
        },
        'required': ['amount', 'from', 'to'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final amount = (arguments['amount'] as num?)?.toDouble() ?? 100.0;
    final from = arguments['from']?.toString().toUpperCase() ?? 'USD';
    final to = arguments['to']?.toString().toUpperCase() ?? 'EUR';
    final rate = (from == 'USD' && to == 'EUR') ? 0.92 : 1.08;
    return MCPToolResult.text(jsonEncode({
      'originalAmount': amount,
      'from': from,
      'to': to,
      'convertedAmount': (amount * rate).toStringAsFixed(2),
      'rate': rate,
    }));
  }
}

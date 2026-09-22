import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_genui_mcp/flutter_genui_mcp.dart';
import 'env_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const GenuiSmartHomeApp());
}

class GenuiSmartHomeApp extends StatelessWidget {
  const GenuiSmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI Smart Home Studio',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3E92B8), // Fluent Pastel Sky Blue
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF82CAED), // Fluent Frosted Powder Sky
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      home: const SmartHomeScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. Smart Home MCP Tools
// ═══════════════════════════════════════════════════════════════

class GetSmartHomeStateTool extends McpLocalTool {
  @override
  String get name => 'get_home_state';

  @override
  String get description => 'Get current state of thermostats, lights, locks, and power draw.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {},
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final state = {
      'thermostat': {
        'room': 'Living Room',
        'current_temp': 21.5,
        'target_temp': 23.0,
        'mode': 'Comfort',
        'humidity': 48,
      },
      'devices': [
        {'id': 'light_lr', 'name': 'Living Room Chandelier', 'type': 'light', 'is_on': true, 'brightness': 80},
        {'id': 'light_kitchen', 'name': 'Kitchen Counter Lights', 'type': 'light', 'is_on': false, 'brightness': 50},
        {'id': 'ac_master', 'name': 'Master Bedroom AC', 'type': 'climate', 'is_on': true, 'brightness': 65},
        {'id': 'lock_front', 'name': 'Front Door Smart Lock', 'type': 'lock', 'is_on': true, 'brightness': 100},
      ],
      'total_power_kw': 1.85,
    };
    return MCPToolResult(
      content: [MCPContent(type: 'text', text: jsonEncode(state))],
    );
  }
}

class SetDeviceStateTool extends McpLocalTool {
  @override
  String get name => 'set_device_state';

  @override
  String get description => 'Update target temperature, switch state, or brightness of a device.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'device_id': {'type': 'string'},
          'is_on': {'type': 'boolean'},
          'target_temp': {'type': 'number'},
          'brightness': {'type': 'number'},
        },
        'required': ['device_id'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({'success': true, 'updated': arguments}),
        ),
      ],
    );
  }
}

class GetEnergyUsageTool extends McpLocalTool {
  @override
  String get name => 'get_energy_usage';

  @override
  String get description => 'Get today’s energy consumption breakdown across rooms in kWh.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {},
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final usage = {
      'total_kwh': 14.8,
      'breakdown': [
        {'room': 'Living Room', 'kwh': 4.5},
        {'room': 'Kitchen', 'kwh': 5.2},
        {'room': 'Master Bedroom', 'kwh': 3.6},
        {'room': 'Home Office', 'kwh': 1.5},
      ],
    };
    return MCPToolResult(
      content: [MCPContent(type: 'text', text: jsonEncode(usage))],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. Custom GenUI Catalog Items
// ═══════════════════════════════════════════════════════════════

// --- A. Thermostat Widget ---
final thermostatSchema = S.object(
  description: 'Interactive smart thermostat control card.',
  properties: {
    'room': S.string(),
    'current_temp': S.number(),
    'target_temp': S.number(),
    'mode': S.string(),
    'humidity': S.number(),
  },
  required: ['room', 'current_temp', 'target_temp'],
);

final thermostatItem = CatalogItem(
  name: 'ThermostatCard',
  dataSchema: thermostatSchema,
  widgetBuilder: (itemContext) => _ThermostatCardWidget(itemContext: itemContext),
);

class _ThermostatCardWidget extends StatefulWidget {
  final CatalogItemContext itemContext;
  const _ThermostatCardWidget({required this.itemContext});

  @override
  State<_ThermostatCardWidget> createState() => _ThermostatCardWidgetState();
}

class _ThermostatCardWidgetState extends State<_ThermostatCardWidget> {
  late double _targetTemp;

  @override
  void initState() {
    super.initState();
    final data = widget.itemContext.data as Map<String, dynamic>? ?? {};
    _targetTemp = (data['target_temp'] as num?)?.toDouble() ?? 22.0;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.itemContext.data as Map<String, dynamic>? ?? {};
    final room = data['room']?.toString() ?? 'Room';
    final current = (data['current_temp'] as num?)?.toDouble() ?? 21.0;
    final mode = data['mode']?.toString() ?? 'Auto';
    final humidity = data['humidity']?.toString() ?? '45';

    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Current: ${current.toStringAsFixed(1)}°C • $humidity% RH', style: theme.textTheme.bodySmall),
                  ],
                ),
                Chip(
                  label: Text(mode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() => _targetTemp -= 0.5);
                  },
                ),
                const SizedBox(width: 24),
                Column(
                  children: [
                    Text(
                      '${_targetTemp.toStringAsFixed(1)}°C',
                      style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                    ),
                    const Text('TARGET TEMP', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 24),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() => _targetTemp += 0.5);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: _targetTemp.clamp(16.0, 30.0),
              min: 16.0,
              max: 30.0,
              divisions: 28,
              label: '${_targetTemp.toStringAsFixed(1)}°C',
              onChanged: (val) {
                setState(() => _targetTemp = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- B. Device Grid Widget ---
final deviceGridSchema = S.object(
  description: 'Interactive smart home device switches and controls.',
  properties: {
    'devices': S.list(
      items: S.object(
        properties: {
          'id': S.string(),
          'name': S.string(),
          'type': S.string(),
          'is_on': S.boolean(),
          'brightness': S.number(),
        },
      ),
    ),
  },
  required: ['devices'],
);

final deviceGridItem = CatalogItem(
  name: 'DeviceGrid',
  dataSchema: deviceGridSchema,
  widgetBuilder: (itemContext) => _DeviceGridWidget(itemContext: itemContext),
);

class _DeviceGridWidget extends StatefulWidget {
  final CatalogItemContext itemContext;
  const _DeviceGridWidget({required this.itemContext});

  @override
  State<_DeviceGridWidget> createState() => _DeviceGridWidgetState();
}

class _DeviceGridWidgetState extends State<_DeviceGridWidget> {
  final Map<String, bool> _states = {};

  @override
  Widget build(BuildContext context) {
    final data = widget.itemContext.data as Map<String, dynamic>? ?? {};
    final list = (data['devices'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.devices, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text('Device Controls', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 20),
            for (final d in list) ...[
              _buildDeviceRow(d),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceRow(Map<String, dynamic> d) {
    final id = d['id']?.toString() ?? '';
    final name = d['name']?.toString() ?? 'Device';
    final initialOn = d['is_on'] == true;
    final isOn = _states.putIfAbsent(id, () => initialOn);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOn ? Colors.blue.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isOn ? Icons.lightbulb : Icons.lightbulb_outline,
                color: isOn ? Colors.amber : Colors.grey,
              ),
              const SizedBox(width: 10),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          Switch(
            value: isOn,
            onChanged: (val) {
              setState(() => _states[id] = val);
            },
          ),
        ],
      ),
    );
  }
}

// --- C. Energy Usage Chart Widget ---
final energyChartSchema = S.object(
  description: 'Bar chart visualizing energy consumption across rooms.',
  properties: {
    'total_kwh': S.number(),
    'breakdown': S.list(
      items: S.object(
        properties: {
          'room': S.string(),
          'kwh': S.number(),
        },
      ),
    ),
  },
  required: ['breakdown'],
);

final energyChartItem = CatalogItem(
  name: 'EnergyChart',
  dataSchema: energyChartSchema,
  widgetBuilder: (itemContext) => _EnergyChartWidget(itemContext: itemContext),
);

class _EnergyChartWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _EnergyChartWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final list = (data['breakdown'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final total = (data['total_kwh'] as num?)?.toDouble() ?? 0.0;
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Energy Consumption', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text('${total.toStringAsFixed(1)} kWh total', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    for (var i = 0; i < list.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: (list[i]['kwh'] as num?)?.toDouble() ?? 0.0,
                            color: const Color(0xFF0284C7),
                            width: 22,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < list.length) {
                            final name = list[idx]['room']?.toString().split(' ').first ?? '';
                            return Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold));
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 3. Screen Setup
// ═══════════════════════════════════════════════════════════════

const String smartHomeSystemPrompt = '''
You are a smart home automation AI assistant.
When the user asks about home climate, devices, or energy usage:
1. Invoke the tools: `get_home_state` or `get_energy_usage`.
2. Generate interactive GenUI components:
   - "ThermostatCard" for climate control:
     {"room": "Living Room", "current_temp": 21.5, "target_temp": 23.0, "mode": "Comfort", "humidity": 48}
   - "DeviceGrid" for lights/switches:
     {"devices": [{"id": "1", "name": "Living Room Chandelier", "is_on": true, "brightness": 80}]}
   - "EnergyChart" for consumption:
     {"total_kwh": 14.8, "breakdown": [{"room": "Living Room", "kwh": 4.5}]}
''';

class SmartHomeScreen extends StatelessWidget {
  const SmartHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = BasicCatalogItems.asNoAssetCatalog().copyWith(
      newItems: [thermostatItem, deviceGridItem, energyChartItem],
    );

    // Load initial LLM configuration if configured in .env
    final initialLlm = LlmConfig(
      provider: EnvLoader.getProvider(),
      model: EnvLoader.get('LLM_MODEL', defaultValue: 'gpt-4o'),
      apiKey: EnvLoader.get('LLM_API_KEY'),
      baseUrl: EnvLoader.get('LLM_URL'),
    );

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.home_filled, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('GenUI Smart Home Studio'),
          ],
        ),
      ),
      body: GenuiMcpPlayground(
        initialLlmConfig: initialLlm.provider != LlmProvider.none ? initialLlm : null,
        customLocalTools: [
          GetSmartHomeStateTool(),
          SetDeviceStateTool(),
          GetEnergyUsageTool(),
        ],
        initialEnabledTools: const ['get_home_state', 'set_device_state', 'get_energy_usage'],
        initialSystemPrompt: smartHomeSystemPrompt,
        genuiCatalog: catalog,
        showAgentInspector: true,
      ),
    );
  }
}

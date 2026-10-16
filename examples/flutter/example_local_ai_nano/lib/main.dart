import 'dart:io';
import 'package:flutter_ui_mcp/flutter_ui_mcp.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LocalAiNanoApp());
}

class LocalAiNanoApp extends StatelessWidget {
  const LocalAiNanoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Nano On-Device Copilot',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8), // Google Blue
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8AB4F8), // Google Blue Dark
          brightness: Brightness.dark,
        ),
      ),
      home: const LocalAiNanoScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Local On-Device Tools (called directly by Gemini Nano)
// ═══════════════════════════════════════════════════════════════

/// A local device tool returning battery and power state.
class DeviceBatteryTool extends McpLocalTool {
  @override
  String get name => 'get_device_battery';

  @override
  String get description =>
      'Query the current battery percentage and charging state of this device.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {},
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    // In production, this can hook into battery_plus or Android BatteryManager
    return MCPToolResult.text(
      'Battery: 86%, Charging: Fast Charging (Wireless), Health: Good, Temp: 31.5°C',
      metadata: {
        'level': 86,
        'isCharging': true,
        'source': 'Android AICore BatteryManager',
      },
    );
  }
}

/// A local device tool returning hardware & OS telemetry.
class DeviceTelemetryTool extends McpLocalTool {
  @override
  String get name => 'get_device_telemetry';

  @override
  String get description =>
      'Inspect hardware CPU cores, operating system, and on-device NPU/AICore status.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {},
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final os = Platform.operatingSystem;
    final version = Platform.operatingSystemVersion;
    final cores = Platform.numberOfProcessors;

    return MCPToolResult.text(
      'Device Specs:\n'
      '• OS: $os ($version)\n'
      '• Processor: $cores CPU Cores + On-Device NPU\n'
      '• Model Engine: Google Gemini Nano via Android AICore\n'
      '• Privacy: 100% on-device inference, no data transmitted.',
      metadata: {
        'os': os,
        'cores': cores,
        'npuEnabled': true,
      },
    );
  }
}

const String nanoSystemPrompt = '''
You are an intelligent, ultra-responsive on-device AI copilot powered by Google Gemini Nano.
You run entirely on the user's mobile device (Samsung Galaxy S25 / Android AICore) with zero cloud latency.

Available Local Tools:
- `get_device_battery`: Check battery level and charging status.
- `get_device_telemetry`: Inspect CPU, NPU, and OS specs.

Tool Usage Rules:
- When the user asks about battery, power, or charging, invoke `get_device_battery`.
- When the user asks about hardware, device specs, or OS telemetry, invoke `get_device_telemetry`.
- Be concise, direct, helpful, and highlight on-device privacy.
''';

class LocalAiNanoScreen extends StatelessWidget {
  const LocalAiNanoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAndroid = theme.platform == TargetPlatform.android;

    const nanoConfig = LlmConfig(
      provider: LlmProvider.localAi,
      model: 'gemini-nano',
      apiKey: '', // No API key required on-device
    );

    return Scaffold(
      body: Column(
        children: [
          // On-device status banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAndroid
                            ? 'On-Device AI: Google Gemini Nano (Samsung Galaxy S25 / Android AICore)'
                            : 'On-Device AI Engine: Local OS-Native Inference',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Zero cloud latency • 100% Private • Local Tool Execution Enabled',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'OFFLINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: McpPlayground(
              initialLlmConfig: nanoConfig,
              customLocalTools: [
                DeviceBatteryTool(),
                DeviceTelemetryTool(),
              ],
              initialEnabledTools: const [
                'get_device_battery',
                'get_device_telemetry',
              ],
              initialSystemPrompt: nanoSystemPrompt,
              showAgentInspector: true,
            ),
          ),
        ],
      ),
    );
  }
}

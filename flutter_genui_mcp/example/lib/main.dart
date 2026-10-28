import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_genui_mcp/flutter_genui_mcp.dart';
import 'env_loader.dart';
import 'genui_travel_example.dart';

// Standalone GenUI Examples (imported with prefix aliases to avoid collisions)
import 'package:example_genui_weather/main.dart' as weather_demo;
import 'package:example_genui_weather/env_loader.dart' as weather_env;
import 'package:example_genui_smarthome/main.dart' as smarthome_demo;
import 'package:example_genui_smarthome/env_loader.dart' as smarthome_env;
import 'package:example_genui_pc_builder/main.dart' as pc_builder_demo;
import 'package:example_genui_pc_builder/env_loader.dart' as pc_builder_env;
import 'package:example_genui_finance/main.dart' as finance_demo;
import 'package:example_genui_finance/env_loader.dart' as finance_env;
import 'package:mcp_playground_flutter_example_genui_filesystem/main.dart'
    as filesystem_demo;
import 'package:mcp_playground_flutter_example_genui_filesystem/env_loader.dart'
    as filesystem_env;
import 'package:example_genui_file_etl/main.dart' as file_etl_demo;
import 'package:example_genui_file_etl/env_loader.dart' as file_etl_env;
import 'package:example_genui_data_studio/main.dart' as data_studio_demo;
import 'package:example_genui_data_studio/env_loader.dart' as data_studio_env;
import 'package:example_genui_model_optimizer/main.dart'
    as model_optimizer_demo;
import 'package:example_genui_model_optimizer/env_loader.dart'
    as model_optimizer_env;
import 'package:example_genui_benchmark_lab/main.dart' as benchmark_lab_demo;
import 'package:example_genui_benchmark_lab/env_loader.dart'
    as benchmark_lab_env;
import 'package:example_genui_agent_swarm/main.dart' as agent_swarm_demo;
import 'package:example_genui_agent_swarm/env_loader.dart' as agent_swarm_env;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  await Future.wait([
    weather_env.EnvLoader.load(),
    smarthome_env.EnvLoader.load(),
    pc_builder_env.EnvLoader.load(),
    finance_env.EnvLoader.load(),
    filesystem_env.EnvLoader.load(),
    file_etl_env.EnvLoader.load(),
    data_studio_env.EnvLoader.load(),
    model_optimizer_env.EnvLoader.load(),
    benchmark_lab_env.EnvLoader.load(),
    agent_swarm_env.EnvLoader.load(),
  ]);
  runApp(const GenuiShowcaseApp());
}

/// Available showcase demos in the Flutter GenUI MCP Gallery.
enum GenuiMcpDemo {
  travel(
    id: 'travel',
    title: 'Travel & Stay Planner',
    subtitle: 'Interactive booking, hotel cards, SerpAPI live search & itinerary timelines',
    icon: Icons.flight_takeoff_rounded,
    badge: 'Flagship',
    examplePrompts: [
      'Plan a 4-day trip to Kyoto with boutique hotels near Gion and a day-by-day sightseeing itinerary.',
      'Find family-friendly accommodations in Barcelona near the beach under \$220/night.',
      'Create a 3-day weekend itinerary in Paris highlighting museums and top dining spots.',
    ],
  ),
  weather(
    id: 'weather',
    title: 'Weather Copilot & Live Charts',
    subtitle: 'Open-Meteo forecasts, dynamic parameter form, multi-channel fl_chart & JPG export',
    icon: Icons.wb_sunny_rounded,
    badge: 'Weather',
    examplePrompts: [
      'Show me the 7-day weather forecast for Vienna with temperature and precipitation chart.',
      'Give me a 48h weather forecast for Tokyo with wind speed and cloud cover.',
      'Render the weather parameter form so I can choose custom channels for New York.',
    ],
  ),
  smartHome(
    id: 'smarthome',
    title: 'Smart Home IoT & Thermostats',
    subtitle: 'Dynamic thermostat controls, device toggle grid & 7-day energy telemetry chart',
    icon: Icons.home_rounded,
    badge: 'IoT',
    examplePrompts: [
      'Turn on the living room thermostat and set temperature to 22°C in Eco mode.',
      'Show all connected smart home devices and their real-time power consumption.',
      'Generate an energy usage chart comparing living room and kitchen consumption over the last 7 days.',
    ],
  ),
  pcBuilder(
    id: 'pc_builder',
    title: 'PC Hardware Architect',
    subtitle: 'Custom gaming & workstation PC configurator, hardware catalog grid & live order receipt',
    icon: Icons.computer_rounded,
    badge: 'Hardware',
    examplePrompts: [
      'Help me build a 4K gaming PC with RTX 4080 Super and Ryzen 7 7800X3D under \$2500.',
      'Recommend a quiet workstation PC for 8K video editing and 3D rendering with 64GB RAM.',
      'Show me compatible DDR5 RAM kits and PCIe 4.0 NVMe SSD options for gaming.',
    ],
  ),
  finance(
    id: 'finance',
    title: 'Finance & Portfolio Analytics',
    subtitle: 'Interactive budget allocation sliders, expense breakdown pie chart & investment growth curves',
    icon: Icons.pie_chart_rounded,
    badge: 'Finance',
    examplePrompts: [
      'Analyze my monthly budget of \$5,000 and create an interactive slider allocation plan.',
      'Show investment growth projection for \$1,200/month over 15 years at 7.5% annual return.',
      'Generate expense breakdown pie chart for: Rent \$2100, Groceries \$750, Travel \$450, Savings \$1700.',
    ],
  ),
  filesystem(
    id: 'filesystem',
    title: 'Cloud & Filesystem Explorer',
    subtitle: 'Interactive directory trees, syntax-highlighted file preview surfaces & metadata cards',
    icon: Icons.folder_copy_rounded,
    badge: 'Filesystem',
    examplePrompts: [
      'Explore current project directory and render an interactive tree view with file sizes.',
      'Inspect pubspec.yaml file metadata and display its configuration contents.',
      'Preview lib/main.dart and highlight imports and top-level definitions.',
    ],
  ),
  fileEtl(
    id: 'file_etl',
    title: 'File ETL & Data Pipeline',
    subtitle: 'Dataset summary cards, interactive schema transformer, preview table & export pipeline',
    icon: Icons.transform_rounded,
    badge: 'Pipeline',
    examplePrompts: [
      'Ingest customer transactions CSV, clean invalid email formats, and map to enterprise schema.',
      'Build an automated ETL pipeline that normalizes dates, trims whitespace, and calculates totals.',
      'Show preview table of transformed dataset with 10 sample records and export as JSON.',
    ],
  ),
  dataStudio(
    id: 'data_studio',
    title: 'Data Studio & BI Dashboards',
    subtitle: 'Executive KPI metric cards, interactive data table with filters & 12-month revenue trend chart',
    icon: Icons.insights_rounded,
    badge: 'Analytics',
    examplePrompts: [
      'Generate executive SaaS dashboard with MRR, churn rate, LTV, and customer acquisition cost.',
      'Render interactive data table for regional sales with sorting, search, and margin columns.',
      'Plot 12-month revenue trend chart with 95% confidence interval and seasonality indicators.',
    ],
  ),
  modelOptimizer(
    id: 'model_optimizer',
    title: 'Model Optimizer & Cost Lab',
    subtitle: 'Side-by-side model comparison, 10M token cost projections & intelligent routing policy',
    icon: Icons.speed_rounded,
    badge: 'AI Ops',
    examplePrompts: [
      'Compare latency, throughput, and costs between GPT-4o, Claude 3.5 Sonnet, and Gemini 1.5 Pro.',
      'Generate monthly cost projection for 15M input tokens and 4M output tokens across top models.',
      'Recommend intelligent model routing rules to optimize cost for classification while preserving accuracy.',
    ],
  ),
  benchmarkLab(
    id: 'benchmark_lab',
    title: 'Benchmark Quality Lab',
    subtitle: 'Model benchmark scorecard, 5-axis radar chart & latency vs cost scatter plot',
    icon: Icons.science_rounded,
    badge: 'Benchmarks',
    examplePrompts: [
      'Run MMLU and HumanEval benchmark comparison between open-source and proprietary models.',
      'Render 5-axis radar chart evaluating reasoning, coding, math, tool-use, and instruction-following.',
      'Plot latency vs cost scatter chart with pareto frontier for current model portfolio.',
    ],
  ),
  agentSwarm(
    id: 'agent_swarm',
    title: 'Agent Swarm Orchestrator',
    subtitle: 'Multi-agent collaboration timeline, subtask dependency graph & live worker status',
    icon: Icons.hub_rounded,
    badge: 'Swarm',
    examplePrompts: [
      'Orchestrate 3-agent swarm: Researcher, Synthesizer, and Reviewer to investigate market trends.',
      'Display real-time multi-agent execution timeline with subtask dependencies and step logs.',
      'Coordinate parallel agent workers to scrape, summarize, and cross-validate industry whitepapers.',
    ],
  );

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final List<String> examplePrompts;

  const GenuiMcpDemo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.examplePrompts,
  });
}

class GenuiShowcaseApp extends StatefulWidget {
  const GenuiShowcaseApp({super.key});

  @override
  State<GenuiShowcaseApp> createState() => _GenuiShowcaseAppState();
}

/// Backwards compatibility alias for [GenuiShowcaseApp].
typedef GenuiTravelExampleApp = GenuiShowcaseApp;

class _GenuiShowcaseAppState extends State<GenuiShowcaseApp> {
  ThemeMode _themeMode = ThemeMode.system;
  GenuiMcpDemo _currentDemo = GenuiMcpDemo.travel;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _selectDemo(GenuiMcpDemo demo) {
    setState(() {
      _currentDemo = demo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter GenUI MCP - Feature Showcase',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('de', ''),
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF),
          brightness: Brightness.dark,
        ),
      ),
      home: GenuiShowcaseGalleryShell(
        currentDemo: _currentDemo,
        onSelectDemo: _selectDemo,
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class GenuiShowcaseGalleryShell extends StatelessWidget {
  final GenuiMcpDemo currentDemo;
  final ValueChanged<GenuiMcpDemo> onSelectDemo;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const GenuiShowcaseGalleryShell({
    super.key,
    required this.currentDemo,
    required this.onSelectDemo,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  void _showPromptsDialog(BuildContext context, GenuiMcpDemo demo) {
    GenuiExamplePromptsDialog.show(
      context,
      title: demo.title,
      subtitle: demo.subtitle,
      icon: demo.icon,
      badge: demo.badge,
      prompts: demo.examplePrompts,
    );
  }

  void _showFeaturePicker(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.auto_awesome_mosaic_rounded,
                          size: 18,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GenUI Showcase Domains',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Select any domain to test or inspect prompts',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: GenuiMcpDemo.values.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final demo = GenuiMcpDemo.values[index];
                        final isSelected = demo == currentDemo;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            onSelectDemo(demo);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primaryContainer
                                      .withValues(alpha: 0.35)
                                  : colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.primaryContainer,
                                      child: Icon(
                                        demo.icon,
                                        size: 16,
                                        color: isSelected
                                            ? colorScheme.onPrimary
                                            : colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        demo.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? colorScheme.primary
                                              : null,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        demo.badge,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 18,
                                        color: colorScheme.primary,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  demo.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.3,
                                  ),
                                ),
                                if (demo.examplePrompts.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.lightbulb_outline_rounded,
                                        size: 14,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          demo.examplePrompts.first,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: colorScheme.outline,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.tips_and_updates_rounded,
                                            size: 16),
                                        tooltip: 'View Prompts',
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          _showPromptsDialog(context, demo);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    final promptTooltipText = currentDemo.examplePrompts.isNotEmpty
        ? '💡 Example Prompts:\n• ${currentDemo.examplePrompts.join('\n• ')}'
        : 'View Example Prompts';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        elevation: 1,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_mosaic_rounded,
                    size: 16,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 6),
                    Text(
                      'GENUI MCP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: isMobile
                  ? InkWell(
                      onTap: () => _showFeaturePicker(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(currentDemo.icon, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                currentDemo.title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                currentDemo.badge,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_drop_down_rounded, size: 18),
                          ],
                        ),
                      ),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<GenuiMcpDemo>(
                        isExpanded: true,
                        menuWidth: 420,
                        value: currentDemo,
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        items: GenuiMcpDemo.values.map((demo) {
                          final isFlagship = demo.badge == 'Flagship';
                          return DropdownMenuItem<GenuiMcpDemo>(
                            value: demo,
                            child: Row(
                              children: [
                                Icon(demo.icon, size: 18),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    demo.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isFlagship
                                        ? colorScheme.primary
                                            .withValues(alpha: 0.15)
                                        : colorScheme.secondary
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    demo.badge,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isFlagship
                                          ? colorScheme.primary
                                          : colorScheme.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) onSelectDemo(val);
                        },
                      ),
                    ),
            ),
            const SizedBox(width: 4),
            // Example Prompts button placed directly beside the dropdown
            Tooltip(
              message: promptTooltipText,
              waitDuration: const Duration(milliseconds: 300),
              showDuration: const Duration(seconds: 5),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              textStyle: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
              child: IconButton.filledTonal(
                icon: const Icon(
                  Icons.tips_and_updates_rounded,
                  size: 18,
                  color: Colors.amber,
                ),
                tooltip: 'Example Prompts (Click to View & Copy)',
                onPressed: () => _showPromptsDialog(context, currentDemo),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: KeyedSubtree(
        key: ValueKey(currentDemo.id),
        child: _buildCurrentDemoView(context),
      ),
    );
  }

  Widget _buildCurrentDemoView(BuildContext context) {
    switch (currentDemo) {
      case GenuiMcpDemo.travel:
        return const GenuiTravelScreen();
      case GenuiMcpDemo.weather:
        return const weather_demo.GenuiWeatherScreen();
      case GenuiMcpDemo.smartHome:
        return const smarthome_demo.SmartHomeScreen();
      case GenuiMcpDemo.pcBuilder:
        return const pc_builder_demo.PcBuilderMainScreen();
      case GenuiMcpDemo.finance:
        return const finance_demo.FinanceScreen();
      case GenuiMcpDemo.filesystem:
        return const filesystem_demo.GenuiFilesystemScreen();
      case GenuiMcpDemo.fileEtl:
        return const file_etl_demo.FileEtlScreen();
      case GenuiMcpDemo.dataStudio:
        return const data_studio_demo.DataStudioScreen();
      case GenuiMcpDemo.modelOptimizer:
        return const model_optimizer_demo.ModelOptimizerScreen();
      case GenuiMcpDemo.benchmarkLab:
        return const benchmark_lab_demo.BenchmarkLabScreen();
      case GenuiMcpDemo.agentSwarm:
        return const agent_swarm_demo.AgentSwarmScreen();
    }
  }
}

/// Dialog displaying selectable GenUI example prompts with 1-tap copy functionality.
class GenuiExamplePromptsDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final List<String> prompts;

  const GenuiExamplePromptsDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.prompts,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
    required List<String> prompts,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => GenuiExamplePromptsDialog(
        title: title,
        subtitle: subtitle,
        icon: icon,
        badge: badge,
        prompts: prompts,
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Copied prompt to clipboard!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(icon, size: 20, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // Prompts section header
              Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates_rounded,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tested Example Prompts',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Select any text or tap the copy button to copy into the chat input:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: 12),
              // Prompts List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: prompts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final prompt = prompts[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _copyToClipboard(context, prompt),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SelectableText(
                                prompt,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              tooltip: 'Copy Prompt',
                              onPressed: () => _copyToClipboard(context, prompt),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

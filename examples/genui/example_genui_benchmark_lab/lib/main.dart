import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_genui_mcp/flutter_genui_mcp.dart';
import 'env_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const GenuiBenchmarkLabApp());
}

class GenuiBenchmarkLabApp extends StatelessWidget {
  const GenuiBenchmarkLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI Model & Prompt Benchmark Lab',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9333EA), // Royal Violet / Benchmark Lab
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA855F7),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      home: const BenchmarkLabScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. Benchmark & Evaluation MCP Tools
// ═══════════════════════════════════════════════════════════════

class RunPromptBenchmarkTool extends McpLocalTool {
  @override
  String get name => 'run_prompt_benchmark';

  @override
  String get description =>
      'Execute prompt benchmarks across candidate models, measuring latency, token usage, quality scores, and monetary cost.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'test_prompt': {'type': 'string', 'description': 'The benchmark prompt to evaluate'},
          'models': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Candidate models to benchmark',
          },
        },
        'required': ['test_prompt'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final prompt = arguments['test_prompt']?.toString() ?? 'Extract structured entities';
    final candidateModels = (arguments['models'] as List?)?.cast<String>() ?? [
      'claude-3-5-sonnet',
      'gpt-4o',
      'deepseek-chat',
      'gemini-1.5-flash',
    ];

    final runs = [
      {
        'model': 'claude-3-5-sonnet',
        'latency_ms': 740,
        'accuracy_score': 98.2,
        'instruction_score': 99.0,
        'conciseness_score': 94.0,
        'hallucination_resistance': 98.5,
        'cost_per_1k': 0.0090,
        'tokens_used': 340,
        'is_winner': true,
      },
      {
        'model': 'gpt-4o',
        'latency_ms': 620,
        'accuracy_score': 96.5,
        'instruction_score': 96.0,
        'conciseness_score': 91.0,
        'hallucination_resistance': 96.0,
        'cost_per_1k': 0.0075,
        'tokens_used': 365,
        'is_winner': false,
      },
      {
        'model': 'deepseek-chat',
        'latency_ms': 480,
        'accuracy_score': 95.0,
        'instruction_score': 94.5,
        'conciseness_score': 92.0,
        'hallucination_resistance': 94.0,
        'cost_per_1k': 0.00042,
        'tokens_used': 320,
        'is_winner': false,
      },
      {
        'model': 'gemini-1.5-flash',
        'latency_ms': 310,
        'accuracy_score': 91.8,
        'instruction_score': 92.0,
        'conciseness_score': 88.0,
        'hallucination_resistance': 90.5,
        'cost_per_1k': 0.00030,
        'tokens_used': 310,
        'is_winner': false,
      },
    ];

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({
            'success': true,
            'test_prompt': prompt,
            'models_evaluated': candidateModels.length,
            'runs': runs,
          }),
        ),
      ],
    );
  }
}

class EvaluateModelTradeoffsTool extends McpLocalTool {
  @override
  String get name => 'evaluate_model_tradeoffs';

  @override
  String get description =>
      'Compute the Pareto frontier balancing quality score vs. response latency vs. cost per thousand queries.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'priority': {
            'type': 'string',
            'description': 'Primary optimization goal: quality, speed, or cost',
          },
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final priority = arguments['priority']?.toString() ?? 'cost';

    final evaluation = {
      'optimization_priority': priority,
      'recommendation': priority == 'quality'
          ? 'Claude 3.5 Sonnet delivers highest accuracy (98.2%) with superior instruction following.'
          : priority == 'speed'
              ? 'Gemini 1.5 Flash delivers lowest TTFT and end-to-end latency (310ms).'
              : 'DeepSeek-Chat offers optimal Pareto frontier: 95% accuracy at 95% lower cost than frontier models.',
      'winner_model': priority == 'quality'
          ? 'claude-3-5-sonnet'
          : priority == 'speed'
              ? 'gemini-1.5-flash'
              : 'deepseek-chat',
    };

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({'success': true, 'evaluation': evaluation}),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. Custom GenUI Catalog Items
// ═══════════════════════════════════════════════════════════════

// --- A. Benchmark Scorecard ---
final benchmarkScorecardSchema = S.object(
  description: 'Executive KPI scoreboard summarizing model latency, accuracy, cost, and winner.',
  properties: {
    'winner_model': S.string(),
    'avg_latency_ms': S.integer(),
    'top_accuracy_percent': S.number(),
    'cost_comparison_summary': S.string(),
  },
  required: ['winner_model', 'avg_latency_ms', 'top_accuracy_percent'],
);

final benchmarkScorecardItem = CatalogItem(
  name: 'BenchmarkScorecard',
  dataSchema: benchmarkScorecardSchema,
  widgetBuilder: (itemContext) => _BenchmarkScorecardWidget(itemContext: itemContext),
);

class _BenchmarkScorecardWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _BenchmarkScorecardWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final winner = data['winner_model']?.toString() ?? 'deepseek-chat';
    final latency = data['avg_latency_ms']?.toString() ?? '480';
    final accuracy = data['top_accuracy_percent']?.toString() ?? '98.2';
    final summary = data['cost_comparison_summary']?.toString() ?? '95% cost reduction achieved';
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.military_tech, color: Colors.purple, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Benchmark Evaluation Scorecard', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Pareto-Optimal Pick: $winner', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('WINNER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Top Accuracy', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text('$accuracy%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Avg Latency', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text('${latency}ms', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Savings', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(summary.contains('%') ? summary.split(' ').first : '-95%',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- B. Radar / Quality Comparison Bars ---
final qualityComparisonSchema = S.object(
  description: 'Detailed quality criteria metrics comparing instruction adherence, conciseness, and hallucinations.',
  properties: {
    'title': S.string(),
    'models': S.list(
      items: S.object(
        properties: {
          'model_name': S.string(),
          'accuracy': S.number(),
          'instruction_following': S.number(),
          'conciseness': S.number(),
          'hallucination_resistance': S.number(),
        },
        required: ['model_name', 'accuracy', 'instruction_following'],
      ),
    ),
  },
  required: ['models'],
);

final qualityComparisonItem = CatalogItem(
  name: 'RadarQualityChart',
  dataSchema: qualityComparisonSchema,
  widgetBuilder: (itemContext) => _RadarQualityChartWidget(itemContext: itemContext),
);

class _RadarQualityChartWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _RadarQualityChartWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final title = data['title']?.toString() ?? 'Model Quality Criterion Breakdown';
    final models = (data['models'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...models.map((m) {
              final name = m['model_name']?.toString() ?? '';
              final acc = (m['accuracy'] as num?)?.toDouble() ?? 90.0;
              final inst = (m['instruction_following'] as num?)?.toDouble() ?? 90.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Overall: ${((acc + inst) / 2).toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const SizedBox(width: 100, child: Text('Accuracy:', style: TextStyle(fontSize: 10, color: Colors.grey))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: acc / 100.0,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                valueColor: const AlwaysStoppedAnimation(Colors.purple),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${acc.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const SizedBox(width: 100, child: Text('Instructions:', style: TextStyle(fontSize: 10, color: Colors.grey))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: inst / 100.0,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                valueColor: const AlwaysStoppedAnimation(Colors.blue),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${inst.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// --- C. Latency vs. Cost Comparison Chart ---
final latencyCostSchema = S.object(
  description: 'Bar comparison showing Latency (ms) and Cost per 1k requests across models.',
  properties: {
    'title': S.string(),
    'models': S.list(
      items: S.object(
        properties: {
          'model': S.string(),
          'latency_ms': S.integer(),
          'cost_per_1k': S.number(),
        },
        required: ['model', 'latency_ms', 'cost_per_1k'],
      ),
    ),
  },
  required: ['models'],
);

final latencyCostItem = CatalogItem(
  name: 'LatencyCostScatter',
  dataSchema: latencyCostSchema,
  widgetBuilder: (itemContext) => _LatencyCostScatterWidget(itemContext: itemContext),
);

class _LatencyCostScatterWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _LatencyCostScatterWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final title = data['title']?.toString() ?? 'Speed vs. Cost Evaluation';
    final models = (data['models'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1000,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < models.length) {
                            final rawName = models[idx]['model']?.toString() ?? '';
                            final shortName = rawName.split('-').first;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(shortName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (v, meta) => Text('${v.toInt()}ms', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(models.length, (i) {
                    final lat = (models[i]['latency_ms'] as num?)?.toDouble() ?? 500.0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: lat,
                          color: i == 0 ? Colors.purple : (i == 1 ? Colors.blue : Colors.teal),
                          width: 22,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }),
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
// 3. Screen Setup & System Prompt
// ═══════════════════════════════════════════════════════════════

const String benchmarkLabSystemPrompt = '''
You are an expert AI Model Evaluator and Benchmark Scientist.
When the user asks to test, benchmark, or compare LLM models on specific tasks:
1. Invoke tools:
   - `run_prompt_benchmark` to measure response quality, latency, token throughput, and costs across candidate models.
   - `evaluate_model_tradeoffs` to compute Pareto frontiers across quality, speed, and cost.
2. Render rich, interactive GenUI components:
   - "BenchmarkScorecard" to highlight winner model, latency, and accuracy KPIs.
   - "RadarQualityChart" to compare instruction adherence, conciseness, and hallucinations.
   - "LatencyCostScatter" to visually present response latency in milliseconds.
''';

class BenchmarkLabScreen extends StatelessWidget {
  const BenchmarkLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = BasicCatalogItems.asNoAssetCatalog().copyWith(
      newItems: [
        benchmarkScorecardItem,
        qualityComparisonItem,
        latencyCostItem,
      ],
    );

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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'GenUI Model & Prompt Benchmark Lab',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: GenuiMcpPlayground(
        initialLlmConfig: initialLlm.provider != LlmProvider.none ? initialLlm : null,
        customLocalTools: [
          RunPromptBenchmarkTool(),
          EvaluateModelTradeoffsTool(),
        ],
        initialEnabledTools: const [
          'run_prompt_benchmark',
          'evaluate_model_tradeoffs',
        ],
        initialSystemPrompt: benchmarkLabSystemPrompt,
        genuiCatalog: catalog,
        showAgentInspector: true,
      ),
    );
  }
}

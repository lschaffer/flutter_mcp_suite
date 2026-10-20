import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_genui_mcp/flutter_genui_mcp.dart';
import 'env_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const GenuiModelOptimizerApp());
}

class GenuiModelOptimizerApp extends StatelessWidget {
  const GenuiModelOptimizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI Model Cost & Architecture Optimizer',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5), // Indigo Accent
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF818CF8), // Periwinkle Violet
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      home: const ModelOptimizerScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. Model Pricing & Architecture MCP Tools
// ═══════════════════════════════════════════════════════════════

class QueryModelPricingTool extends McpLocalTool {
  @override
  String get name => 'query_model_pricing';

  @override
  String get description =>
      'Query live token pricing, context window limits, and provider classification for one or more LLM models.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'models': {
            'type': 'array',
            'items': {'type': 'string'},
            'description':
                'List of model IDs (e.g. gpt-4o, claude-3-5-sonnet, deepseek-chat, gemini-1.5-flash, llama3:8b)',
          },
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final rawList = arguments['models'] as List? ?? [
      'gpt-4o',
      'claude-3-5-sonnet',
      'deepseek-chat',
      'gemini-1.5-flash',
      'llama3:8b',
    ];

    final results = <Map<String, dynamic>>[];

    for (final raw in rawList) {
      final modelId = raw.toString();
      final isLocal = modelId.toLowerCase().contains('llama') ||
          modelId.toLowerCase().contains('ollama') ||
          modelId.toLowerCase().contains('local') ||
          modelId.toLowerCase().contains('qwen');

      final cfg = LlmConfig(
        provider: isLocal
            ? LlmProvider.ollama
            : modelId.startsWith('claude')
                ? LlmProvider.claude
                : modelId.startsWith('gemini')
                    ? LlmProvider.gemini
                    : LlmProvider.openai,
        model: modelId,
        apiKey: 'demo-key',
        baseUrl: isLocal ? 'http://localhost:11434' : '',
      );

      final priceInfo = await ModelPricingService.fetchPrice(cfg);
      final inUsd = priceInfo.inputPer1MUsd;
      final outUsd = priceInfo.outputPer1MUsd;
      final inEur = ModelPricingService.toEur(inUsd);
      final outEur = ModelPricingService.toEur(outUsd);

      results.add({
        'model': modelId,
        'provider': cfg.provider.name,
        'input_per_1m_usd': inUsd,
        'output_per_1m_usd': outUsd,
        'input_per_1m_eur': double.parse(inEur.toStringAsFixed(4)),
        'output_per_1m_eur': double.parse(outEur.toStringAsFixed(4)),
        'context_window': priceInfo.contextWindow ?? 128000,
        'formatted_context': priceInfo.formattedContextWindow ?? '128k',
        'is_local': isLocal,
        'rate_description': priceInfo.rateDescription,
      });
    }

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({'success': true, 'models': results}),
        ),
      ],
    );
  }
}

class SimulateWorkloadTool extends McpLocalTool {
  @override
  String get name => 'simulate_workload';

  @override
  String get description =>
      'Simulate monthly token consumption and costs across multiple models for given volume, prompt length, and completion length.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'monthly_requests': {
            'type': 'integer',
            'description': 'Expected number of queries per month (e.g. 50000)',
          },
          'avg_input_tokens': {
            'type': 'integer',
            'description': 'Average prompt tokens per request (e.g. 1500)',
          },
          'avg_output_tokens': {
            'type': 'integer',
            'description': 'Average completion tokens per request (e.g. 500)',
          },
        },
        'required': ['monthly_requests', 'avg_input_tokens', 'avg_output_tokens'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final requests = (arguments['monthly_requests'] as num?)?.toInt() ?? 50000;
    final inTokens = (arguments['avg_input_tokens'] as num?)?.toInt() ?? 1500;
    final outTokens = (arguments['avg_output_tokens'] as num?)?.toInt() ?? 500;

    final totalIn1M = (requests * inTokens) / 1000000.0;
    final totalOut1M = (requests * outTokens) / 1000000.0;

    final modelsProfile = [
      {'name': 'gpt-4o', 'in': 2.50, 'out': 10.00, 'color': '#EF4444'},
      {'name': 'claude-3-5-sonnet', 'in': 3.00, 'out': 15.00, 'color': '#F59E0B'},
      {'name': 'gemini-1.5-flash', 'in': 0.075, 'out': 0.30, 'color': '#3B82F6'},
      {'name': 'deepseek-chat', 'in': 0.14, 'out': 0.28, 'color': '#10B981'},
      {'name': 'ollama-local', 'in': 0.0, 'out': 0.0, 'color': '#6B7280'},
    ];

    final comparisons = <Map<String, dynamic>>[];
    for (final m in modelsProfile) {
      final inRate = m['in'] as double;
      final outRate = m['out'] as double;
      final monthlyUsd = (totalIn1M * inRate) + (totalOut1M * outRate);
      final monthlyEur = ModelPricingService.toEur(monthlyUsd);

      final curve = [10000, 25000, 50000, 100000].map((r) {
        final stepIn = (r * inTokens) / 1000000.0;
        final stepOut = (r * outTokens) / 1000000.0;
        return {
          'requests': '${(r / 1000).round()}k',
          'cost': double.parse(((stepIn * inRate) + (stepOut * outRate)).toStringAsFixed(2)),
        };
      }).toList();

      comparisons.add({
        'model': m['name'],
        'color': m['color'],
        'monthly_cost_usd': double.parse(monthlyUsd.toStringAsFixed(2)),
        'monthly_cost_eur': double.parse(monthlyEur.toStringAsFixed(2)),
        'curve_points': curve,
      });
    }

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({
            'success': true,
            'requests': requests,
            'total_input_tokens': (totalIn1M * 1000000).round(),
            'total_output_tokens': (totalOut1M * 1000000).round(),
            'comparisons': comparisons,
          }),
        ),
      ],
    );
  }
}

class RecommendRoutingTool extends McpLocalTool {
  @override
  String get name => 'recommend_model_routing';

  @override
  String get description =>
      'Generate an optimal tiered multi-model routing architecture tailored for cost, quality, and context capacity.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workload_profile': {
            'type': 'string',
            'description':
                'Target workload type: customer_support, coding_agent, enterprise_rag, or high_volume_extraction',
          },
          'monthly_budget_usd': {
            'type': 'number',
            'description': 'Target monthly budget threshold in USD',
          },
        },
        'required': ['workload_profile'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final profile = arguments['workload_profile']?.toString() ?? 'enterprise_rag';
    final budget = (arguments['monthly_budget_usd'] as num?)?.toDouble() ?? 300.0;

    final recommendation = {
      'strategy_title': 'Tiered Intelligent LLM Routing',
      'workload_profile': profile,
      'summary':
          'Route complex reasoning to frontier models while funneling repetitive lookups and classification to ultra-low cost / local models.',
      'projected_monthly_spend': '\$68.40 / mo',
      'savings_percentage': '79.2% Savings',
      'tiers': [
        {
          'tier_name': 'Tier 1: Complex Synthesis & Reasoning',
          'model': 'claude-3-5-sonnet',
          'traffic_percent': 15,
          'role': 'Multi-step planning, intricate code refactoring, and root-cause analysis.',
        },
        {
          'tier_name': 'Tier 2: Standard RAG & Generation',
          'model': 'deepseek-chat',
          'traffic_percent': 65,
          'role': 'Query answer synthesis, summarization, and data translation.',
        },
        {
          'tier_name': 'Tier 3: Classification & Safety Triage',
          'model': 'llama3:8b (Ollama Local)',
          'traffic_percent': 20,
          'role': 'Intent detection, guardrails, sensitive PII scrubbing (Zero Cost).',
        },
      ],
      'budget_status': {
        'budget_limit': '\$${budget.toStringAsFixed(0)}',
        'projected_spend': '\$68.40',
        'status': 'within_budget',
        'recommendation': 'Projected monthly spend is well below your \$${budget.toStringAsFixed(0)} allocation.',
      },
    };

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({'success': true, 'recommendation': recommendation}),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. Custom GenUI Catalog Items
// ═══════════════════════════════════════════════════════════════

// --- A. Model Comparison Matrix ---
final modelComparisonSchema = S.object(
  description: 'Side-by-side comparison matrix of LLM models with dynamic rates and context windows.',
  properties: {
    'title': S.string(),
    'subtitle': S.string(),
    'models': S.list(
      items: S.object(
        properties: {
          'name': S.string(),
          'provider': S.string(),
          'input_price': S.string(),
          'output_price': S.string(),
          'context_window': S.string(),
          'badge': S.string(),
          'is_local': S.boolean(),
          'is_highlighted': S.boolean(),
        },
        required: ['name', 'provider', 'input_price', 'output_price'],
      ),
    ),
  },
  required: ['models'],
);

final modelComparisonItem = CatalogItem(
  name: 'ModelComparisonMatrix',
  dataSchema: modelComparisonSchema,
  widgetBuilder: (itemContext) => _ModelComparisonWidget(itemContext: itemContext),
);

class _ModelComparisonWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _ModelComparisonWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final title = data['title']?.toString() ?? 'Model Pricing & Context Matrix';
    final subtitle = data['subtitle']?.toString();
    final models = (data['models'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.currency_exchange, color: theme.colorScheme.onPrimaryContainer, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      if (subtitle != null)
                        Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: models.map((m) {
                final isLocal = m['is_local'] == true;
                final isHighlight = m['is_highlighted'] == true;
                final badge = m['badge']?.toString();
                final ctx = m['context_window']?.toString() ?? '128k';

                return SizedBox(
                  width: 260,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isHighlight
                          ? theme.colorScheme.primary.withValues(alpha: 0.08)
                          : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isHighlight
                            ? theme.colorScheme.primary
                            : isLocal
                                ? Colors.teal.withValues(alpha: 0.5)
                                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        width: isHighlight ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                m['name']?.toString() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (badge != null && badge.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isLocal ? Colors.teal : theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  badge,
                                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                m['provider']?.toString().toUpperCase() ?? 'PROVIDER',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.memory, size: 13, color: theme.colorScheme.outline),
                            const SizedBox(width: 4),
                            Text(
                              ctx,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Prompt / 1M:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              m['input_price']?.toString() ?? '',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Completion / 1M:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              m['output_price']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isLocal ? Colors.teal : theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// --- B. Cost Projection Chart ---
final costChartSchema = S.object(
  description: 'Interactive cost simulation curve comparing monthly expenditure across models.',
  properties: {
    'title': S.string(),
    'subtitle': S.string(),
    'currency': S.string(),
    'series': S.list(
      items: S.object(
        properties: {
          'model_name': S.string(),
          'color_hex': S.string(),
          'points': S.list(
            items: S.object(
              properties: {
                'requests': S.string(),
                'cost': S.number(),
              },
            ),
          ),
        },
        required: ['model_name', 'points'],
      ),
    ),
  },
  required: ['series'],
);

final costChartItem = CatalogItem(
  name: 'CostProjectionChart',
  dataSchema: costChartSchema,
  widgetBuilder: (itemContext) => _CostProjectionChartWidget(itemContext: itemContext),
);

class _CostProjectionChartWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _CostProjectionChartWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final title = data['title']?.toString() ?? 'Monthly Cost Scaling Projection';
    final subtitle = data['subtitle']?.toString();
    final currency = data['currency']?.toString() ?? '\$';
    final series = (data['series'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final theme = Theme.of(context);

    if (series.isEmpty) {
      return const SizedBox();
    }

    final firstPoints = (series.first['points'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final labels = firstPoints.map((p) => p['requests']?.toString() ?? '').toList();

    double maxVal = 10.0;
    final lineBarsData = <LineChartBarData>[];

    for (var i = 0; i < series.length; i++) {
      final s = series[i];
      final points = (s['points'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final hex = s['color_hex']?.toString().replaceAll('#', '');
      final color = hex != null && hex.length == 6
          ? Color(int.parse('FF$hex', radix: 16))
          : [Colors.indigo, Colors.amber, Colors.teal, Colors.red, Colors.purple][i % 5];

      final spots = <FlSpot>[];
      for (var idx = 0; idx < points.length; idx++) {
        final cost = (points[idx]['cost'] as num?)?.toDouble() ?? 0.0;
        if (cost > maxVal) maxVal = cost;
        spots.add(FlSpot(idx.toDouble(), cost));
      }

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: color,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: color.withValues(alpha: 0.1),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: series.map((s) {
                final hex = s['color_hex']?.toString().replaceAll('#', '');
                final color = hex != null && hex.length == 6
                    ? Color(int.parse('FF$hex', radix: 16))
                    : theme.colorScheme.primary;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(s['model_name']?.toString() ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxVal * 1.15,
                  lineBarsData: lineBarsData,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (val, meta) => Text(
                          '$currency${val.toInt()}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(labels[idx], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withValues(alpha: 0.15), strokeWidth: 1),
                  ),
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

// --- C. Model Routing Strategy Card ---
final modelRoutingSchema = S.object(
  description: 'Recommended multi-tiered LLM routing architecture with traffic allocation and projected savings.',
  properties: {
    'strategy_title': S.string(),
    'summary': S.string(),
    'projected_monthly_spend': S.string(),
    'savings_percentage': S.string(),
    'tiers': S.list(
      items: S.object(
        properties: {
          'tier_name': S.string(),
          'model': S.string(),
          'traffic_percent': S.integer(),
          'role': S.string(),
        },
        required: ['tier_name', 'model', 'traffic_percent'],
      ),
    ),
  },
  required: ['strategy_title', 'tiers'],
);

final modelRoutingItem = CatalogItem(
  name: 'ModelRoutingCard',
  dataSchema: modelRoutingSchema,
  widgetBuilder: (itemContext) => _ModelRoutingCardWidget(itemContext: itemContext),
);

class _ModelRoutingCardWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _ModelRoutingCardWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final title = data['strategy_title']?.toString() ?? 'Architecture Routing Recommendation';
    final summary = data['summary']?.toString();
    final spend = data['projected_monthly_spend']?.toString() ?? '';
    final savings = data['savings_percentage']?.toString() ?? '';
    final tiers = (data['tiers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.alt_route, color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (savings.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      savings,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            if (summary != null) ...[
              const SizedBox(height: 8),
              Text(summary, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Projected Blended Spend:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Text(spend, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('Traffic Allocation Tiers', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...tiers.map((t) {
              final pct = (t['traffic_percent'] as num?)?.toInt() ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t['tier_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('$pct% traffic', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100.0,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          pct >= 50 ? theme.colorScheme.primary : (pct >= 20 ? Colors.teal : Colors.orange),
                        ),
                        minHeight: 6,
                      ),
                    ),
                    if (t['role'] != null) ...[
                      const SizedBox(height: 2),
                      Text(t['role']!.toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// --- D. Budget Threshold Banner ---
final budgetBannerSchema = S.object(
  description: 'Budget advisory banner showing budget limit vs projected spend.',
  properties: {
    'budget_limit': S.string(),
    'projected_spend': S.string(),
    'status': S.string(),
    'recommendation': S.string(),
  },
  required: ['budget_limit', 'projected_spend', 'status', 'recommendation'],
);

final budgetBannerItem = CatalogItem(
  name: 'BudgetThresholdBanner',
  dataSchema: budgetBannerSchema,
  widgetBuilder: (itemContext) => _BudgetThresholdBannerWidget(itemContext: itemContext),
);

class _BudgetThresholdBannerWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _BudgetThresholdBannerWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final limit = data['budget_limit']?.toString() ?? '';
    final spend = data['projected_spend']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'within_budget';
    final rec = data['recommendation']?.toString() ?? '';

    final isOk = status == 'within_budget';
    final isWarn = status == 'warning';
    final color = isOk ? Colors.green : (isWarn ? Colors.orange : Colors.red);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isOk ? Icons.check_circle : (isWarn ? Icons.warning : Icons.error), color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Budget Status: $spend of $limit', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(rec, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 3. Screen Setup & System Prompt
// ═══════════════════════════════════════════════════════════════

const String modelOptimizerSystemPrompt = '''
You are an expert AI Cloud Architect and LLM Cost Governance Copilot.
Your objective is to help engineering teams analyze model pricing, simulate monthly token burn rates, and design cost-effective tiered routing architectures.

When the user asks about model costs, workload sizing, or LLM selection:
1. Invoke tools:
   - `query_model_pricing` to fetch dynamic rates and context windows.
   - `simulate_workload` to project monthly token costs across volume curves.
   - `recommend_model_routing` to design tiered multi-model architectures.
2. Render rich, interactive GenUI components:
   - "ModelComparisonMatrix" to display side-by-side rates, context limits, and local/cloud badges.
   - "CostProjectionChart" to render scaling curves across request volumes.
   - "ModelRoutingCard" to showcase tiered traffic allocation and percentage savings.
   - "BudgetThresholdBanner" for budget alerts and recommendations.
''';

class ModelOptimizerScreen extends StatelessWidget {
  const ModelOptimizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = BasicCatalogItems.asNoAssetCatalog().copyWith(
      newItems: [
        modelComparisonItem,
        costChartItem,
        modelRoutingItem,
        budgetBannerItem,
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
            Icon(Icons.query_stats, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'GenUI Model Cost & Architecture Optimizer',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: GenuiMcpPlayground(
        initialLlmConfig: initialLlm.provider != LlmProvider.none ? initialLlm : null,
        customLocalTools: [
          QueryModelPricingTool(),
          SimulateWorkloadTool(),
          RecommendRoutingTool(),
        ],
        initialEnabledTools: const [
          'query_model_pricing',
          'simulate_workload',
          'recommend_model_routing',
        ],
        initialSystemPrompt: modelOptimizerSystemPrompt,
        genuiCatalog: catalog,
        showAgentInspector: true,
      ),
    );
  }
}

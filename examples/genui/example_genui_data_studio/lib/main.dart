import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:genui_mcp_playground/genui_mcp_playground.dart';
import 'env_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const GenuiDataStudioApp());
}

class GenuiDataStudioApp extends StatelessWidget {
  const GenuiDataStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI Data Visualizer & Query Studio',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B64C5), // Fluent Pastel Iris
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9CA3F0), // Fluent Frosted Periwinkle
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      home: const DataStudioScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. Data Studio MCP Tools
// ═══════════════════════════════════════════════════════════════

class LoadDatasetTool extends McpLocalTool {
  @override
  String get name => 'load_dataset';

  @override
  String get description => 'Load analytical business dataset (monthly metrics, sales, or cohort data).';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'dataset_name': {'type': 'string', 'description': 'saas_growth, sales_pipeline, or ecommerce'},
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final dataset = {
      'name': 'SaaS Growth & Performance 2026',
      'kpis': [
        {'title': 'Annual Recurring Rev', 'value': '\$1.42M', 'change': '+18.4%', 'is_positive': true},
        {'title': 'Active Workspaces', 'value': '38,400', 'change': '+12.1%', 'is_positive': true},
        {'title': 'Net Revenue Churn', 'value': '1.8%', 'change': '-0.5%', 'is_positive': true},
        {'title': 'Avg LTV / CAC', 'value': '4.2x', 'change': '+0.3x', 'is_positive': true},
      ],
      'trend': [
        {'month': 'Jan', 'mrr': 105.0},
        {'month': 'Feb', 'mrr': 112.0},
        {'month': 'Mar', 'mrr': 118.0},
        {'month': 'Apr', 'mrr': 124.0},
        {'month': 'May', 'mrr': 131.0},
        {'month': 'Jun', 'mrr': 142.0},
      ],
      'rows': [
        {'Region': 'North America', 'Accounts': 18200, 'MRR': '\$68,400', 'Health': 'Healthy'},
        {'Region': 'Europe & UK', 'Accounts': 12400, 'MRR': '\$46,200', 'Health': 'Healthy'},
        {'Region': 'Asia-Pacific', 'Accounts': 5600, 'MRR': '\$19,800', 'Health': 'Neutral'},
        {'Region': 'Latin America', 'Accounts': 2200, 'MRR': '\$7,600', 'Health': 'At Risk'},
      ],
    };

    return MCPToolResult(
      content: [MCPContent(type: 'text', text: jsonEncode(dataset))],
    );
  }
}

class AggregateDataTool extends McpLocalTool {
  @override
  String get name => 'aggregate_data';

  @override
  String get description => 'Perform mathematical groupings, sums, and averages across metrics.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'metric': {'type': 'string'},
          'group_by': {'type': 'string'},
        },
        'required': ['metric'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({'success': true, 'aggregated_value': 142000, 'metric': arguments['metric']}),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. Custom GenUI Catalog Items
// ═══════════════════════════════════════════════════════════════

// --- A. Metric KPI Grid ---
final kpiGridSchema = S.object(
  description: 'Grid of executive KPI metric cards with trend indicators.',
  properties: {
    'kpis': S.list(
      items: S.object(
        properties: {
          'title': S.string(),
          'value': S.string(),
          'change': S.string(),
          'is_positive': S.boolean(),
        },
      ),
    ),
  },
  required: ['kpis'],
);

final kpiGridItem = CatalogItem(
  name: 'MetricKpiGrid',
  dataSchema: kpiGridSchema,
  widgetBuilder: (itemContext) => _MetricKpiGridWidget(itemContext: itemContext),
);

class _MetricKpiGridWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _MetricKpiGridWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final list = (data['kpis'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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
            Text('Key Performance Metrics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemBuilder: (context, i) {
                final kpi = list[i];
                final isPos = kpi['is_positive'] == true;
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(kpi['title']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(kpi['value']?.toString() ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            kpi['change']?.toString() ?? '',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPos ? Colors.green : Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- B. Interactive Data Table ---
final dataTableSchema = S.object(
  description: 'Interactive sortable data table for tabular data.',
  properties: {
    'title': S.string(),
    'columns': S.list(items: S.string()),
    'rows': S.list(items: S.object()),
  },
  required: ['columns', 'rows'],
);

final dataTableItem = CatalogItem(
  name: 'InteractiveDataTable',
  dataSchema: dataTableSchema,
  widgetBuilder: (itemContext) => _InteractiveDataTableWidget(itemContext: itemContext),
);

class _InteractiveDataTableWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _InteractiveDataTableWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final title = data['title']?.toString() ?? 'Dataset Table';
    final columns = (data['columns'] as List?)?.cast<String>() ?? [];
    final rows = (data['rows'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  for (final col in columns) DataColumn(label: Text(col, style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: [
                  for (final r in rows)
                    DataRow(
                      cells: [
                        for (final col in columns) DataCell(Text(r[col]?.toString() ?? '')),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- C. Metric Trend Chart ---
final trendChartSchema = S.object(
  description: 'Line chart showing metric trends over time.',
  properties: {
    'title': S.string(),
    'points': S.list(
      items: S.object(
        properties: {
          'label': S.string(),
          'value': S.number(),
        },
      ),
    ),
  },
  required: ['points'],
);

final trendChartItem = CatalogItem(
  name: 'TrendChart',
  dataSchema: trendChartSchema,
  widgetBuilder: (itemContext) => _TrendChartWidget(itemContext: itemContext),
);

class _TrendChartWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _TrendChartWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final title = data['title']?.toString() ?? 'Trend Analysis';
    final points = (data['points'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < points.length; i++)
                          FlSpot(i.toDouble(), (points[i]['value'] as num?)?.toDouble() ?? 0.0),
                      ],
                      isCurved: true,
                      color: const Color(0xFF6366F1),
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      ),
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
                          if (idx >= 0 && idx < points.length) {
                            return Text(points[idx]['label']?.toString() ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold));
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

const String dataStudioSystemPrompt = '''
You are a business intelligence and data visualization AI copilot.
When the user asks for growth analysis, performance reports, or data tables:
1. Invoke the tools: `load_dataset` or `aggregate_data`.
2. Generate interactive GenUI components:
   - "MetricKpiGrid" to summarize top-level performance:
     {"kpis": [{"title": "MRR", "value": "\$142K", "change": "+12%", "is_positive": true}]}
   - "InteractiveDataTable" for tabular breakdowns:
     {"title": "Regional Revenue", "columns": ["Region", "MRR"], "rows": [{"Region": "NA", "MRR": "\$68K"}]}
   - "TrendChart" for time series curves:
     {"title": "Monthly Growth", "points": [{"label": "Jan", "value": 105}, {"label": "Feb", "value": 112}]}
''';

class DataStudioScreen extends StatelessWidget {
  const DataStudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = BasicCatalogItems.asNoAssetCatalog().copyWith(
      newItems: [kpiGridItem, dataTableItem, trendChartItem],
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
            Icon(Icons.analytics, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('GenUI Data Visualizer Studio'),
          ],
        ),
      ),
      body: GenuiMcpPlayground(
        initialLlmConfig: initialLlm.provider != LlmProvider.none ? initialLlm : null,
        customLocalTools: [LoadDatasetTool(), AggregateDataTool()],
        initialEnabledTools: const ['load_dataset', 'aggregate_data'],
        initialSystemPrompt: dataStudioSystemPrompt,
        genuiCatalog: catalog,
        showAgentInspector: true,
      ),
    );
  }
}

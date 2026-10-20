import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_genui_mcp/flutter_genui_mcp.dart';
import 'env_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const GenuiFileEtlApp());
}

class GenuiFileEtlApp extends StatelessWidget {
  const GenuiFileEtlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI File ETL & Data Transformation Studio',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488), // Deep Teal / Data Pipeline
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2DD4BF),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      home: const FileEtlScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. Data ETL MCP Tools
// ═══════════════════════════════════════════════════════════════

class InspectDatasetTool extends McpLocalTool {
  @override
  String get name => 'inspect_dataset';

  @override
  String get description =>
      'Read and inspect raw attached CSV/JSON file structure, detecting headers, data types, missing values, and token footprints.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'dataset_name': {
            'type': 'string',
            'description': 'Name of the dataset (e.g. sample_customer_orders.csv)',
          },
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    String csvContent;
    try {
      csvContent = await rootBundle.loadString('assets/sample_customer_orders.csv');
    } catch (_) {
      csvContent = '''order_id,customer_name,company,country,product_tier,order_value_usd,payment_status,order_date
ORD-1092,Elena Rostova,AeroDynamics GmbH,Germany,Enterprise,14500.00,Paid,2026-09-14
ORD-1093,Marcus Sterling,Vanguard Capital,United Kingdom,Enterprise,28000.00,Paid,2026-09-15
ORD-1094,Kenji Sato,Sakura AI Tech,Japan,Pro,4200.00,Paid,2026-09-18
ORD-1095,Chloe Martin,Lumiere Studio,France,Starter,850.00,Pending,2026-09-20''';
    }

    final lines = csvContent.trim().split('\n');
    final header = lines.first.split(',').map((h) => h.trim()).toList();
    final rowCount = lines.length - 1;

    final columnsInfo = [
      {'name': 'order_id', 'type': 'String (ID)', 'null_percentage': '0%', 'sample': 'ORD-1092'},
      {'name': 'customer_name', 'type': 'String', 'null_percentage': '0%', 'sample': 'Elena Rostova'},
      {'name': 'company', 'type': 'String', 'null_percentage': '0%', 'sample': 'AeroDynamics GmbH'},
      {'name': 'country', 'type': 'String', 'null_percentage': '0%', 'sample': 'Germany'},
      {'name': 'product_tier', 'type': 'Enum (Enterprise, Pro, Starter)', 'null_percentage': '0%', 'sample': 'Enterprise'},
      {'name': 'order_value_usd', 'type': 'Float / Numeric', 'null_percentage': '0%', 'sample': '14500.00'},
      {'name': 'payment_status', 'type': 'Enum (Paid, Pending, Cancelled)', 'null_percentage': '0%', 'sample': 'Paid'},
      {'name': 'order_date', 'type': 'Date (ISO-8601)', 'null_percentage': '0%', 'sample': '2026-09-14'},
    ];

    final summary = {
      'file_name': 'sample_customer_orders.csv',
      'total_rows': rowCount,
      'total_columns': header.length,
      'encoding': 'UTF-8 (allowMalformed: true)',
      'delimiter': ',',
      'token_estimate': (csvContent.length / 3.8).round(),
      'columns': columnsInfo,
    };

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({'success': true, 'dataset_summary': summary}),
        ),
      ],
    );
  }
}

class TransformDatasetTool extends McpLocalTool {
  @override
  String get name => 'transform_dataset';

  @override
  String get description =>
      'Apply schema transformations, filters (e.g. status == Paid), column renaming, or column deletions to raw records.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'filter_condition': {'type': 'string', 'description': 'Filter e.g. "order_value_usd >= 4000 AND payment_status == Paid"'},
          'drop_columns': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Columns to exclude from output',
          },
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final condition = arguments['filter_condition']?.toString() ?? 'High Value Orders (>= \$4,000)';

    final transformedRows = [
      {'ID': 'ORD-1092', 'Company': 'AeroDynamics GmbH', 'Tier': 'Enterprise', 'Revenue': '\$14,500', 'Country': 'Germany'},
      {'ID': 'ORD-1093', 'Company': 'Vanguard Capital', 'Tier': 'Enterprise', 'Revenue': '\$28,000', 'Country': 'United Kingdom'},
      {'ID': 'ORD-1094', 'Company': 'Sakura AI Tech', 'Tier': 'Pro', 'Revenue': '\$4,200', 'Country': 'Japan'},
      {'ID': 'ORD-1097', 'Company': 'Solaria Energy', 'Tier': 'Enterprise', 'Revenue': '\$19,200', 'Country': 'Spain'},
      {'ID': 'ORD-1098', 'Company': 'Nordic Data Labs', 'Tier': 'Enterprise', 'Revenue': '\$32,000', 'Country': 'Sweden'},
      {'ID': 'ORD-1100', 'Company': 'Nile FinTech', 'Tier': 'Pro', 'Revenue': '\$5,400', 'Country': 'Egypt'},
      {'ID': 'ORD-1101', 'Company': 'Amazonas AI', 'Tier': 'Pro', 'Revenue': '\$4,800', 'Country': 'Brazil'},
    ];

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({
            'success': true,
            'filter_applied': condition,
            'retained_rows': transformedRows.length,
            'columns': ['ID', 'Company', 'Tier', 'Revenue', 'Country'],
            'rows': transformedRows,
          }),
        ),
      ],
    );
  }
}

class ExportDatasetTool extends McpLocalTool {
  @override
  String get name => 'export_dataset';

  @override
  String get description => 'Export cleaned and transformed dataset to CSV, SQL schema, or Dart Model code.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'target_format': {'type': 'string', 'description': 'csv, sql, or dart_model'},
        },
        'required': ['target_format'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final format = arguments['target_format']?.toString().toLowerCase() ?? 'csv';

    String snippet;
    if (format == 'dart_model') {
      snippet = '''class CleanOrderRecord {
  final String id;
  final String company;
  final String tier;
  final double revenue;
  final String country;

  const CleanOrderRecord({required this.id, required this.company, required this.tier, required this.revenue, required this.country});
}''';
    } else if (format == 'sql') {
      snippet = '''CREATE TABLE enterprise_orders (
  id VARCHAR(32) PRIMARY KEY,
  company VARCHAR(128) NOT NULL,
  tier VARCHAR(32),
  revenue DECIMAL(12,2),
  country VARCHAR(64)
);''';
    } else {
      snippet = '''ID,Company,Tier,Revenue,Country
ORD-1092,AeroDynamics GmbH,Enterprise,14500.00,Germany
ORD-1093,Vanguard Capital,Enterprise,28000.00,United Kingdom
ORD-1097,Solaria Energy,Enterprise,19200.00,Spain''';
    }

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({
            'success': true,
            'format': format,
            'payload': snippet,
          }),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. Custom GenUI Catalog Items
// ═══════════════════════════════════════════════════════════════

// --- A. Dataset Summary Card ---
final datasetSummarySchema = S.object(
  description: 'Metadata card summarizing file size, row/column counts, encoding, and prompt token metrics.',
  properties: {
    'file_name': S.string(),
    'total_rows': S.integer(),
    'total_columns': S.integer(),
    'encoding': S.string(),
    'token_estimate': S.integer(),
  },
  required: ['file_name', 'total_rows', 'total_columns'],
);

final datasetSummaryItem = CatalogItem(
  name: 'DatasetSummaryCard',
  dataSchema: datasetSummarySchema,
  widgetBuilder: (itemContext) => _DatasetSummaryCardWidget(itemContext: itemContext),
);

class _DatasetSummaryCardWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _DatasetSummaryCardWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final file = data['file_name']?.toString() ?? 'dataset.csv';
    final rows = data['total_rows']?.toString() ?? '0';
    final cols = data['total_columns']?.toString() ?? '0';
    final enc = data['encoding']?.toString() ?? 'UTF-8';
    final tokens = data['token_estimate']?.toString() ?? '0';
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.teal.withValues(alpha: 0.3)),
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
                    color: Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.file_present, color: Colors.teal, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(file, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('$enc • Delimited Format', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '~$tokens ctx tokens',
                    style: const TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
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
                        const Text('Total Records', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text('$rows rows', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                        const Text('Feature Columns', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text('$cols attributes', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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

// --- B. Schema Transformer Widget ---
final schemaTransformerSchema = S.object(
  description: 'Schema attribute inspector showing columns, detected data types, and null ratios.',
  properties: {
    'title': S.string(),
    'attributes': S.list(
      items: S.object(
        properties: {
          'name': S.string(),
          'type': S.string(),
          'null_percentage': S.string(),
          'sample': S.string(),
        },
        required: ['name', 'type'],
      ),
    ),
  },
  required: ['attributes'],
);

final schemaTransformerItem = CatalogItem(
  name: 'SchemaTransformerWidget',
  dataSchema: schemaTransformerSchema,
  widgetBuilder: (itemContext) => _SchemaTransformerWidget(itemContext: itemContext),
);

class _SchemaTransformerWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _SchemaTransformerWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final title = data['title']?.toString() ?? 'Detected Schema & Attribute Definitions';
    final attrs = (data['attributes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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
                const Icon(Icons.schema, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...attrs.map((a) {
              final name = a['name']?.toString() ?? '';
              final type = a['type']?.toString() ?? 'String';
              final sample = a['sample']?.toString() ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(type, style: TextStyle(color: theme.colorScheme.primary, fontSize: 11)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(sample, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
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

// --- C. Data Preview Table ---
final dataPreviewSchema = S.object(
  description: 'Interactive table showing transformed and filtered dataset rows.',
  properties: {
    'title': S.string(),
    'columns': S.list(items: S.string()),
    'rows': S.list(items: S.object()),
  },
  required: ['columns', 'rows'],
);

final dataPreviewItem = CatalogItem(
  name: 'DataPreviewTable',
  dataSchema: dataPreviewSchema,
  widgetBuilder: (itemContext) => _DataPreviewTableWidget(itemContext: itemContext),
);

class _DataPreviewTableWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _DataPreviewTableWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final title = data['title']?.toString() ?? 'Filtered Dataset View';
    final columns = (data['columns'] as List?)?.cast<String>() ?? [];
    final rows = (data['rows'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.table_chart, color: Colors.teal, size: 20),
                    const SizedBox(width: 8),
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${rows.length} Records', style: const TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                columnSpacing: 18,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 44,
                columns: columns
                    .map((col) => DataColumn(
                          label: Text(col, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ))
                    .toList(),
                rows: rows.map((r) {
                  return DataRow(
                    cells: columns.map((col) {
                      return DataCell(
                        Text(r[col]?.toString() ?? '', style: const TextStyle(fontSize: 11)),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- D. Export Pipeline Card ---
final exportPipelineSchema = S.object(
  description: 'Interactive export card with code snippets and download actions.',
  properties: {
    'format': S.string(),
    'code_snippet': S.string(),
    'record_count': S.integer(),
  },
  required: ['format', 'code_snippet'],
);

final exportPipelineItem = CatalogItem(
  name: 'ExportPipelineCard',
  dataSchema: exportPipelineSchema,
  widgetBuilder: (itemContext) => _ExportPipelineCardWidget(itemContext: itemContext),
);

class _ExportPipelineCardWidget extends StatefulWidget {
  final CatalogItemContext itemContext;
  const _ExportPipelineCardWidget({required this.itemContext});

  @override
  State<_ExportPipelineCardWidget> createState() => _ExportPipelineCardWidgetState();
}

class _ExportPipelineCardWidgetState extends State<_ExportPipelineCardWidget> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.itemContext.data as Map<String, dynamic>? ?? {};
    final format = data['format']?.toString().toUpperCase() ?? 'CSV';
    final code = data['code_snippet']?.toString() ?? '';
    final count = data['record_count']?.toString() ?? 'All';
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.teal.withValues(alpha: 0.4)),
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
                    const Icon(Icons.file_download, color: Colors.teal, size: 20),
                    const SizedBox(width: 8),
                    Text('Pipeline Deliverable ($format)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                Text('$count Exported', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  code,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  setState(() => _copied = true);
                },
                icon: Icon(_copied ? Icons.check : Icons.copy, size: 16),
                label: Text(_copied ? 'Copied to Clipboard' : 'Copy $format Artifact'),
                style: FilledButton.styleFrom(backgroundColor: Colors.teal),
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

const String fileEtlSystemPrompt = '''
You are an expert Data Wrangling and ETL Pipeline AI Copilot.
When the user attaches or queries CSV or JSON data files:
1. Invoke tools:
   - `inspect_dataset` to examine metadata, row counts, schema, and token requirements.
   - `transform_dataset` to apply filters, column drops, and type transformations.
   - `export_dataset` to generate clean CSV, SQL schemas, or Dart model classes.
2. Render rich, interactive GenUI components:
   - "DatasetSummaryCard" to summarize file metadata and token context sizes.
   - "SchemaTransformerWidget" to display data types and null ratios.
   - "DataPreviewTable" to render paginated preview rows.
   - "ExportPipelineCard" to provide copyable deliverables.
''';

class FileEtlScreen extends StatelessWidget {
  const FileEtlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = BasicCatalogItems.asNoAssetCatalog().copyWith(
      newItems: [
        datasetSummaryItem,
        schemaTransformerItem,
        dataPreviewItem,
        exportPipelineItem,
      ],
    );

    final initialLlm = LlmConfig(
      provider: EnvLoader.getProvider(),
      model: EnvLoader.get('LLM_MODEL', defaultValue: 'gemini-3.7-flash'),
      apiKey: EnvLoader.get('LLM_API_KEY'),
      baseUrl: EnvLoader.get('LLM_URL'),
    );

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.transform, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'GenUI File ETL & Data Transformation Studio',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: GenuiMcpPlayground(
        initialLlmConfig: initialLlm.provider != LlmProvider.none ? initialLlm : null,
        customLocalTools: [
          InspectDatasetTool(),
          TransformDatasetTool(),
          ExportDatasetTool(),
        ],
        initialEnabledTools: const [
          'inspect_dataset',
          'transform_dataset',
          'export_dataset',
        ],
        initialSystemPrompt: fileEtlSystemPrompt,
        genuiCatalog: catalog,
        showAgentInspector: true,
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:genui_mcp_playground/genui_mcp_playground.dart';
import 'env_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const GenuiFinanceApp());
}

class GenuiFinanceApp extends StatelessWidget {
  const GenuiFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI Personal Finance & Budget Planner',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF489E78), // Fluent Pastel Sage Green
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF86D5AD), // Fluent Frosted Mint Green
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
        ),
      ),
      home: const FinanceScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. Finance MCP Tools
// ═══════════════════════════════════════════════════════════════

class GetMonthlyExpensesTool extends McpLocalTool {
  @override
  String get name => 'get_monthly_expenses';

  @override
  String get description => 'Get monthly breakdown of expenses by category (Housing, Food, Transit, Leisure).';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {},
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final expenses = {
      'income': 5400.0,
      'total_expenses': 3650.0,
      'categories': [
        {'name': 'Housing', 'amount': 1800.0, 'color': '#3B82F6'},
        {'name': 'Groceries & Dining', 'amount': 850.0, 'color': '#10B981'},
        {'name': 'Transportation', 'amount': 400.0, 'color': '#F59E0B'},
        {'name': 'Leisure & Subs', 'amount': 350.0, 'color': '#8B5CF6'},
        {'name': 'Utilities & Health', 'amount': 250.0, 'color': '#EC4899'},
      ],
    };
    return MCPToolResult(
      content: [MCPContent(type: 'text', text: jsonEncode(expenses))],
    );
  }
}

class CalculateBudgetSavingsTool extends McpLocalTool {
  @override
  String get name => 'calculate_budget_savings';

  @override
  String get description => 'Calculate projected annual savings based on monthly income and expense adjustments.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'monthly_income': {'type': 'number'},
          'monthly_expenses': {'type': 'number'},
        },
        'required': ['monthly_income', 'monthly_expenses'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final income = (arguments['monthly_income'] as num).toDouble();
    final expenses = (arguments['monthly_expenses'] as num).toDouble();
    final monthlySavings = (income - expenses).clamp(0.0, double.infinity);
    final annualSavings = monthlySavings * 12;

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({
            'monthly_savings': monthlySavings,
            'annual_savings': annualSavings,
            'savings_rate_percent': ((monthlySavings / income) * 100).toStringAsFixed(1),
          }),
        ),
      ],
    );
  }
}

class SimulateInvestmentGrowthTool extends McpLocalTool {
  @override
  String get name => 'simulate_investment_growth';

  @override
  String get description => 'Simulate compound interest returns over 1, 3, 5, and 10 years.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'monthly_contribution': {'type': 'number'},
          'annual_interest_rate': {'type': 'number', 'description': 'e.g. 0.08 for 8%'},
        },
        'required': ['monthly_contribution'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final pmt = (arguments['monthly_contribution'] as num).toDouble();
    final rate = (arguments['annual_interest_rate'] as num?)?.toDouble() ?? 0.07;
    final r = rate / 12;

    double fv(int years) {
      final n = years * 12;
      var total = 0.0;
      for (var i = 0; i < n; i++) {
        total = (total + pmt) * (1 + r);
      }
      return total;
    }

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({
            '1_year': fv(1).round(),
            '3_years': fv(3).round(),
            '5_years': fv(5).round(),
            '10_years': fv(10).round(),
          }),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. Custom GenUI Catalog Items
// ═══════════════════════════════════════════════════════════════

// --- A. Expense Pie Chart Widget ---
final expensePieSchema = S.object(
  description: 'Interactive pie chart showing category breakdown of expenses.',
  properties: {
    'total_expenses': S.number(),
    'categories': S.list(
      items: S.object(
        properties: {
          'name': S.string(),
          'amount': S.number(),
        },
      ),
    ),
  },
  required: ['categories'],
);

final expensePieItem = CatalogItem(
  name: 'ExpensePieChart',
  dataSchema: expensePieSchema,
  widgetBuilder: (itemContext) => _ExpensePieWidget(itemContext: itemContext),
);

class _ExpensePieWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _ExpensePieWidget({required this.itemContext});

  static const List<Color> _colors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    final data = itemContext.data as Map<String, dynamic>? ?? {};
    final list = (data['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final total = (data['total_expenses'] as num?)?.toDouble() ?? 0.0;
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Monthly Expenses', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text('\$${total.toStringAsFixed(0)} / mo', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  sections: [
                    for (var i = 0; i < list.length; i++)
                      PieChartSectionData(
                        value: (list[i]['amount'] as num?)?.toDouble() ?? 1.0,
                        title: '\$${(list[i]['amount'] as num?)?.toInt() ?? 0}',
                        color: _colors[i % _colors.length],
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (var i = 0; i < list.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: _colors[i % _colors.length], shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(list[i]['name']?.toString() ?? '', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- B. Interactive Budget Slider Card ---
final budgetSliderSchema = S.object(
  description: 'Interactive budget adjustment sliders with live savings calculation.',
  properties: {
    'monthly_income': S.number(),
    'categories': S.list(
      items: S.object(
        properties: {
          'name': S.string(),
          'amount': S.number(),
          'max_amount': S.number(),
        },
      ),
    ),
  },
  required: ['monthly_income', 'categories'],
);

final budgetSliderItem = CatalogItem(
  name: 'BudgetSliders',
  dataSchema: budgetSliderSchema,
  widgetBuilder: (itemContext) => _BudgetSlidersWidget(itemContext: itemContext),
);

class _BudgetSlidersWidget extends StatefulWidget {
  final CatalogItemContext itemContext;
  const _BudgetSlidersWidget({required this.itemContext});

  @override
  State<_BudgetSlidersWidget> createState() => _BudgetSlidersWidgetState();
}

class _BudgetSlidersWidgetState extends State<_BudgetSlidersWidget> {
  final Map<String, double> _currentAmounts = {};
  double _income = 5400.0;

  @override
  void initState() {
    super.initState();
    final data = widget.itemContext.data as Map<String, dynamic>? ?? {};
    _income = (data['monthly_income'] as num?)?.toDouble() ?? 5400.0;
    final list = (data['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final c in list) {
      final name = c['name']?.toString() ?? '';
      _currentAmounts[name] = (c['amount'] as num?)?.toDouble() ?? 300.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.itemContext.data as Map<String, dynamic>? ?? {};
    final list = (data['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final theme = Theme.of(context);

    final totalExpenses = _currentAmounts.values.fold(0.0, (a, b) => a + b);
    final remainingSavings = (_income - totalExpenses).clamp(0.0, double.infinity);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Interactive Budget Adjuster', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Adjust categories to optimize savings', style: theme.textTheme.bodySmall),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Text('+\$${remainingSavings.toStringAsFixed(0)} saved', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24),
            for (final cat in list) ...[
              _buildSliderRow(cat),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow(Map<String, dynamic> cat) {
    final name = cat['name']?.toString() ?? 'Category';
    final max = (cat['max_amount'] as num?)?.toDouble() ?? 2000.0;
    final val = _currentAmounts[name] ?? 300.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('\$${val.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: val.clamp(0.0, max),
          min: 0.0,
          max: max,
          divisions: (max / 50).round().clamp(5, 100),
          onChanged: (newVal) {
            setState(() => _currentAmounts[name] = newVal);
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 3. Screen Setup
// ═══════════════════════════════════════════════════════════════

const String financeSystemPrompt = '''
You are an expert personal finance and investment AI advisor.
When the user asks for budget reviews, spending analysis, or investment projections:
1. Invoke the tools: `get_monthly_expenses`, `calculate_budget_savings`, or `simulate_investment_growth`.
2. Generate interactive GenUI components:
   - "ExpensePieChart" to visualize current expenses:
     {"total_expenses": 3650.0, "categories": [{"name": "Housing", "amount": 1800.0}, {"name": "Groceries", "amount": 850.0}]}
   - "BudgetSliders" for interactive budget planning:
     {"monthly_income": 5400.0, "categories": [{"name": "Groceries", "amount": 850.0, "max_amount": 1500.0}]}
''';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = BasicCatalogItems.asNoAssetCatalog().copyWith(
      newItems: [expensePieItem, budgetSliderItem],
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
            Icon(Icons.savings, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('GenUI Budget & Portfolio Studio'),
          ],
        ),
      ),
      body: GenuiMcpPlayground(
        initialLlmConfig: initialLlm.provider != LlmProvider.none ? initialLlm : null,
        customLocalTools: [
          GetMonthlyExpensesTool(),
          CalculateBudgetSavingsTool(),
          SimulateInvestmentGrowthTool(),
        ],
        initialEnabledTools: const [
          'get_monthly_expenses',
          'calculate_budget_savings',
          'simulate_investment_growth',
        ],
        initialSystemPrompt: financeSystemPrompt,
        genuiCatalog: catalog,
        showAgentInspector: true,
      ),
    );
  }
}

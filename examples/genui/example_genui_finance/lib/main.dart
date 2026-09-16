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
// 1. Finance GenUI Client-Side Functions
// Reference: https://flutter.dev/blog/a2ui-client-side-functions
// ═══════════════════════════════════════════════════════════════

/// Deterministically fetches the monthly breakdown of spending and income.
class GetMonthlyExpensesFunction extends SynchronousClientFunction {
  const GetMonthlyExpensesFunction();

  @override
  String get name => 'getMonthlyExpenses';

  @override
  String get description =>
      'Returns a deterministic breakdown of monthly expenses by category (Housing, Groceries, Transit, Leisure, Utilities) and total monthly income.';

  @override
  ClientFunctionReturnType get returnType => ClientFunctionReturnType.object;

  @override
  Schema get argumentSchema => S.object(properties: {});

  @override
  Object? executeSync(JsonMap args, ExecutionContext _) {
    return {
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
  }
}

/// Deterministically calculates monthly and annual savings and savings rate.
class CalculateBudgetSavingsFunction extends SynchronousClientFunction {
  const CalculateBudgetSavingsFunction();

  @override
  String get name => 'calculateBudgetSavings';

  @override
  String get description =>
      'Calculates projected annual and monthly savings and savings rate based on monthly income and expense adjustments.';

  @override
  ClientFunctionReturnType get returnType => ClientFunctionReturnType.object;

  @override
  Schema get argumentSchema => S.object(
        properties: {
          'monthly_income': S.number(description: 'Gross monthly income'),
          'monthly_expenses': S.number(description: 'Total monthly expenses'),
        },
        required: ['monthly_income', 'monthly_expenses'],
      );

  @override
  Object? executeSync(JsonMap args, ExecutionContext _) {
    final income = (args['monthly_income'] as num?)?.toDouble() ?? 0.0;
    final expenses = (args['monthly_expenses'] as num?)?.toDouble() ?? 0.0;
    final monthlySavings = (income - expenses).clamp(0.0, double.infinity);
    final annualSavings = monthlySavings * 12;
    final savingsRate = income > 0 ? (monthlySavings / income) * 100 : 0.0;

    return {
      'monthly_savings': monthlySavings,
      'annual_savings': annualSavings,
      'savings_rate_percent': savingsRate.toStringAsFixed(1),
    };
  }
}

/// Deterministically computes compound investment projections.
class SimulateInvestmentGrowthFunction extends SynchronousClientFunction {
  const SimulateInvestmentGrowthFunction();

  @override
  String get name => 'simulateInvestmentGrowth';

  @override
  String get description =>
      'Simulates deterministic compound interest returns over 1, 3, 5, and 10 years for regular monthly contributions. Can also return a single year projection if "years" is provided.';

  @override
  ClientFunctionReturnType get returnType => ClientFunctionReturnType.any;

  @override
  Schema get argumentSchema => S.object(
        properties: {
          'monthly_contribution': S.number(description: 'Monthly contribution amount'),
          'annual_interest_rate': S.number(
            description: 'Annual interest rate (e.g. 0.075 for 7.5%)',
          ),
          'years': S.number(
            description: 'Optional number of years to project (e.g. 1, 3, 5, 10)',
          ),
        },
        required: ['monthly_contribution'],
      );

  @override
  Object? executeSync(JsonMap args, ExecutionContext _) {
    final rawPmt = args['monthly_contribution'] ??
        args['monthlyContribution'] ??
        args['contribution'] ??
        args['amount'];
    final pmt = (rawPmt is num ? rawPmt.toDouble() : null) ??
        (double.tryParse(rawPmt?.toString() ?? '') ?? 450.0);

    final rawRate = args['annual_interest_rate'] ??
        args['annualInterestRate'] ??
        args['annual_return'] ??
        args['interest_rate'] ??
        args['rate'];
    double rate = 0.075;
    if (rawRate is num) {
      rate = rawRate.toDouble();
      if (rate > 1.0) rate = rate / 100.0;
    } else if (rawRate is String) {
      final parsed = double.tryParse(rawRate.replaceAll('%', '').trim());
      if (parsed != null) {
        rate = parsed > 1.0 ? parsed / 100.0 : parsed;
      }
    }

    final r = rate / 12;

    double fv(int years) {
      final n = years * 12;
      var total = 0.0;
      for (var i = 0; i < n; i++) {
        total = (total + pmt) * (1 + r);
      }
      return total;
    }

    String fmt(num val) {
      final str = val.round().toString();
      return '\$${str.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }

    final reqYears = (args['years'] as num?)?.toInt();
    if (reqYears != null) {
      return fmt(fv(reqYears));
    }

    final fv1 = fv(1).round();
    final fv3 = fv(3).round();
    final fv5 = fv(5).round();
    final fv10 = fv(10).round();

    return {
      'monthly_contribution': pmt,
      'annual_interest_rate': rate,
      '1_year': fv1,
      '3_years': fv3,
      '5_years': fv5,
      '10_years': fv10,
      '1_year_formatted': fmt(fv1),
      '3_years_formatted': fmt(fv3),
      '5_years_formatted': fmt(fv5),
      '10_years_formatted': fmt(fv10),
      'projections': [
        {'years': 1, 'amount': fv1, 'formatted': fmt(fv1)},
        {'years': 3, 'amount': fv3, 'formatted': fmt(fv3)},
        {'years': 5, 'amount': fv5, 'formatted': fmt(fv5)},
        {'years': 10, 'amount': fv10, 'formatted': fmt(fv10)},
      ],
    };
  }
}

const financeClientFunctions = <ClientFunction>[
  GetMonthlyExpensesFunction(),
  CalculateBudgetSavingsFunction(),
  SimulateInvestmentGrowthFunction(),
];

// ═══════════════════════════════════════════════════════════════
// 2. Custom GenUI Catalog Items
// ═══════════════════════════════════════════════════════════════

final ExecutionContext _fallbackContext =
    DataContext(InMemoryDataModel(), DataPath('/'));

dynamic _resolveCall(dynamic raw, [ExecutionContext? context]) {
  if (raw == null) return null;
  if (raw is Map) {
    if (raw.containsKey('call')) {
      final funcName = raw['call']?.toString() ?? '';
      final rawArgs = raw['args'];
      final args = rawArgs is Map ? Map<String, dynamic>.from(rawArgs) : <String, dynamic>{};
      for (final func in financeClientFunctions) {
        if (func.name.toLowerCase() == funcName.toLowerCase().replaceAll('_', '')) {
          if (func is SynchronousClientFunction) {
            try {
              return func.executeSync(args, context ?? _fallbackContext);
            } catch (_) {}
          }
        }
      }
    }
    final newMap = <String, dynamic>{};
    for (final entry in raw.entries) {
      newMap[entry.key.toString()] = _resolveCall(entry.value, context);
    }
    return newMap;
  }
  if (raw is List) {
    return raw.map((item) => _resolveCall(item, context)).toList();
  }
  return raw;
}


List<Map<String, dynamic>> _extractCategories(dynamic raw) {
  if (raw == null) return const [];
  raw = _resolveCall(raw);

  if (raw is List) {
    final result = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        final name = m['name']?.toString() ?? m['category']?.toString() ?? '';
        final amount = (m['amount'] ?? m['value'] ?? m['cost'] as num?)?.toDouble() ?? 0.0;
        final maxAmount = (m['max_amount'] ?? m['maxAmount'] ?? m['max'] as num?)?.toDouble();
        final itemMap = <String, dynamic>{
          'name': name,
          'amount': amount,
        };
        if (m.containsKey('color')) itemMap['color'] = m['color'];
        if (maxAmount != null) itemMap['max_amount'] = maxAmount;
        result.add(itemMap);
      }
    }
    return result;
  }

  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    if (map.containsKey('categories')) {
      return _extractCategories(map['categories']);
    }

    final result = <Map<String, dynamic>>[];
    for (final entry in map.entries) {
      if (entry.key == 'total_expenses' || entry.key == 'totalExpenses' || entry.key == 'income') {
        continue;
      }
      if (entry.value is num) {
        result.add({
          'name': entry.key,
          'amount': (entry.value as num).toDouble(),
        });
      } else if (entry.value is Map) {
        final valMap = Map<String, dynamic>.from(entry.value as Map);
        final itemMap = <String, dynamic>{
          'name': valMap['name']?.toString() ?? entry.key,
          'amount': (valMap['amount'] as num?)?.toDouble() ?? 0.0,
        };
        if (valMap.containsKey('color')) itemMap['color'] = valMap['color'];
        if (valMap['max_amount'] != null) {
          itemMap['max_amount'] = (valMap['max_amount'] as num).toDouble();
        }
        result.add(itemMap);
      }
    }
    return result;
  }

  return const [];
}

double _extractTotalExpenses(dynamic rawData, List<Map<String, dynamic>> categories) {
  rawData = _resolveCall(rawData);
  if (rawData is Map) {
    final map = Map<String, dynamic>.from(rawData);
    final rawTotal = map['total_expenses'] ?? map['totalExpenses'] ?? map['total'];
    if (rawTotal is num) return rawTotal.toDouble();
    if (rawTotal is String) {
      final parsed = double.tryParse(rawTotal.replaceAll(RegExp(r'[^\d.]'), ''));
      if (parsed != null) return parsed;
    }
    if (map['categories'] is Map) {
      final nested = Map<String, dynamic>.from(map['categories'] as Map);
      final nestedTotal = nested['total_expenses'] ?? nested['totalExpenses'];
      if (nestedTotal is num) return nestedTotal.toDouble();
    }
  }

  return categories.fold<double>(
    0.0,
    (sum, cat) => sum + ((cat['amount'] as num?)?.toDouble() ?? 0.0),
  );
}

double _extractIncome(dynamic rawData) {
  rawData = _resolveCall(rawData);
  if (rawData is Map) {
    final map = Map<String, dynamic>.from(rawData);
    final raw = map['monthly_income'] ?? map['monthlyIncome'] ?? map['income'];
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      final parsed = double.tryParse(raw.replaceAll(RegExp(r'[^\d.]'), ''));
      if (parsed != null) return parsed;
    }
    if (map['categories'] is Map) {
      final nested = Map<String, dynamic>.from(map['categories'] as Map);
      final nestedIncome = nested['income'] ?? nested['monthly_income'];
      if (nestedIncome is num) return nestedIncome.toDouble();
    }
  }
  return 5400.0;
}

// --- A. Expense Pie Chart Widget ---
final expensePieSchema = S.object(
  description: 'Interactive pie chart showing category breakdown of expenses.',
  properties: {
    'total_expenses': S.number(description: 'Total monthly expenses'),
    'categories': S.any(description: 'List of categories with name and amount, or map of category names to amounts'),
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
    final rawData = _resolveCall(itemContext.data, itemContext.dataContext);
    var list = _extractCategories(
      rawData is Map ? (rawData['categories'] ?? rawData) : rawData,
    );
    var total = _extractTotalExpenses(rawData, list);

    if (list.isEmpty) {
      final defaultExpenses = const GetMonthlyExpensesFunction().executeSync(const {}, _fallbackContext) as Map<String, dynamic>;
      list = _extractCategories(defaultExpenses['categories']);
      total = (defaultExpenses['total_expenses'] as num).toDouble();
    }

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
                        value: ((list[i]['amount'] as num?)?.toDouble() ?? 1.0).clamp(0.01, double.infinity),
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
    'monthly_income': S.number(description: 'Gross monthly income'),
    'categories': S.any(description: 'List or map of budget categories with spending amounts'),
  },
  required: ['categories'],
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
    _extractData();
  }

  @override
  void didUpdateWidget(covariant _BudgetSlidersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemContext.data != widget.itemContext.data) {
      _extractData();
    }
  }

  void _extractData() {
    final rawData = _resolveCall(widget.itemContext.data, widget.itemContext.dataContext);
    _income = _extractIncome(rawData);
    var list = _extractCategories(
      rawData is Map ? (rawData['categories'] ?? rawData) : rawData,
    );
    if (list.isEmpty) {
      final defaultExpenses = const GetMonthlyExpensesFunction().executeSync(const {}, _fallbackContext) as Map<String, dynamic>;
      list = _extractCategories(defaultExpenses['categories']);
    }
    for (final c in list) {
      final name = c['name']?.toString() ?? '';
      if (name.isNotEmpty && !_currentAmounts.containsKey(name)) {
        _currentAmounts[name] = (c['amount'] as num?)?.toDouble() ?? 300.0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawData = _resolveCall(widget.itemContext.data, widget.itemContext.dataContext);
    var list = _extractCategories(
      rawData is Map ? (rawData['categories'] ?? rawData) : rawData,
    );
    if (list.isEmpty) {
      final defaultExpenses = const GetMonthlyExpensesFunction().executeSync(const {}, _fallbackContext) as Map<String, dynamic>;
      list = _extractCategories(defaultExpenses['categories']);
    }
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
    final val = _currentAmounts[name] ?? ((cat['amount'] as num?)?.toDouble() ?? 300.0);
    final effectiveMax = max > 0 ? max : (val > 0 ? val * 2 : 1000.0);

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
          value: val.clamp(0.0, effectiveMax),
          min: 0.0,
          max: effectiveMax,
          divisions: (effectiveMax / 50).round().clamp(5, 100),
          onChanged: (newVal) {
            setState(() => _currentAmounts[name] = newVal);
          },
        ),
      ],
    );
  }
}

// --- C. Investment Growth Card Widget ---
final investmentGrowthSchema = S.object(
  description: 'Compound interest investment growth projection card with multi-year milestones.',
  properties: {
    'monthly_contribution': S.number(description: 'Monthly investment amount'),
    'annual_interest_rate': S.number(description: 'Annual interest rate (e.g. 0.075 for 7.5%)'),
    'projections': S.any(description: 'Yearly projected balances or simulation call'),
  },
  required: ['monthly_contribution'],
);

final investmentGrowthItem = CatalogItem(
  name: 'InvestmentGrowthCard',
  dataSchema: investmentGrowthSchema,
  widgetBuilder: (itemContext) => _InvestmentGrowthWidget(itemContext: itemContext),
);

class _InvestmentGrowthWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _InvestmentGrowthWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final rawData = _resolveCall(itemContext.data, itemContext.dataContext);
    final map = rawData is Map ? Map<String, dynamic>.from(rawData) : <String, dynamic>{};

    final pmt = (map['monthly_contribution'] ?? map['monthlyContribution'] ?? map['amount'] as num?)?.toDouble() ?? 450.0;
    final rawRate = map['annual_interest_rate'] ?? map['annual_return'] ?? map['rate'] ?? 0.075;
    double rate = 0.075;
    if (rawRate is num) {
      rate = rawRate.toDouble();
      if (rate > 1.0) rate = rate / 100.0;
    }

    final sim = const SimulateInvestmentGrowthFunction().executeSync({
      'monthly_contribution': pmt,
      'annual_interest_rate': rate,
    }, _fallbackContext) as Map<String, dynamic>;

    final theme = Theme.of(context);
    final projections = (sim['projections'] as List).cast<Map<String, dynamic>>();

    final total10YearDeposits = pmt * 12 * 10;
    final total10YearGrowth = (sim['10_years'] as num).toDouble();
    final interestEarned = (total10YearGrowth - total10YearDeposits).clamp(0.0, double.infinity);

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
                    Text('Investment Growth Simulation', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Monthly: \$${pmt.toStringAsFixed(0)} | Return: ${(rate * 100).toStringAsFixed(1)}%/yr',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sim['10_years_formatted']?.toString() ?? '\$80,036',
                    style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('Projected Growth Milestones:', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final p in projections) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          p['years'] == 10 ? Icons.stars : Icons.trending_up,
                          size: 16,
                          color: p['years'] == 10 ? Colors.amber : Colors.blueAccent,
                        ),
                        const SizedBox(width: 8),
                        Text('${p['years']} Year${p['years'] == 1 ? '' : 's'}:', style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Text(
                      p['formatted']?.toString() ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: p['years'] == 10 ? 15 : 13,
                        color: p['years'] == 10 ? Colors.greenAccent : null,
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ((p['amount'] as num).toDouble() / (total10YearGrowth > 0 ? total10YearGrowth : 1.0)).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    p['years'] == 10 ? Colors.greenAccent : (p['years'] == 5 ? Colors.blueAccent : Colors.tealAccent),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '10-Yr Deposits: \$${total10YearDeposits.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    'Compound Interest: +\$${interestEarned.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, color: Colors.greenAccent, fontWeight: FontWeight.bold),
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

// ═══════════════════════════════════════════════════════════════
// 3. Screen Setup
// ═══════════════════════════════════════════════════════════════

const String financeSystemPrompt = '''
You are an expert personal finance and investment AI advisor.
When the user asks for budget reviews, spending analysis, or investment projections:
1. Available Client-Side Functions:
   - `getMonthlyExpenses()`: Returns monthly income (\$5,400) and current categories: Housing (\$1,800), Groceries & Dining (\$850), Transportation (\$400), Leisure & Subs (\$350), Utilities & Health (\$250) totaling \$3,650.
   - `calculateBudgetSavings(monthly_income, monthly_expenses)`: Computes deterministic monthly and annual savings and savings rate.
   - `simulateInvestmentGrowth(monthly_contribution, annual_interest_rate, [years])`: Computes compound interest projections over 1, 3, 5, and 10 years.
2. Generating interactive GenUI components:
   - "ExpensePieChart": When the user asks to break down expenses or show a pie chart, ALWAYS emit the "ExpensePieChart" component with populated categories:
     {"total_expenses": 3650.0, "categories": [{"name": "Housing", "amount": 1800.0}, {"name": "Groceries & Dining", "amount": 850.0}, {"name": "Transportation", "amount": 400.0}, {"name": "Leisure & Subs", "amount": 350.0}, {"name": "Utilities & Health", "amount": 250.0}]}
   - "BudgetSliders": When the user asks to adjust budget or plan savings, emit the "BudgetSliders" component:
     {"monthly_income": 5400.0, "categories": [{"name": "Housing", "amount": 1800.0, "max_amount": 2500.0}, {"name": "Groceries & Dining", "amount": 850.0, "max_amount": 1500.0}, {"name": "Transportation", "amount": 400.0, "max_amount": 800.0}, {"name": "Leisure & Subs", "amount": 350.0, "max_amount": 700.0}, {"name": "Utilities & Health", "amount": 250.0, "max_amount": 500.0}]}
   - "InvestmentGrowthCard": When the user asks to simulate compounding returns or investment growth, ALWAYS emit the "InvestmentGrowthCard" component:
     {"monthly_contribution": 450.0, "annual_interest_rate": 0.075}
3. Always emit dedicated GenUI components ("ExpensePieChart", "BudgetSliders", "InvestmentGrowthCard") instead of generic text cards. Never leave projection values blank.
''';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = BasicCatalogItems.asNoAssetCatalog().copyWith(
      newItems: [expensePieItem, budgetSliderItem, investmentGrowthItem],
      newFunctions: financeClientFunctions,
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
        initialSystemPrompt: financeSystemPrompt,
        genuiCatalog: catalog,
        clientFunctions: financeClientFunctions,
        showAgentInspector: true,
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:dart_mcp_core/dart_mcp_core.dart';

/// In-memory relational database seeded with realistic e-commerce data.
class DemoSqlDatabase {
  static final List<Map<String, dynamic>> customers = [
    {'id': 1, 'name': 'Alice Smith', 'country': 'USA', 'tier': 'Gold'},
    {'id': 2, 'name': 'Bob Martin', 'country': 'Germany', 'tier': 'Silver'},
    {'id': 3, 'name': 'Claire Dupont', 'country': 'France', 'tier': 'Gold'},
    {'id': 4, 'name': 'David Kim', 'country': 'South Korea', 'tier': 'Bronze'},
    {'id': 5, 'name': 'Elena Rossi', 'country': 'Italy', 'tier': 'Gold'},
  ];

  static final List<Map<String, dynamic>> products = [
    {'id': 101, 'name': 'UltraBook Pro 15', 'category': 'Computers', 'price': 1299.0, 'stock': 45},
    {'id': 102, 'name': 'Noise-Cancelling Headphones', 'category': 'Audio', 'price': 249.0, 'stock': 120},
    {'id': 103, 'name': 'Smart Fitness Watch', 'category': 'Wearables', 'price': 199.0, 'stock': 85},
    {'id': 104, 'name': '4K Curved Monitor', 'category': 'Computers', 'price': 499.0, 'stock': 30},
    {'id': 105, 'name': 'Wireless Ergonomic Mouse', 'category': 'Accessories', 'price': 69.0, 'stock': 200},
  ];

  static final List<Map<String, dynamic>> orders = [
    {'id': 1001, 'customer_id': 1, 'product_id': 101, 'quantity': 1, 'total_price': 1299.0, 'date': '2026-03-01'},
    {'id': 1002, 'customer_id': 1, 'product_id': 102, 'quantity': 2, 'total_price': 498.0, 'date': '2026-03-02'},
    {'id': 1003, 'customer_id': 2, 'product_id': 103, 'quantity': 1, 'total_price': 199.0, 'date': '2026-03-05'},
    {'id': 1004, 'customer_id': 3, 'product_id': 101, 'quantity': 2, 'total_price': 2598.0, 'date': '2026-03-10'},
    {'id': 1005, 'customer_id': 3, 'product_id': 104, 'quantity': 1, 'total_price': 499.0, 'date': '2026-03-11'},
    {'id': 1006, 'customer_id': 4, 'product_id': 105, 'quantity': 3, 'total_price': 207.0, 'date': '2026-03-15'},
    {'id': 1007, 'customer_id': 5, 'product_id': 102, 'quantity': 1, 'total_price': 249.0, 'date': '2026-03-18'},
    {'id': 1008, 'customer_id': 5, 'product_id': 104, 'quantity': 2, 'total_price': 998.0, 'date': '2026-03-20'},
  ];

  static Map<String, dynamic> getSchema() {
    return {
      'database': 'ecommerce_analytics.db',
      'tables': {
        'customers': {
          'columns': ['id (INT PRIMARY KEY)', 'name (TEXT)', 'country (TEXT)', 'tier (TEXT)'],
          'row_count': customers.length,
          'sample': customers.first,
        },
        'products': {
          'columns': ['id (INT PRIMARY KEY)', 'name (TEXT)', 'category (TEXT)', 'price (REAL)', 'stock (INT)'],
          'row_count': products.length,
          'sample': products.first,
        },
        'orders': {
          'columns': [
            'id (INT PRIMARY KEY)',
            'customer_id (INT REFERENCES customers(id))',
            'product_id (INT REFERENCES products(id))',
            'quantity (INT)',
            'total_price (REAL)',
            'date (TEXT)'
          ],
          'row_count': orders.length,
          'sample': orders.first,
        },
      },
    };
  }

  static List<Map<String, dynamic>> executeQuery(String sql) {
    final lower = sql.toLowerCase();

    // Aggregate category revenue
    if (lower.contains('category') && (lower.contains('sum') || lower.contains('revenue') || lower.contains('total_price'))) {
      final categoryRevenue = <String, double>{};
      final categoryOrders = <String, int>{};
      for (final o in orders) {
        final prod = products.firstWhere((p) => p['id'] == o['product_id']);
        final cat = prod['category'] as String;
        final tot = (o['total_price'] as num).toDouble();
        categoryRevenue[cat] = (categoryRevenue[cat] ?? 0.0) + tot;
        categoryOrders[cat] = (categoryOrders[cat] ?? 0) + (o['quantity'] as int);
      }
      return categoryRevenue.entries.map((e) {
        return {
          'category': e.key,
          'total_revenue': e.value,
          'items_sold': categoryOrders[e.key],
        };
      }).toList()
        ..sort((a, b) => (b['total_revenue'] as double).compareTo(a['total_revenue'] as double));
    }

    // Top spending customers
    if (lower.contains('customer') && (lower.contains('sum') || lower.contains('spend') || lower.contains('total_price') || lower.contains('top'))) {
      final customerSpent = <int, double>{};
      for (final o in orders) {
        final cid = o['customer_id'] as int;
        final tot = (o['total_price'] as num).toDouble();
        customerSpent[cid] = (customerSpent[cid] ?? 0.0) + tot;
      }
      final results = customerSpent.entries.map((e) {
        final cust = customers.firstWhere((c) => c['id'] == e.key);
        return {
          'customer_id': e.key,
          'customer_name': cust['name'],
          'country': cust['country'],
          'tier': cust['tier'],
          'total_spent': e.value,
        };
      }).toList()
        ..sort((a, b) => (b['total_spent'] as double).compareTo(a['total_spent'] as double));
      return results;
    }

    // Products table query
    if (lower.contains('from products')) {
      return products;
    }

    // Orders table query
    if (lower.contains('from orders')) {
      return orders;
    }

    // Customers table query
    if (lower.contains('from customers')) {
      return customers;
    }

    // Default join summary
    return orders.map((o) {
      final cust = customers.firstWhere((c) => c['id'] == o['customer_id']);
      final prod = products.firstWhere((p) => p['id'] == o['product_id']);
      return {
        'order_id': o['id'],
        'customer': cust['name'],
        'product': prod['name'],
        'category': prod['category'],
        'total_price': o['total_price'],
        'date': o['date'],
      };
    }).toList();
  }
}

/// Tool to get schema.
class SqliteGetSchemaTool extends McpLocalTool {
  @override
  String get name => 'sqlite_get_schema';

  @override
  String get description =>
      'Inspect available tables and column schemas in the database.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'database_name': {'type': 'string', 'description': 'Database identifier'},
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final schemaJson = jsonEncode(DemoSqlDatabase.getSchema());
    return MCPToolResult(
      content: [MCPContent(type: 'text', text: schemaJson)],
    );
  }
}

/// Tool to execute SQL queries.
class SqliteQueryTool extends McpLocalTool {
  @override
  String get name => 'sqlite_query';

  @override
  String get description =>
      'Execute a SQL query (SELECT) against the database and return row results as JSON.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'query': {'type': 'string', 'description': 'SQL SELECT query to execute'},
        },
        'required': ['query'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final query = arguments['query'] as String;
    try {
      final rows = DemoSqlDatabase.executeQuery(query);
      final res = jsonEncode({
        'success': true,
        'query': query,
        'row_count': rows.length,
        'rows': rows,
      });
      return MCPToolResult(
        content: [MCPContent(type: 'text', text: res)],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent(type: 'text', text: 'Error executing query: $e')],
        isError: true,
      );
    }
  }
}

/// Tool to export analytical executive summary.
class ExportAnalysisReportTool extends McpLocalTool {
  @override
  String get name => 'export_analysis_report';

  @override
  String get description =>
      'Export the data analysis, metrics table, and executive summary to a markdown file.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'title': {'type': 'string', 'description': 'Report title'},
          'kpi_metrics': {'type': 'object', 'description': 'Key performance metrics map'},
          'executive_summary': {'type': 'string', 'description': 'Summary of business findings'},
          'recommendations': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Strategic recommendations',
          },
          'output_filename': {'type': 'string', 'description': 'Destination filename'},
        },
        'required': ['title', 'executive_summary', 'recommendations'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final title = arguments['title'] as String? ?? 'Executive Data Analytics Report';
    final kpiMetrics = (arguments['kpi_metrics'] as Map?)?.cast<String, dynamic>() ?? {};
    final summary = arguments['executive_summary'] as String? ?? '';
    final recommendations = (arguments['recommendations'] as List?)?.cast<String>() ?? [];
    final filename = arguments['output_filename'] as String? ?? 'DATABASE_REPORT.md';

    final buffer = StringBuffer();
    buffer.writeln('# $title\n');
    buffer.writeln('**Generated on**: ${DateTime.now().toUtc().toIso8601String()}\n');

    if (kpiMetrics.isNotEmpty) {
      buffer.writeln('## 📊 Key Performance Indicators');
      buffer.writeln('| Metric | Value |');
      buffer.writeln('| --- | --- |');
      for (final entry in kpiMetrics.entries) {
        buffer.writeln('| ${entry.key} | ${entry.value} |');
      }
      buffer.writeln('');
    }

    buffer.writeln('## 💡 Executive Summary');
    buffer.writeln('$summary\n');

    if (recommendations.isNotEmpty) {
      buffer.writeln('## 🚀 Strategic Recommendations');
      for (final rec in recommendations) {
        buffer.writeln('- $rec');
      }
      buffer.writeln('');
    }

    buffer.writeln('---\n*Generated by MCP Playground `sqlite-database-analyst` skill.*');

    try {
      final file = File(filename);
      await file.writeAsString(buffer.toString());
      final res = jsonEncode({
        'success': true,
        'filename': file.absolute.path,
        'bytes_written': buffer.length,
      });
      return MCPToolResult(
        content: [MCPContent(type: 'text', text: res)],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent(type: 'text', text: 'Error writing file: $e')],
        isError: true,
      );
    }
  }
}

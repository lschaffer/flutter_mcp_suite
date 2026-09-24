import 'dart:convert';
import 'package:flutter_genui_mcp/flutter_genui_mcp.dart';
import 'package:genui/genui.dart';
import 'env_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const GenuiPcBuilderApp());
}

class GenuiPcBuilderApp extends StatelessWidget {
  const GenuiPcBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI PC Builder & Hardware Store',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
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
      home: const PcBuilderMainScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. Data Models for Hardware Store
// ═══════════════════════════════════════════════════════════════

class PcHardwareItem {
  final String id;
  final String name;
  final String category; // 'cpu', 'motherboard', 'gpu', 'ram', 'storage', 'psu', 'case', 'cooling'
  final String brand;
  final double price;
  final double rating;
  final String specs;
  final String imageUrl;

  const PcHardwareItem({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.price,
    required this.rating,
    required this.specs,
    required this.imageUrl,
  });

  factory PcHardwareItem.fromJson(Map<String, dynamic> json) {
    return PcHardwareItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Hardware Item',
      category: json['category']?.toString() ?? 'other',
      brand: json['brand']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      specs: json['specs']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'brand': brand,
    'price': price,
    'rating': rating,
    'specs': specs,
    'imageUrl': imageUrl,
  };
}

final List<PcHardwareItem> sampleStoreInventory = [
  // CPUs
  const PcHardwareItem(
    id: 'cpu-01',
    name: 'AMD Ryzen 7 7800X3D',
    category: 'cpu',
    brand: 'AMD',
    price: 389.99,
    rating: 4.95,
    specs: '8 Cores, 16 Threads, 5.0 GHz Boost, 96MB 3D V-Cache, AM5 Socket',
    imageUrl:
        'https://images.unsplash.com/photo-1555680202-c86f0e12f086?w=600&auto=format&fit=crop&q=80',
  ),
  const PcHardwareItem(
    id: 'cpu-02',
    name: 'AMD Ryzen 9 7950X3D',
    category: 'cpu',
    brand: 'AMD',
    price: 549.99,
    rating: 4.92,
    specs: '16 Cores, 32 Threads, 5.7 GHz Boost, 128MB 3D V-Cache, AM5',
    imageUrl:
        'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=600&auto=format&fit=crop&q=80',
  ),
  const PcHardwareItem(
    id: 'cpu-03',
    name: 'Intel Core i7-14700K',
    category: 'cpu',
    brand: 'Intel',
    price: 369.99,
    rating: 4.88,
    specs: '20 Cores (8P + 12E), 28 Threads, Up to 5.6 GHz, LGA1700 Socket',
    imageUrl:
        'https://images.unsplash.com/photo-1591799264318-7e6ef8ddb7ea?w=600&auto=format&fit=crop&q=80',
  ),
  const PcHardwareItem(
    id: 'cpu-04',
    name: 'Intel Core i9-14900K',
    category: 'cpu',
    brand: 'Intel',
    price: 529.99,
    rating: 4.90,
    specs: '24 Cores (8P + 16E), 32 Threads, Up to 6.0 GHz, LGA1700',
    imageUrl:
        'https://images.unsplash.com/photo-1591799264318-7e6ef8ddb7ea?w=600&auto=format&fit=crop&q=80',
  ),

  // Motherboards
  const PcHardwareItem(
    id: 'mb-01',
    name: 'ASUS ROG Strix B650E-F Gaming WiFi',
    category: 'motherboard',
    brand: 'ASUS',
    price: 269.99,
    rating: 4.91,
    specs: 'AMD AM5, PCIe 5.0 x16, DDR5-6400+, WiFi 6E, 3x M.2 Slots, Aura Sync',
    imageUrl:
        'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&auto=format&fit=crop&q=80',
  ),
  const PcHardwareItem(
    id: 'mb-02',
    name: 'MSI MAG X670E Tomahawk WiFi',
    category: 'motherboard',
    brand: 'MSI',
    price: 299.99,
    rating: 4.89,
    specs: 'AMD AM5, 14+2+1 Duet Rail VRM, PCIe 5.0, 4x M.2, 2.5G LAN, WiFi 6E',
    imageUrl:
        'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&auto=format&fit=crop&q=80',
  ),
  const PcHardwareItem(
    id: 'mb-03',
    name: 'Gigabyte Z790 AORUS Elite AX',
    category: 'motherboard',
    brand: 'Gigabyte',
    price: 249.99,
    rating: 4.87,
    specs: 'Intel LGA1700, 16+1+2 Twin Digital VRM, DDR5-7600+, 4x M.2 PCIe 4.0',
    imageUrl:
        'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&auto=format&fit=crop&q=80',
  ),

  // Graphics Cards
  const PcHardwareItem(
    id: 'gpu-01',
    name: 'NVIDIA GeForce RTX 4070 Super 12GB',
    category: 'gpu',
    brand: 'NVIDIA',
    price: 599.99,
    rating: 4.93,
    specs: '12GB GDDR6X, DLSS 3.5 Frame Gen, Ray Tracing, 220W TDP',
    imageUrl:
        'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=600&auto=format&fit=crop&q=80',
  ),
  const PcHardwareItem(
    id: 'gpu-02',
    name: 'NVIDIA GeForce RTX 4080 Super 16GB',
    category: 'gpu',
    brand: 'NVIDIA',
    price: 999.99,
    rating: 4.96,
    specs: '16GB GDDR6X, 10240 CUDA Cores, 4K High Refresh, DLSS 3.5',
    imageUrl:
        'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?w=600&auto=format&fit=crop&q=80',
  ),
  const PcHardwareItem(
    id: 'gpu-03',
    name: 'AMD Radeon RX 7900 GRE 16GB',
    category: 'gpu',
    brand: 'AMD',
    price: 539.99,
    rating: 4.90,
    specs: '16GB GDDR6, 256-bit bus, RDNA 3 Architecture, AV1 Encode',
    imageUrl:
        'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=600&auto=format&fit=crop&q=80',
  ),

  // Memory (RAM)
  const PcHardwareItem(
    id: 'ram-01',
    name: 'Corsair Vengeance RGB DDR5 32GB (2x16GB) 6000MHz',
    category: 'ram',
    brand: 'Corsair',
    price: 119.99,
    rating: 4.92,
    specs: 'DDR5 6000MHz, CL30 (30-36-36-76), AMD EXPO & Intel XMP 3.0, Dynamic RGB',
    imageUrl:
        'https://images.unsplash.com/photo-1562975079-78d1f7c8ec1b?w=600&auto=format&fit=crop&q=80',
  ),
  const PcHardwareItem(
    id: 'ram-02',
    name: 'G.Skill Ripjaws S5 DDR5 64GB (2x32GB) 6000MHz',
    category: 'ram',
    brand: 'G.Skill',
    price: 209.99,
    rating: 4.93,
    specs: 'DDR5 6000MT/s, CL30-40-40-96, Low Profile Matte Black Heatspreader',
    imageUrl:
        'https://images.unsplash.com/photo-1562975079-78d1f7c8ec1b?w=600&auto=format&fit=crop&q=80',
  ),

  // Storage
  const PcHardwareItem(
    id: 'ssd-01',
    name: 'Samsung 990 PRO NVMe M.2 SSD 2TB',
    category: 'storage',
    brand: 'Samsung',
    price: 169.99,
    rating: 4.97,
    specs: 'PCIe 4.0 NVMe, Sequential Read: 7450 MB/s, Write: 6900 MB/s, V-NAND TLC',
    imageUrl:
        'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=600&auto=format&fit=crop&q=80',
  ),

  // Power Supply (PSU)
  const PcHardwareItem(
    id: 'psu-01',
    name: 'Corsair RM850x 850W 80+ Gold Modular',
    category: 'psu',
    brand: 'Corsair',
    price: 139.99,
    rating: 4.91,
    specs: 'Fully Modular, 80 PLUS Gold Certified, Zero RPM Fan Mode, 100% Japanese Caps',
    imageUrl:
        'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?w=600&auto=format&fit=crop&q=80',
  ),

  // Case
  const PcHardwareItem(
    id: 'case-01',
    name: 'NZXT H9 Flow Dual-Chamber Mid-Tower',
    category: 'case',
    brand: 'NZXT',
    price: 159.99,
    rating: 4.89,
    specs: 'Panoramic Glass Panels, Perforated Mesh Airflow, 4x 120mm Fans Included',
    imageUrl:
        'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=600&auto=format&fit=crop&q=80',
  ),

  // Cooling
  const PcHardwareItem(
    id: 'cooler-01',
    name: 'Thermalright Peerless Assassin 120 SE ARGB',
    category: 'cooling',
    brand: 'Thermalright',
    price: 36.90,
    rating: 4.94,
    specs: 'Dual-Tower CPU Air Cooler, 6 Heatpipes, 2x 120mm PWM Quiet Fans, ARGB',
    imageUrl:
        'https://images.unsplash.com/photo-1541029071515-84cc54f84dc5?w=600&auto=format&fit=crop&q=80',
  ),
  const PcHardwareItem(
    id: 'cooler-02',
    name: 'Arctic Liquid Freezer III 360 A-RGB',
    category: 'cooling',
    brand: 'Arctic',
    price: 109.99,
    rating: 4.95,
    specs: '360mm AIO Liquid Cooler, VRM Cooling Fan, 38mm Radiator, High Static Pressure',
    imageUrl:
        'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=600&auto=format&fit=crop&q=80',
  ),
];

// ═══════════════════════════════════════════════════════════════
// 2. Local MCP Tools for PC Store Agent
// ═══════════════════════════════════════════════════════════════

class SearchPcHardwareTool extends McpLocalTool {
  @override
  String get name => 'search_pc_hardware';

  @override
  String get description =>
      'Searches the store inventory for PC hardware components (CPU, Motherboard, GPU, RAM, SSD, PSU, Case, Cooler). '
      'Filter by category, search text, or maximum price. Returns matching products with verified specs, prices, and photo URLs.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'category': {
        'type': 'string',
        'enum': [
          'all',
          'cpu',
          'motherboard',
          'gpu',
          'ram',
          'storage',
          'psu',
          'case',
          'cooling',
        ],
        'description': 'Hardware category to filter by.',
      },
      'query': {
        'type': 'string',
        'description': 'Optional search keyword (e.g. "Ryzen", "RTX 4070", "DDR5", "NZXT").',
      },
      'maxPrice': {
        'type': 'number',
        'description': 'Maximum price filter in USD.',
      },
    },
  };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final cat = (arguments['category'] as String? ?? 'all').toLowerCase();
    final query = (arguments['query'] as String? ?? '').toLowerCase();
    final maxPrice = (arguments['maxPrice'] as num?)?.toDouble();

    var results = sampleStoreInventory.where((item) {
      if (cat != 'all' && item.category.toLowerCase() != cat) return false;
      if (maxPrice != null && item.price > maxPrice) return false;
      if (query.isNotEmpty) {
        final matches =
            item.name.toLowerCase().contains(query) ||
            item.brand.toLowerCase().contains(query) ||
            item.specs.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList();

    final dataList = results.map((e) => e.toJson()).toList();
    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({
            'status': 'success',
            'count': dataList.length,
            'items': dataList,
          }),
        ),
      ],
    );
  }
}

class SubmitPcOrderTool extends McpLocalTool {
  @override
  String get name => 'submit_pc_order';

  @override
  String get description =>
      'Submits a finalized PC hardware order with selected item IDs, customer name, shipping address, and email. '
      'Calculates final invoice amounts and returns a verified Order Confirmation with tracking ID.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'customerName': {
        'type': 'string',
        'description': 'Customer full name.',
      },
      'email': {
        'type': 'string',
        'description': 'Customer email address.',
      },
      'shippingAddress': {
        'type': 'string',
        'description': 'Delivery address for hardware shipment.',
      },
      'itemIds': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'List of hardware item IDs to purchase.',
      },
    },
    'required': ['customerName', 'email', 'itemIds'],
  };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final customer = arguments['customerName']?.toString() ?? 'Valued Customer';
    final email = arguments['email']?.toString() ?? 'user@example.com';
    final address = arguments['shippingAddress']?.toString() ?? 'Standard Delivery';
    final rawIds = (arguments['itemIds'] as List?) ?? [];
    final ids = rawIds.map((e) => e.toString()).toSet();

    final orderedItems =
        sampleStoreInventory.where((it) => ids.contains(it.id)).toList();

    double subtotal = 0.0;
    for (final it in orderedItems) {
      subtotal += it.price;
    }
    final tax = subtotal * 0.08;
    final total = subtotal + tax;
    final orderId = 'ORD-PC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({
            'status': 'success',
            'orderId': orderId,
            'customerName': customer,
            'email': email,
            'shippingAddress': address,
            'itemsCount': orderedItems.length,
            'subtotal': double.parse(subtotal.toStringAsFixed(2)),
            'tax': double.parse(tax.toStringAsFixed(2)),
            'shipping': 0.0,
            'total': double.parse(total.toStringAsFixed(2)),
            'fulfillmentStatus': 'Confirmed & Scheduled for Assembly',
            'estimatedDelivery': '3-5 Business Days',
          }),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 3. GenUI Catalog Definitions
// ═══════════════════════════════════════════════════════════════

final pcBuildFormSchema = S.object(
  description:
      'Form allowing user to select use case, target budget, and platform architecture.',
  properties: {
    'title': S.string(description: 'Form title.'),
    'subtitle': S.string(description: 'Form subtitle.'),
    'defaultUseCase': S.string(description: 'Initial use case.'),
    'defaultBudget': S.number(description: 'Initial budget slider value in USD.'),
  },
);

final pcBuildFormItem = CatalogItem(
  name: 'PcBuildForm',
  dataSchema: pcBuildFormSchema,
  widgetBuilder: (ctx) => _PcBuildFormWidget(itemContext: ctx),
);

final productCatalogGridSchema = S.object(
  description:
      'Product grid showing available hardware items in the store with photos and specs.',
  properties: {
    'title': S.string(description: 'Grid section title.'),
    'category': S.string(
      description: 'Category name (e.g. Processors, Graphics Cards).',
    ),
    'items': S.list(
      description: 'List of hardware products.',
      items: S.object(
        properties: {
          'id': S.string(),
          'name': S.string(),
          'category': S.string(),
          'price': S.number(),
          'rating': S.number(),
          'specs': S.string(),
          'imageUrl': S.string(),
          'brand': S.string(),
        },
      ),
    ),
  },
  required: ['items'],
);

final productCatalogGridItem = CatalogItem(
  name: 'ProductCatalogGrid',
  dataSchema: productCatalogGridSchema,
  widgetBuilder: (ctx) => _ProductCatalogGridWidget(itemContext: ctx),
);

final pcOrderSummarySchema = S.object(
  description:
      'Order cart and summary card with itemized prices, total, and checkout submission.',
  properties: {
    'title': S.string(description: 'Card title.'),
    'subtitle': S.string(description: 'Subtitle / status note.'),
    'items': S.list(
      description: 'List of products included in this build.',
      items: S.object(
        properties: {
          'id': S.string(),
          'name': S.string(),
          'category': S.string(),
          'price': S.number(),
          'imageUrl': S.string(),
        },
      ),
    ),
    'subtotal': S.number(description: 'Subtotal sum.'),
    'tax': S.number(description: 'Calculated tax.'),
    'shipping': S.number(description: 'Shipping cost.'),
    'total': S.number(description: 'Total amount.'),
  },
  required: ['items'],
);

final pcOrderSummaryItem = CatalogItem(
  name: 'PcOrderSummaryCard',
  dataSchema: pcOrderSummarySchema,
  widgetBuilder: (ctx) => _PcOrderSummaryWidget(itemContext: ctx),
);

final orderReceiptSchema = S.object(
  description: 'Verified order confirmation card with order ID and summary.',
  properties: {
    'orderId': S.string(description: 'Unique order ID.'),
    'customerName': S.string(description: 'Customer name.'),
    'email': S.string(description: 'Customer email.'),
    'shippingAddress': S.string(description: 'Delivery address.'),
    'total': S.number(description: 'Total order cost.'),
    'status': S.string(description: 'Fulfillment status.'),
    'itemsCount': S.integer(description: 'Count of items.'),
  },
  required: ['orderId', 'total'],
);

final orderReceiptItem = CatalogItem(
  name: 'OrderReceiptCard',
  dataSchema: orderReceiptSchema,
  widgetBuilder: (ctx) => _OrderReceiptWidget(itemContext: ctx),
);

Catalog buildPcBuilderGenuiCatalog() {
  final base = BasicCatalogItems.asNoAssetCatalog();
  return base.copyWith(
    newItems: [
      pcBuildFormItem,
      productCatalogGridItem,
      pcOrderSummaryItem,
      orderReceiptItem,
    ],
  );
}

// ═══════════════════════════════════════════════════════════════
// 4. Flutter Widgets for Catalog Items
// ═══════════════════════════════════════════════════════════════

class _PcBuildFormWidget extends StatefulWidget {
  final CatalogItemContext itemContext;
  const _PcBuildFormWidget({required this.itemContext});

  @override
  State<_PcBuildFormWidget> createState() => _PcBuildFormWidgetState();
}

class _PcBuildFormWidgetState extends State<_PcBuildFormWidget> {
  String _useCase = 'Gaming (1440p / 4K)';
  double _budget = 1800;
  String _platform = 'AMD AM5';
  bool _isSubmitting = false;

  final List<String> _useCases = [
    'Gaming (1440p / 4K)',
    'Competitive eSports (High FPS)',
    'Content Creation / 3D Workstation',
    'Budget Value Build',
  ];

  @override
  void initState() {
    super.initState();
    final data = Map<String, Object?>.from(
      (widget.itemContext.data as Map?) ?? {},
    );
    if (data['defaultBudget'] is num) {
      _budget = (data['defaultBudget'] as num).toDouble();
    }
  }

  void _submit() {
    setState(() => _isSubmitting = true);

    widget.itemContext.dispatchEvent(
      UserActionEvent(
        name: 'start_pc_build',
        sourceComponentId: widget.itemContext.id,
        context: <String, Object?>{
          'useCase': _useCase,
          'targetBudget': _budget.toInt(),
          'platform': _platform,
          'message':
              'User selected $_useCase build with target budget \$${_budget.toInt()} and $_platform platform architecture. Search the store inventory for matching components and recommend an optimal build.',
          'userSummary':
              'Build Request: $_useCase | Budget: \$${_budget.toInt()} | Platform: $_platform',
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = Map<String, Object?>.from(
      (widget.itemContext.data as Map?) ?? {},
    );
    final theme = Theme.of(context);
    final title = data['title']?.toString() ?? 'Custom PC Rig Builder';
    final subtitle =
        data['subtitle']?.toString() ??
        'Specify your target workload and budget to configure your rig';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.computer_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),

            // Use Case Choice
            Text(
              'Primary Use Case',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _useCases.map((uc) {
                final selected = _useCase == uc;
                return ChoiceChip(
                  label: Text(uc),
                  selected: selected,
                  onSelected: (val) {
                    if (val) setState(() => _useCase = uc);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Budget Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target Budget',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${_budget.toInt()}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              min: 800,
              max: 4000,
              divisions: 32,
              value: _budget,
              label: '\$${_budget.toInt()}',
              onChanged: (val) => setState(() => _budget = val),
            ),
            const SizedBox(height: 14),

            // Platform Choice (SegmentedButton)
            Text(
              'Platform Architecture',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'AMD AM5',
                    label: Text('AMD AM5 (DDR5)'),
                    icon: Icon(Icons.memory),
                  ),
                  ButtonSegment(
                    value: 'Intel LGA1700',
                    label: Text('Intel LGA1700'),
                    icon: Icon(Icons.developer_board),
                  ),
                ],
                selected: {_platform},
                onSelectionChanged: (set) {
                  setState(() => _platform = set.first);
                },
              ),
            ),
            const SizedBox(height: 22),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  _isSubmitting
                      ? 'Recommending Hardware...'
                      : 'Recommend Store Hardware & Build Rig',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _isSubmitting ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCatalogGridWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _ProductCatalogGridWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = Map<String, Object?>.from(
      (itemContext.data as Map?) ?? {},
    );
    final theme = Theme.of(context);
    final title = data['title']?.toString() ?? 'Store Products';
    final category = data['category']?.toString();
    final rawItems = (data['items'] as List?) ?? [];
    final items = rawItems
        .map((e) => PcHardwareItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            children: [
              Icon(Icons.storefront_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category != null && category.isNotEmpty
                      ? '$title ($category)'
                      : title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${items.length} in stock',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 580;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 2 : 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWide ? 1.6 : 2.0,
              ),
              itemBuilder: (ctx, index) {
                final item = items[index];
                return _HardwareProductCard(
                  item: item,
                  onSelect: () {
                    itemContext.dispatchEvent(
                      UserActionEvent(
                        name: 'select_hardware_item',
                        sourceComponentId: itemContext.id,
                        context: <String, Object?>{
                          'action': 'add_to_build',
                          'itemId': item.id,
                          'name': item.name,
                          'price': item.price,
                          'category': item.category,
                          'message':
                              'Added "${item.name}" (\$${item.price.toStringAsFixed(2)}) to PC build.',
                          'userSummary':
                              'Selected: ${item.name} (\$${item.price.toStringAsFixed(2)})',
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _HardwareProductCard extends StatelessWidget {
  final PcHardwareItem item;
  final VoidCallback onSelect;

  const _HardwareProductCard({
    required this.item,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.memory,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.brand,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.specs,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: onSelect,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_shopping_cart, size: 14),
                            SizedBox(width: 4),
                            Text('Choose', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PcOrderSummaryWidget extends StatefulWidget {
  final CatalogItemContext itemContext;
  const _PcOrderSummaryWidget({required this.itemContext});

  @override
  State<_PcOrderSummaryWidget> createState() => _PcOrderSummaryWidgetState();
}

class _PcOrderSummaryWidgetState extends State<_PcOrderSummaryWidget> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final data = Map<String, Object?>.from(
      (widget.itemContext.data as Map?) ?? {},
    );
    _nameCtrl = TextEditingController(
      text: data['customerName']?.toString() ?? '',
    );
    _emailCtrl = TextEditingController(
      text: data['email']?.toString() ?? '',
    );
    _addressCtrl = TextEditingController(
      text: data['shippingAddress']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _submitOrder(List<String> itemIds, double total) {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in your Full Name, Email, and Delivery Address to place order.',
          ),
          backgroundColor: Colors.deepOrange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Auto-reset submitting indicator after request dispatches
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _isSubmitting = false);
    });

    widget.itemContext.dispatchEvent(
      UserActionEvent(
        name: 'submit_final_order',
        sourceComponentId: widget.itemContext.id,
        context: <String, Object?>{
          'customerName': name,
          'email': email,
          'shippingAddress': address,
          'itemIds': itemIds,
          'total': total,
          'message':
              'Order Checkout Submitted by Customer.\n'
              '- Customer: $name\n'
              '- Email: $email\n'
              '- Shipping Address: $address\n'
              '- Item IDs: ${itemIds.join(", ")}\n'
              '- Total: \$${total.toStringAsFixed(2)}\n\n'
              'Please invoke the tool `submit_pc_order` with these exact customer details and item IDs, and render the `OrderReceiptCard` GenUI component.',
          'userSummary':
              'Placed Order: ${itemIds.length} parts | Total: \$${total.toStringAsFixed(2)} | Recipient: $name',
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = Map<String, Object?>.from(
      (widget.itemContext.data as Map?) ?? {},
    );
    final theme = Theme.of(context);
    final title = data['title']?.toString() ?? 'PC Build Order Summary';
    final rawItems = (data['items'] as List?) ?? [];

    final itemIds = <String>[];
    double calculatedSubtotal = 0.0;

    final parsedItems = rawItems.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final id = m['id']?.toString() ?? '';
      itemIds.add(id);
      final price = (m['price'] as num?)?.toDouble() ?? 0.0;
      calculatedSubtotal += price;
      return m;
    }).toList();

    final subtotal = (data['subtotal'] as num?)?.toDouble() ?? calculatedSubtotal;
    final tax = (data['tax'] as num?)?.toDouble() ?? (subtotal * 0.08);
    final shipping = (data['shipping'] as num?)?.toDouble() ?? 0.0;
    final total = (data['total'] as num?)?.toDouble() ?? (subtotal + tax + shipping);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${parsedItems.length} Parts',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Itemized list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: parsedItems.length,
              separatorBuilder: (_, _) => const Divider(height: 12),
              itemBuilder: (ctx, i) {
                final it = parsedItems[i];
                final price = (it['price'] as num?)?.toDouble() ?? 0.0;
                final cat = it['category']?.toString().toUpperCase() ?? 'PART';
                return Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: it['imageUrl'] != null &&
                              it['imageUrl'].toString().isNotEmpty
                          ? Image.network(
                              it['imageUrl'].toString(),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.memory, size: 20),
                            )
                          : const Icon(Icons.memory, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it['name']?.toString() ?? 'Component',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            cat,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 28),

            // Cost calculation
            _PriceRow(
              label: 'Hardware Subtotal',
              amount: '\$${subtotal.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 4),
            _PriceRow(
              label: 'Estimated Sales Tax (8%)',
              amount: '\$${tax.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 4),
            _PriceRow(
              label: 'Insured Express Shipping',
              amount: shipping == 0 ? 'FREE' : '\$${shipping.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Order Cost',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text(
              'Shipping & Contact Details',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'e.g. Alex Morgan',
                prefixIcon: Icon(Icons.person_outline, size: 18),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address for Tracking',
                hintText: 'e.g. alex@example.com',
                prefixIcon: Icon(Icons.email_outlined, size: 18),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Shipping Street Address',
                hintText: 'e.g. 742 Evergreen Terrace, Springfield, OR',
                prefixIcon: Icon(Icons.local_shipping_outlined, size: 18),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSubmitting
                      ? 'Submitting Order...'
                      : 'Place Order & Pay (\$${total.toStringAsFixed(2)})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _isSubmitting
                    ? null
                    : () => _submitOrder(itemIds, total),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String amount;
  const _PriceRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          amount,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _OrderReceiptWidget extends StatelessWidget {
  final CatalogItemContext itemContext;
  const _OrderReceiptWidget({required this.itemContext});

  @override
  Widget build(BuildContext context) {
    final data = Map<String, Object?>.from(
      (itemContext.data as Map?) ?? {},
    );
    final theme = Theme.of(context);
    final orderId = data['orderId']?.toString() ?? 'ORD-PC-SUCCESS';
    final customer = data['customerName']?.toString() ?? 'Valued Customer';
    final email = data['email']?.toString() ?? 'customer@example.com';
    final address =
        data['shippingAddress']?.toString() ?? 'Standard Express Delivery';
    final total = (data['total'] as num?)?.toDouble() ?? 0.0;
    final status = data['status']?.toString() ?? 'Order Placed & Confirmed';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade400, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade800,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Confirmed!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    Text(
                      'Order ID: $orderId',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),

          _ReceiptDetail(
            icon: Icons.person_outline,
            label: 'Customer',
            value: customer,
          ),
          const SizedBox(height: 8),
          _ReceiptDetail(
            icon: Icons.email_outlined,
            label: 'Tracking Sent To',
            value: email,
          ),
          const SizedBox(height: 8),
          _ReceiptDetail(
            icon: Icons.home_outlined,
            label: 'Shipping To',
            value: address,
          ),
          const SizedBox(height: 8),
          _ReceiptDetail(
            icon: Icons.local_shipping_outlined,
            label: 'Status',
            value: status,
          ),
          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Amount Charged',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ReceiptDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 5. System Prompt for PC Builder Agent
// ═══════════════════════════════════════════════════════════════

const String pcBuilderGenuiSystemPrompt = '''
You are an expert PC Hardware Architect and Store Assistant.
Your mission is to guide users to pick compatible, top-performing PC components (CPUs, motherboards, GPUs, RAM, SSDs, PSUs, cases, coolers), build customized rigs within their target budget, place items in an order, and submit the checkout.

You have access to two MCP Tools:
1. `search_pc_hardware(category, query, maxPrice)`:
   Searches the store inventory for products with real specs, prices, and photo URLs.
2. `submit_pc_order(customerName, email, shippingAddress, itemIds)`:
   Submits and confirms customer orders, creating verified order records.

CRITICAL REQUIREMENT - GENUI RENDERING:
Always render interactive GenUI components instead of text tables. To render UI, emit the standard A2UI JSON messages (`createSurface` followed by `updateComponents`):

1. To display the interactive configurator form:
```json
{"version": "v0.9", "createSurface": {"surfaceId": "pc_config_form"}}
{"version": "v0.9", "updateComponents": {"surfaceId": "pc_config_form", "components": [{"id": "root", "component": "PcBuildForm", "data": {"title": "Custom PC Rig Builder", "subtitle": "Configure your platform and target budget", "defaultUseCase": "Gaming (1440p / 4K)", "defaultBudget": 2000}}]}}
```

2. When displaying hardware products/catalog items (RAM, CPU, Motherboard, GPU, etc.) for the user to view and select:
```json
{"version": "v0.9", "createSurface": {"surfaceId": "product_grid"}}
{"version": "v0.9", "updateComponents": {"surfaceId": "product_grid", "components": [{"id": "root", "component": "ProductCatalogGrid", "data": {"title": "Available Graphics Cards", "category": "Graphics Cards", "items": [{"id": "gpu-01", "name": "NVIDIA RTX 4070 Super 12GB", "category": "gpu", "price": 599.99, "rating": 4.93, "specs": "12GB GDDR6X, DLSS 3.5", "imageUrl": "https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=600&auto=format&fit=crop&q=80", "brand": "NVIDIA"}]}}]}}
```

3. When recommending a full build or showing the user's order cart:
```json
{"version": "v0.9", "createSurface": {"surfaceId": "order_summary"}}
{"version": "v0.9", "updateComponents": {"surfaceId": "order_summary", "components": [{"id": "root", "component": "PcOrderSummaryCard", "data": {"title": "Your Custom PC Build Order", "items": [{"id": "cpu-01", "name": "AMD Ryzen 7 7800X3D", "category": "cpu", "price": 389.99, "imageUrl": "https://images.unsplash.com/photo-1555680202-c86f0e12f086?w=600&auto=format&fit=crop&q=80"}], "subtotal": 1845.00, "tax": 147.60, "shipping": 0.0, "total": 1992.60}}]}}
```

4. When the user confirms/places an order:
First call `submit_pc_order`, then render the receipt:
```json
{"version": "v0.9", "createSurface": {"surfaceId": "order_receipt"}}
{"version": "v0.9", "updateComponents": {"surfaceId": "order_receipt", "components": [{"id": "root", "component": "OrderReceiptCard", "data": {"orderId": "ORD-PC-123456", "customerName": "Alex Morgan", "email": "alex@example.com", "shippingAddress": "123 Tech Way, San Jose, CA", "total": 1992.60, "status": "Confirmed & Scheduled for Assembly", "itemsCount": 7}}]}}
```

Always ensure component compatibility (e.g. AM5 CPU with AM5 Motherboard & DDR5 RAM), search store inventory with `search_pc_hardware`, and accompany UI surfaces with friendly helpful explanations!
''';

// ═══════════════════════════════════════════════════════════════
// 6. Main Screen
// ═══════════════════════════════════════════════════════════════

class PcBuilderMainScreen extends StatelessWidget {
  const PcBuilderMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = EnvLoader.getProvider();
    final initialLlm = LlmConfig(
      provider: provider != LlmProvider.none ? provider : LlmProvider.mistral,
      apiKey: EnvLoader.get('LLM_API_KEY'),
      model: EnvLoader.get('LLM_MODEL', defaultValue: 'mistral-medium-latest'),
      baseUrl: EnvLoader.get(
        'LLM_URL',
        defaultValue: 'https://api.mistral.ai/v1',
      ),
    );

    return Scaffold(
      body: GenuiMcpPlayground(
        initialLlmConfig: initialLlm.provider != LlmProvider.none
            ? initialLlm
            : null,
        customLocalTools: [
          SearchPcHardwareTool(),
          SubmitPcOrderTool(),
        ],
        initialEnabledTools: const [
          'search_pc_hardware',
          'submit_pc_order',
        ],
        initialSystemPrompt: pcBuilderGenuiSystemPrompt,
        genuiCatalog: buildPcBuilderGenuiCatalog(),
        showAgentInspector: true,
      ),
    );
  }
}

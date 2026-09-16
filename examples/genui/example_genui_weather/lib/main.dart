import 'dart:convert';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:genui/genui.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:genui_mcp_playground/genui_mcp_playground.dart';

import 'env_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const GenuiWeatherExampleApp());
}

class GenuiWeatherExampleApp extends StatelessWidget {
  const GenuiWeatherExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI Weather Generator Example',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0078D4),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2B88D8),
          brightness: Brightness.dark,
        ),
      ),
      home: const GenuiWeatherScreen(),
    );
  }
}

/// The weather channels the user can select in the generated form.
const List<String> _weatherChannels = [
  'temperature_2m',
  'wind_speed_10m',
  'wind_direction_10m',
  'cloud_cover',
  'precipitation',
];

const Map<String, int> _durationHours = {
  '24h': 24,
  '48h': 48,
  '72h': 72,
  '7 days': 168,
};

// ═══════════════════════════════════════════════════════════════
// 1. Weather forecast tool (Open-Meteo, no API key required)
// ═══════════════════════════════════════════════════════════════

/// A Dart-native MCP tool returning a structured weather forecast as JSON.
class WeatherForecastTool extends McpLocalTool {
  @override
  String get name => 'get_weather_forecast';

  @override
  String get description =>
      'Fetch an hourly weather forecast from Open-Meteo for a city. Returns '
      'JSON with a list of timestamps and the selected weather channels '
      '(temperature_2m, wind_speed_10m, wind_direction_10m, cloud_cover, '
      'precipitation).';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'city': {'type': 'string', 'description': 'City name, e.g. "Vienna".'},
      'hours': {
        'type': 'integer',
        'description': 'Number of forecast hours (default 24, max 168).',
      },
      'channels': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'The selected weather channels.',
      },
    },
    'required': ['city'],
  };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    try {
      final city = (arguments['city'] as String? ?? 'Vienna').trim();
      final hours = (arguments['hours'] as num?)?.toInt() ?? 24;
      final channels =
          (arguments['channels'] as List?)?.map((e) => e.toString()).toList() ??
          const ['temperature_2m'];

      // Resolve coordinates via geocoding.
      double lat = 48.2082;
      double lng = 16.3738;
      String resolvedName = city;
      final geoUrl =
          'https://geocoding-api.open-meteo.com/v1/search'
          '?name=${Uri.encodeComponent(city)}&count=1&language=en&format=json';
      final geoResp = await http
          .get(Uri.parse(geoUrl))
          .timeout(const Duration(seconds: 15));
      if (geoResp.statusCode == 200) {
        final geoData = jsonDecode(geoResp.body) as Map<String, dynamic>;
        final results = geoData['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final first = results.first as Map;
          lat = (first['latitude'] as num).toDouble();
          lng = (first['longitude'] as num).toDouble();
          resolvedName = '${first['name']}, ${first['country'] ?? ''}';
        }
      }

      // Ensure weather_code and temperature_2m are included for rich weather cards.
      final queryChannels = {
        ...channels,
        'weather_code',
        'temperature_2m',
      }.toList();

      final weatherUrl =
          'https://api.open-meteo.com/v1/forecast'
          '?latitude=$lat&longitude=$lng'
          '&hourly=${queryChannels.join(',')}'
          '&forecast_hours=$hours&timezone=auto';
      final resp = await http
          .get(Uri.parse(weatherUrl))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return MCPToolResult(
          content: [
            MCPContent(
              type: 'text',
              text: 'Error: Weather API failed (HTTP ${resp.statusCode}).',
            ),
          ],
          isError: true,
        );
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final hourly = data['hourly'] as Map<String, dynamic>?;
      final times = (hourly?['time'] as List?)?.cast<String>() ?? const [];

      final resultChannels = <Map<String, dynamic>>[];
      for (final channel in queryChannels) {
        final values = hourly?[channel] as List?;
        if (values == null) continue;
        resultChannels.add({
          'label': channel,
          'values': values.map((v) => (v as num).toDouble()).toList(),
        });
      }

      return MCPToolResult(
        content: [
          MCPContent(
            type: 'text',
            text: jsonEncode({
              'location': resolvedName,
              'times': times,
              'channels': resultChannels,
            }),
          ),
        ],
        isError: false,
      );
    } catch (e) {
      return MCPToolResult(
        content: [
          MCPContent(type: 'text', text: 'Weather execution error: $e'),
        ],
        isError: true,
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. Weather form catalog item
// ═══════════════════════════════════════════════════════════════

final weatherFormSchema = S.object(
  description: 'A form for requesting a weather forecast.',
  properties: {
    'title': S.string(description: 'Optional heading for the form.'),
  },
);

final weatherFormItem = CatalogItem(
  name: 'WeatherForm',
  dataSchema: weatherFormSchema,
  widgetBuilder: (itemContext) => _WeatherFormWidget(itemContext: itemContext),
);

class _WeatherFormWidget extends StatefulWidget {
  const _WeatherFormWidget({required this.itemContext});

  final CatalogItemContext itemContext;

  @override
  State<_WeatherFormWidget> createState() => _WeatherFormWidgetState();
}

class _WeatherFormWidgetState extends State<_WeatherFormWidget> {
  final TextEditingController _cityController = TextEditingController();
  String _duration = '24h';
  final Set<String> _channels = {'temperature_2m'};

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _submit() {
    final city = _cityController.text.trim();
    widget.itemContext.dispatchEvent(
      UserActionEvent(
        name: 'get_weather_forecast',
        sourceComponentId: widget.itemContext.id,
        context: <String, Object?>{
          'city': city.isEmpty ? 'Vienna' : city,
          'hours': _durationHours[_duration] ?? 24,
          'channels': _channels.toList(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _cityController,
          decoration: InputDecoration(
            labelText: 'City',
            hintText: 'e.g. Vienna',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _duration,
          decoration: InputDecoration(
            labelText: 'Forecast duration',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            for (final duration in _durationHours.keys)
              DropdownMenuItem(value: duration, child: Text(duration)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _duration = value);
          },
        ),
        const SizedBox(height: 12),
        Text('Weather channels', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final channel in _weatherChannels)
              FilterChip(
                label: Text(channel),
                selected: _channels.contains(channel),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _channels.add(channel);
                    } else {
                      _channels.remove(channel);
                    }
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.cloud_outlined),
          label: const Text('Get forecast'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 3. Weather chart catalog item (fl_chart multi-line + JPG export)
// ═══════════════════════════════════════════════════════════════

final weatherChartSchema = S.object(
  description: 'A weather forecast chart plus a textual list.',
  properties: {
    'title': S.string(),
    'times': S.list(items: S.string()),
    'channels': S.list(
      items: S.object(
        properties: {
          'label': S.string(),
          'values': S.list(items: S.number()),
        },
      ),
    ),
  },
  required: ['title', 'times', 'channels'],
);

final weatherChartItem = CatalogItem(
  name: 'WeatherChart',
  dataSchema: weatherChartSchema,
  widgetBuilder: (itemContext) => _WeatherChartWidget(itemContext: itemContext),
);

class _WeatherChartWidget extends StatefulWidget {
  final CatalogItemContext itemContext;

  const _WeatherChartWidget({required this.itemContext});

  @override
  State<_WeatherChartWidget> createState() => _WeatherChartWidgetState();
}

class _WeatherChartWidgetState extends State<_WeatherChartWidget> {
  final GlobalKey _chartBoundaryKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _exportChartToJpg(String title) async {
    setState(() => _isExporting = true);
    try {
      final boundary =
          _chartBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final uiImage = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await uiImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) return;

      final image = img.Image.fromBytes(
        width: uiImage.width,
        height: uiImage.height,
        bytes: byteData.buffer,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );

      final jpgBytes = img.encodeJpg(image, quality: 92);
      final sanitizedTitle = title.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]+'),
        '_',
      );
      final defaultFileName = '${sanitizedTitle}_chart.jpg';

      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Export Chart Picture (JPG)',
        fileName: defaultFileName,
        bytes: jpgBytes,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (savedUri != null) {
        final filePath = savedUri.path;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Chart exported to JPG: $filePath')),
                ],
              ),
              backgroundColor: const Color(0xFF107C41),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export chart image: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = Map<String, Object?>.from(widget.itemContext.data as Map);
    final title = data['title']?.toString() ?? 'Weather forecast';
    final times = (data['times'] as List?)?.cast<String>() ?? const <String>[];
    final rawChannels = (data['channels'] as List?) ?? const [];

    final channels = <({String label, List<double> values})>[];
    for (final raw in rawChannels) {
      final map = Map<String, Object?>.from(raw as Map);
      channels.add((
        label: map['label']?.toString() ?? '',
        values:
            (map['values'] as List?)
                ?.map((v) => (v as num).toDouble())
                .toList() ??
            const <double>[],
      ));
    }

    // Filter out categorical weather_code from continuous line chart lines.
    final chartChannels =
        channels.where((c) => c.label != 'weather_code').toList();

    // Channel lookups for individual card metrics
    final tempChannel = channels.where((c) => c.label.contains('temperature')).firstOrNull;
    final codeChannel = channels.where((c) => c.label == 'weather_code').firstOrNull;
    final rainChannel = channels.where((c) => c.label.contains('precipitation') || c.label.contains('rain')).firstOrNull;
    final windChannel = channels.where((c) => c.label.contains('wind_speed')).firstOrNull;
    final cloudChannel = channels.where((c) => c.label.contains('cloud_cover')).firstOrNull;

    final theme = Theme.of(context);
    const palette = [
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFFEF4444),
      Color(0xFF06B6D4),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _isExporting ? null : () => _exportChartToJpg(title),
              icon: _isExporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded, size: 16),
              label: const Text('Export Picture (JPG)'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RepaintBoundary(
          key: _chartBoundaryKey,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minY: _minValue(chartChannels) - 1,
                      maxY: _maxValue(chartChannels) + 1,
                      lineBarsData: [
                        for (var i = 0; i < chartChannels.length; i++)
                          LineChartBarData(
                            spots: [
                              for (
                                var j = 0;
                                j < chartChannels[i].values.length;
                                j++
                              )
                                FlSpot(j.toDouble(), chartChannels[i].values[j]),
                            ],
                            isCurved: true,
                            color: palette[i % palette.length],
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: false,
                              color: palette[i % palette.length].withValues(
                                alpha: 0.08,
                              ),
                            ),
                          ),
                      ],
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _bottomInterval(times.length),
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= times.length) {
                                return const Text('');
                              }
                              final timeInfo = _formatWeatherTime(times[index]);
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  timeInfo.time,
                                  style: const TextStyle(fontSize: 9),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < chartChannels.length; i++)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: palette[i % palette.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            chartChannels[i].label,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.wb_sunny_outlined,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hourly Weather Cards',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${times.length} intervals',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 260,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: GridView.builder(
                      padding: const EdgeInsets.only(right: 6, bottom: 4),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 165,
                            mainAxisExtent: 155,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: times.length,
                      itemBuilder: (context, index) {
                        final timeInfo = _formatWeatherTime(times[index]);
                        final weatherCode =
                            index < (codeChannel?.values.length ?? 0)
                                ? codeChannel?.values[index]
                                : null;
                        final temp =
                            index < (tempChannel?.values.length ?? 0)
                                ? tempChannel?.values[index]
                                : null;
                        final rain =
                            index < (rainChannel?.values.length ?? 0)
                                ? rainChannel?.values[index]
                                : null;
                        final wind =
                            index < (windChannel?.values.length ?? 0)
                                ? windChannel?.values[index]
                                : null;
                        final cloud =
                            index < (cloudChannel?.values.length ?? 0)
                                ? cloudChannel?.values[index]
                                : null;

                        final condition = _resolveWeatherCondition(
                          weatherCode: weatherCode,
                          temp: temp,
                          rain: rain,
                          cloud: cloud,
                          wind: wind,
                          isNight: timeInfo.isNight,
                        );

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date & Time
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${timeInfo.dayName} ${timeInfo.date}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: theme.textTheme.bodySmall?.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    timeInfo.time,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Weather Icon Picture & Condition
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: condition.color.withValues(
                                        alpha: 0.16,
                                      ),
                                    ),
                                    child: Icon(
                                      condition.icon,
                                      color: condition.color,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      condition.label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: condition.color,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              const Divider(height: 1, thickness: 0.5),
                              const SizedBox(height: 4),
                              // Selected channel values
                              Expanded(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    for (
                                      var i = 0;
                                      i < chartChannels.length;
                                      i++
                                    ) ...[
                                      if (index <
                                          chartChannels[i].values.length)
                                        () {
                                          final c = chartChannels[i];
                                          final metric = _formatMetric(
                                            c.label,
                                            c.values[index],
                                            palette[i % palette.length],
                                          );
                                          return Row(
                                            children: [
                                              Icon(
                                                metric.icon,
                                                size: 11,
                                                color: metric.color,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                metric.label,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                metric.value,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          );
                                        }(),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

({IconData icon, String label, String value, Color color}) _formatMetric(
  String channel,
  double val,
  Color fallbackColor,
) {
  final clean = channel.toLowerCase();
  if (clean.contains('temperature')) {
    return (
      icon: Icons.thermostat_rounded,
      label: 'Temp',
      value: '${val.toStringAsFixed(1)}°C',
      color: const Color(0xFF3B82F6),
    );
  }
  if (clean.contains('precipitation') || clean.contains('rain')) {
    return (
      icon: Icons.water_drop_rounded,
      label: 'Rain',
      value: '${val.toStringAsFixed(1)} mm',
      color: const Color(0xFF8B5CF6),
    );
  }
  if (clean.contains('wind_speed')) {
    return (
      icon: Icons.air_rounded,
      label: 'Wind',
      value: '${val.toStringAsFixed(1)} km/h',
      color: const Color(0xFF10B981),
    );
  }
  if (clean.contains('wind_direction')) {
    return (
      icon: Icons.explore_outlined,
      label: 'Dir',
      value: '${val.toStringAsFixed(0)}°',
      color: const Color(0xFF06B6D4),
    );
  }
  if (clean.contains('cloud')) {
    return (
      icon: Icons.cloud_outlined,
      label: 'Cloud',
      value: '${val.toStringAsFixed(0)}%',
      color: const Color(0xFFF59E0B),
    );
  }
  return (
    icon: Icons.speed_rounded,
    label: channel.replaceAll('_', ' '),
    value: val.toStringAsFixed(1),
    color: fallbackColor,
  );
}

({String time, String date, String dayName, bool isNight}) _formatWeatherTime(
  String iso,
) {
  try {
    final dt = DateTime.parse(iso);
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = weekdays[dt.weekday - 1];
    final isNight = dt.hour < 6 || dt.hour >= 21;
    return (
      time: '$hour:$min',
      date: '$day.$month',
      dayName: dayName,
      isNight: isNight,
    );
  } catch (_) {
    final short = iso.length > 5 ? iso.substring(iso.length - 5) : iso;
    return (time: short, date: '', dayName: '', isNight: false);
  }
}

({IconData icon, Color color, String label}) _resolveWeatherCondition({
  double? weatherCode,
  double? temp,
  double? rain,
  double? cloud,
  double? wind,
  bool isNight = false,
}) {
  if (weatherCode != null) {
    final code = weatherCode.toInt();
    if (code == 0) {
      return (
        icon: isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
        color: isNight ? const Color(0xFF818CF8) : const Color(0xFFF59E0B),
        label: isNight ? 'Clear' : 'Sunny',
      );
    }
    if (code == 1 || code == 2) {
      return (
        icon: isNight ? Icons.nights_stay_rounded : Icons.wb_cloudy_rounded,
        color: isNight ? const Color(0xFF94A3B8) : const Color(0xFF38BDF8),
        label: 'Partly Cloudy',
      );
    }
    if (code == 3) {
      return (
        icon: Icons.cloud_rounded,
        color: const Color(0xFF64748B),
        label: 'Overcast',
      );
    }
    if (code == 45 || code == 48) {
      return (
        icon: Icons.cloud_queue_rounded,
        color: const Color(0xFF94A3B8),
        label: 'Foggy',
      );
    }
    if (code >= 51 && code <= 57) {
      return (
        icon: Icons.grain_rounded,
        color: const Color(0xFF38BDF8),
        label: 'Drizzle',
      );
    }
    if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) {
      return (
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF3B82F6),
        label: 'Rain',
      );
    }
    if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
      return (
        icon: Icons.ac_unit_rounded,
        color: const Color(0xFF06B6D4),
        label: 'Snow',
      );
    }
    if (code >= 95 && code <= 99) {
      return (
        icon: Icons.thunderstorm_rounded,
        color: const Color(0xFF8B5CF6),
        label: 'Thunderstorm',
      );
    }
  }

  // Heuristic fallbacks:
  if (rain != null && rain > 0.2) {
    return (
      icon: Icons.water_drop_rounded,
      color: const Color(0xFF3B82F6),
      label: 'Rain',
    );
  }
  if (cloud != null && cloud > 65) {
    return (
      icon: Icons.cloud_rounded,
      color: const Color(0xFF64748B),
      label: 'Cloudy',
    );
  }
  if (cloud != null && cloud > 25) {
    return (
      icon: isNight ? Icons.nights_stay_rounded : Icons.wb_cloudy_rounded,
      color: isNight ? const Color(0xFF94A3B8) : const Color(0xFF38BDF8),
      label: 'Partly Cloudy',
    );
  }
  if (temp != null && temp < 0) {
    return (
      icon: Icons.ac_unit_rounded,
      color: const Color(0xFF06B6D4),
      label: 'Freezing',
    );
  }
  return (
    icon: isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
    color: isNight ? const Color(0xFF818CF8) : const Color(0xFFF59E0B),
    label: isNight ? 'Clear' : 'Sunny',
  );
}

double _minValue(List<({String label, List<double> values})> channels) {
  var min = double.infinity;
  for (final channel in channels) {
    for (final value in channel.values) {
      if (value < min) min = value;
    }
  }
  return min.isFinite ? min : 0;
}

double _maxValue(List<({String label, List<double> values})> channels) {
  var max = double.negativeInfinity;
  for (final channel in channels) {
    for (final value in channel.values) {
      if (value > max) max = value;
    }
  }
  return max.isFinite ? max : 1;
}

double _bottomInterval(int length) {
  if (length <= 0) return 1;
  if (length <= 12) return 1;
  if (length <= 48) return 6;
  return 12;
}

// ═══════════════════════════════════════════════════════════════
// 4. Catalog + example screen
// ═══════════════════════════════════════════════════════════════

/// Builds a GenUI catalog with the basic widgets plus the weather form and
/// weather chart items.
Catalog buildWeatherGenuiCatalog() {
  final base = BasicCatalogItems.asNoAssetCatalog();
  return base.copyWith(newItems: [weatherFormItem, weatherChartItem]);
}

/// The system prompt instructing the model how to use weather GenUI widgets, tools, and build/attachment analysis.
const String weatherGenuiSystemPrompt = '''
You are an intelligent GenUI AI assistant backed by live MCP tools, interactive Flutter components, and diagnostic tools.

Capabilities & Component Rules:
- Weather Capabilities:
  - You have access to custom GenUI components: "WeatherForm" and "WeatherChart".
  - You have the `get_weather_forecast` tool for real-time and hourly weather forecasts.
  - When the user asks for a weather forecast without city/parameters, render a "WeatherForm" component.
  - When the user submits a weather form or provides parameters (city, hours, channels):
    1. Invoke the `get_weather_forecast` tool immediately with those arguments.
    2. Render a "WeatherChart" component with the forecast data:
       {
         "title": "Weather forecast for <location>",
         "times": [<list of ISO timestamps from tool result>],
         "channels": [
           { "label": "<channel_name>", "values": [<list of numeric values from tool result>] }
         ]
       }

- Build Analysis & Attachments:
  - You are fully equipped to analyze, diagnose, and inspect attached builds, build logs, stack traces, compiler output, screenshots, and source code files.
  - When the user attaches a file/image or asks to analyze a build/failure:
    1. Examine the attached build output, errors, or logs thoroughly.
    2. Identify root causes, build breakages, missing dependencies, or syntax/runtime errors.
    3. Provide clear, structured diagnosis and step-by-step fix recommendations.

General Guidelines:
- Be concise, direct, and actionable.
- Combine interactive UI components with insightful explanations whenever appropriate.
''';

/// The GenUI-based weather example screen using the standard McpPlayground view.
class GenuiWeatherScreen extends StatelessWidget {
  /// Creates a [GenuiWeatherScreen].
  const GenuiWeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final initialLlm = LlmConfig(
      provider: EnvLoader.getProvider(),
      model: EnvLoader.get('LLM_MODEL', defaultValue: 'gpt-4o'),
      apiKey: EnvLoader.get('LLM_API_KEY'),
      baseUrl: EnvLoader.get('LLM_URL'),
    );

    return GenuiMcpPlayground(
      initialLlmConfig: initialLlm.provider != LlmProvider.none
          ? initialLlm
          : null,
      customLocalTools: [WeatherForecastTool()],
      initialEnabledTools: const ['get_weather_forecast'],
      initialSystemPrompt: weatherGenuiSystemPrompt,
      genuiCatalog: buildWeatherGenuiCatalog(),
      showAgentInspector: true,
    );
  }
}

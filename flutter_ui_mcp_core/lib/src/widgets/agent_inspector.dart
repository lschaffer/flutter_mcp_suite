import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';
import '../../playground_controller.dart';
import '../services/model_pricing_service.dart';

class AgentInspector extends StatefulWidget {
  final PlaygroundController controller;
  final VoidCallback? onClose;

  const AgentInspector({
    super.key,
    required this.controller,
    this.onClose,
  });

  @override
  State<AgentInspector> createState() => _AgentInspectorState();
}

class _AgentInspectorState extends State<AgentInspector> {
  bool _logsAscending = true;
  DateTime? _logsClearedAt;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.controller.activeModelPrice == null &&
          !widget.controller.isLoadingPrice) {
        widget.controller.fetchActiveModelPrice();
      }
    });
  }

  @override
  void didUpdateWidget(AgentInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            widget.controller.activeModelPrice == null &&
            !widget.controller.isLoadingPrice) {
          widget.controller.fetchActiveModelPrice();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final sec = dt.second.toString().padLeft(2, '0');
    return '$hour:$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final config = widget.controller.activeLlmConfig;
    final messages = widget.controller.messages;
    final priceInfo = widget.controller.activeModelPrice;
    final isLoadingPrice = widget.controller.isLoadingPrice;
    final isLocal = ModelPricingService.isLocalOrFree(config);

    // Calculate stats
    int toolCallsCount = 0;
    int sentCharsCount = 0;
    int receivedCharsCount = 0;

    if (widget.controller.systemPrompt.isNotEmpty) {
      sentCharsCount += widget.controller.systemPrompt.length;
    }

    for (final m in messages) {
      if (m.type == MessageType.toolCall) {
        toolCallsCount++;
      }
      if (m.role == ChatRole.user) {
        sentCharsCount += m.content.length;
        if (m.attachments != null) {
          for (final a in m.attachments!) {
            final aSize = a.size ?? a.bytes?.length ?? 0;
            sentCharsCount += aSize;
          }
        }
      } else if (m.role == ChatRole.tool) {
        sentCharsCount += m.content.length;
      } else if (m.role == ChatRole.assistant) {
        if (m.type != MessageType.toolCall) {
          receivedCharsCount += m.content.length;
        }
      }
    }

    final estInputTokens = (sentCharsCount / 3.8).round();
    final estOutputTokens = (receivedCharsCount / 3.8).round();
    final estTotalTokens = estInputTokens + estOutputTokens;
    final maxContext = (priceInfo?.contextWindow != null &&
            priceInfo!.contextWindow! > 0)
        ? priceInfo.contextWindow!
        : (isLocal ? 131072 : 1048576);
    final tokenProgress =
        (estTotalTokens / maxContext.toDouble()).clamp(0.0, 1.0);
    final isWarning = tokenProgress > 0.85;

    double estCost = 0.0;
    if (!isLocal &&
        priceInfo != null &&
        priceInfo.hasPricing &&
        !priceInfo.isFree) {
      estCost = (estInputTokens / 1000000.0) * priceInfo.inputPer1MUsd +
          (estOutputTokens / 1000000.0) * priceInfo.outputPer1MUsd;
    }

    // Build log entries
    final entries = <_LogEntry>[];
    for (final msg in messages) {
      if (_logsClearedAt != null && !msg.timestamp.isAfter(_logsClearedAt!)) {
        continue;
      }
      switch (msg.role) {
        case ChatRole.system:
          final content = msg.content.trim();
          if (content.isNotEmpty) {
            final oneLine = content.replaceAll('\n', ' ');
            final preview = oneLine.length > 80
                ? '${oneLine.substring(0, 80)}...'
                : oneLine;
            entries.add(
              _LogEntry(
                type: 'system',
                text: 'System prompt: $preview',
                details: content,
                timestamp: msg.timestamp,
              ),
            );
          }
          break;
        case ChatRole.user:
          final content = msg.content.trim();
          if (content.isNotEmpty) {
            entries.add(
              _LogEntry(
                type: 'user',
                text: 'User prompt: $content',
                details: content.length > 80 ? content : null,
                timestamp: msg.timestamp,
              ),
            );
          }
          break;
        case ChatRole.assistant:
          final content = msg.content.trim();
          if (content.isNotEmpty) {
            if (msg.type == MessageType.toolCall) {
              final argsRaw = msg.toolArguments != null
                  ? jsonEncode(msg.toolArguments)
                  : '';
              final argsPreview = argsRaw.length > 100
                  ? '${argsRaw.substring(0, 100)}...'
                  : argsRaw;
              final toolText = argsPreview.isNotEmpty
                  ? 'Called tool: ${msg.toolName}($argsPreview)'
                  : 'Called tool: ${msg.toolName ?? 'Tool'}';
              entries.add(
                _LogEntry(
                  type: 'tool_call',
                  text: toolText,
                  details: argsRaw.isNotEmpty ? argsRaw : null,
                  timestamp: msg.timestamp,
                ),
              );
            } else {
              final oneLine = content.replaceAll('\n', ' ');
              final preview = oneLine.length > 80
                  ? '${oneLine.substring(0, 80)}...'
                  : oneLine;
              entries.add(
                _LogEntry(
                  type: 'assistant',
                  text: preview,
                  details: content.length > 80 ? content : null,
                  timestamp: msg.timestamp,
                ),
              );
            }
          }
          break;
        case ChatRole.tool:
          final resultText = msg.content.trim();
          final oneLine = resultText.replaceAll('\n', ' ');
          final resultPreview = oneLine.length > 150
              ? '${oneLine.substring(0, 150)}...'
              : oneLine;
          final displayText = resultPreview.isNotEmpty
              ? '→ $resultPreview'
              : 'Executed.';
          entries.add(
            _LogEntry(
              type: 'tool_response',
              text: displayText,
              details: resultText.isNotEmpty ? resultText : null,
              timestamp: msg.timestamp,
            ),
          );
          break;
      }
    }

    final displayEntries = _logsAscending ? entries : entries.reversed.toList();

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: Color(0xFFF97316)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Agent Inspector',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.controller.isGenerating
                        ? Colors.green
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.controller.isGenerating ? 'Processing' : 'Idle',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                if (widget.onClose != null || Navigator.of(context).canPop()) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Close',
                    onPressed: () {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Model Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Model',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            config.model.isNotEmpty
                                ? config.model
                                : 'No Model selected',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Provider: ${config.provider.displayName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Token Usage Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Token Usage',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '$estTotalTokens / $maxContext',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: tokenProgress,
                              color: isWarning
                                  ? Colors.redAccent
                                  : const Color(0xFFF97316),
                              backgroundColor: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.2),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isLoadingPrice) ...[
                                      Flexible(
                                        child: Text(
                                          'Resolving price...',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: theme.colorScheme
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.7),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ] else if (isLocal) ...[
                                      Text(
                                        '0 (Local / Ollama)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: Colors.green.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          '0',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ] else if (priceInfo != null &&
                                        priceInfo.hasPricing) ...[
                                      Flexible(
                                        child: Text(
                                          'Price/1M: \$${priceInfo.inputPer1MUsd.toStringAsFixed(2)} in / \$${priceInfo.outputPer1MUsd.toStringAsFixed(2)} out',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.7),
                                                fontSize: 11,
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
                                          color: Colors.green.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: Colors.green.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'live',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      Flexible(
                                        child: Text(
                                          'Price: Unknown',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.7),
                                                fontSize: 11,
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
                                          color: theme.colorScheme
                                              .outlineVariant
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: theme.colorScheme
                                                .outlineVariant
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: const Text(
                                          'unknown',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cost: \$${estCost.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF97316),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tool Calls',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$toolCallsCount',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sent Chars',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$sentCharsCount',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Live Execution Logs
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Live Execution Logs',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _logsAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                        ),
                        tooltip: _logsAscending ? 'Ascending' : 'Descending',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            _logsAscending = !_logsAscending;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear_all),
                        tooltip: 'Clear logs',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            _logsClearedAt = DateTime.now();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: displayEntries.isEmpty
                            ? const Center(
                                child: Text(
                                  'No execution logs.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8.0),
                                itemCount: displayEntries.length,
                                itemBuilder: (ctx, idx) {
                                  final entry = displayEntries[idx];
                                  IconData icon = Icons.info_outline;
                                  Color iconColor = Colors.grey;

                                  if (entry.type == 'system') {
                                    icon = Icons.security;
                                    iconColor = Colors.orange;
                                  } else if (entry.type == 'user') {
                                    icon = Icons.person;
                                    iconColor = const Color(0xFF7C3AED);
                                  } else if (entry.type == 'tool_call') {
                                    icon = Icons.build;
                                    iconColor = Colors.amber;
                                  } else if (entry.type == 'tool_response') {
                                    icon = Icons.check_circle;
                                    iconColor = Colors.green;
                                  } else if (entry.type == 'assistant') {
                                    icon = Icons.smart_toy;
                                    iconColor = Colors.blue;
                                  }
                                  return Material(
                                    type: MaterialType.transparency,
                                    child: ListTile(
                                      dense: true,
                                      leading: Icon(
                                        icon,
                                        size: 16,
                                        color: iconColor,
                                      ),
                                      title: Text(
                                        entry.text,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      subtitle: Text(
                                        _formatTimestamp(entry.timestamp),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      trailing: entry.details != null
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.open_in_full,
                                                size: 14,
                                              ),
                                              tooltip: 'Expand log details',
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (c) => AlertDialog(
                                                    title: Text(
                                                      entry.type == 'system'
                                                          ? 'System Prompt'
                                                          : 'Log Details',
                                                    ),
                                                    content:
                                                        SingleChildScrollView(
                                                          child: SelectableText(
                                                            entry.details!,
                                                            style:
                                                                const TextStyle(
                                                                  fontFamily:
                                                                      'monospace',
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                        ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(c),
                                                        child: const Text(
                                                          'Close',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            )
                                          : null,
                                      onTap: entry.details != null
                                          ? () {
                                              showDialog(
                                                context: context,
                                                builder: (c) => AlertDialog(
                                                  title: Text(
                                                    entry.type == 'system'
                                                        ? 'System Prompt'
                                                        : 'Log Details',
                                                  ),
                                                  content: SingleChildScrollView(
                                                    child: SelectableText(
                                                      entry.details!,
                                                      style: const TextStyle(
                                                        fontFamily: 'monospace',
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(c),
                                                      child: const Text('Close'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          : null,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
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

class _LogEntry {
  final String type;
  final String text;
  final String? details;
  final DateTime timestamp;

  _LogEntry({
    required this.type,
    required this.text,
    this.details,
    required this.timestamp,
  });
}

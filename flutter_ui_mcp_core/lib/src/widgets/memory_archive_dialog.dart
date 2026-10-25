import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';
import '../../playground_controller.dart';

/// Dialog for browsing and searching through episodic memory archives stashed during conversation context compression.
class MemoryArchiveDialog extends StatefulWidget {
  final PlaygroundController controller;

  const MemoryArchiveDialog({super.key, required this.controller});

  static Future<void> show(BuildContext context, PlaygroundController controller) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    if (isMobile) {
      return showDialog(
        context: context,
        builder: (ctx) => Dialog.fullscreen(
          child: MemoryArchiveDialog(controller: controller),
        ),
      );
    }
    return showDialog(
      context: context,
      builder: (ctx) => MemoryArchiveDialog(controller: controller),
    );
  }

  @override
  State<MemoryArchiveDialog> createState() => _MemoryArchiveDialogState();
}

class _MemoryArchiveDialogState extends State<MemoryArchiveDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant MemoryArchiveDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final archive = widget.controller.memoryArchive;

    final filtered = _searchQuery.trim().isEmpty
        ? archive
        : widget.controller.episodicMemoryStore.search(_searchQuery);

    final totalTokensArchived = archive.fold<int>(
      0,
      (sum, entry) =>
          sum +
          entry.rawMessages.fold<int>(
            0,
            (s, m) => s + (m.content.length / 4).round(),
          ),
    );

    final isMobile = MediaQuery.sizeOf(context).width < 600;

    Widget buildBody() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.psychology_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Episodic Memory Archive',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${archive.length} compressed episode(s) • ~$totalTokensArchived tokens preserved',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Search bar
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search archived turns, prompts, or tool outputs...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val);
            },
          ),
          const SizedBox(height: 12),

          // Content List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_edu_outlined,
                          size: 48,
                          color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No archived memories match "$_searchQuery".'
                              : 'No memories archived yet.\nOlder turns are automatically preserved here when conversation context compresses.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final entry = filtered[idx];
                      return _buildMemoryCard(entry, theme);
                    },
                  ),
          ),

          const SizedBox(height: 12),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Memory Retrieval Tool ("retrieve_memory") is active.',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (archive.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                  label: const Text('Clear Memory', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    widget.controller.clearMemoryArchive();
                    setState(() {});
                  },
                ),
            ],
          ),
        ],
      );
    }

    if (isMobile) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Episodic Memory Archive',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${archive.length} compressed episode(s) • ~$totalTokensArchived tokens',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: buildBody(),
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: buildBody(),
        ),
      ),
    );
  }

  Widget _buildMemoryCard(EpisodicMemoryEntry entry, ThemeData theme) {
    final entryTokens = entry.rawMessages.fold<int>(
      0,
      (s, m) => s + (m.content.length / 4).round(),
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Text(
            '${entry.startTurnIndex}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
        title: Text(
          entry.summary,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Preserved ${entry.timestamp.toLocal().toString().split('.').first} • ~$entryTokens tokens',
          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Turn Raw Messages (${entry.rawMessages.length}):',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 14),
                      tooltip: 'Copy Turn Content',
                      onPressed: () {
                        final content = entry.rawMessages
                            .map((m) => '[${m.role.name.toUpperCase()}]: ${m.content}')
                            .join('\n\n');
                        Clipboard.setData(ClipboardData(text: content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Turn content copied to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...entry.rawMessages.map((msg) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        '[${msg.role.name.toUpperCase()}]: ${msg.content}',
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

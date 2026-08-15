import 'package:flutter/material.dart';
import '../../playground_controller.dart';
import '../models/workflow_def.dart';

/// Dialog for browsing, loading, and deleting saved Workflow presets.
class WorkflowLoadDialog extends StatefulWidget {
  final PlaygroundController controller;

  const WorkflowLoadDialog({
    super.key,
    required this.controller,
  });

  @override
  State<WorkflowLoadDialog> createState() => _WorkflowLoadDialogState();
}

class _WorkflowLoadDialogState extends State<WorkflowLoadDialog> {
  late List<PlaygroundWorkflow> _workflows;

  @override
  void initState() {
    super.initState();
    _workflows = List.of(widget.controller.workflows);
  }

  void _reload() {
    setState(() {
      _workflows = List.of(widget.controller.workflows);
    });
  }

  Future<void> _deleteWorkflow(PlaygroundWorkflow workflow) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Workflow'),
        content: Text('Are you sure you want to delete "${workflow.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.controller.deleteWorkflow(workflow.id);
      _reload();
    }
  }

  void _selectWorkflow(PlaygroundWorkflow workflow) {
    widget.controller.setLoadedWorkflowId(workflow.id);
    Navigator.pop(context, workflow);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.alt_route, color: Color(0xFF0067C0)),
          SizedBox(width: 8),
          Text('Load Workflow Preset'),
        ],
      ),
      content: SizedBox(
        width: isWide ? 620 : double.maxFinite,
        height: 480,
        child: _workflows.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.alt_route,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No saved workflows yet.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Configure your prompts and tools, then press Save Workflow to create one.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: _workflows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final workflow = _workflows[index];
                  final isLoaded = widget.controller.loadedWorkflowId == workflow.id;
                  final dateStr =
                      '${workflow.updatedAt.year}-${workflow.updatedAt.month.toString().padLeft(2, '0')}-${workflow.updatedAt.day.toString().padLeft(2, '0')}';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: isLoaded
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.alt_route,
                        size: 20,
                        color: isLoaded
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            workflow.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isLoaded)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Loaded',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (workflow.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            workflow.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${workflow.steps.length} step(s)',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const Text(' • '),
                            Text(
                              '${workflow.enabledToolNames.length} tool(s)',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            if (workflow.activeSkillName != null) ...[
                              const Text(' • '),
                              Text(
                                'Skill: ${workflow.activeSkillName}',
                                style: const TextStyle(fontSize: 11, color: Colors.amber),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip: 'Delete Workflow',
                          onPressed: () => _deleteWorkflow(workflow),
                        ),
                        const SizedBox(width: 4),
                        FilledButton(
                          onPressed: () => _selectWorkflow(workflow),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: const Text('Load'),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

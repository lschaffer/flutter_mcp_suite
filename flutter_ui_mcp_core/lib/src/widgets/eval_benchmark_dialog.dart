import 'package:material_ui/material_ui.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';
import '../../playground_controller.dart';

/// Interactive benchmark dialog to run evaluation suites and test cases against the agent.
class EvalBenchmarkDialog extends StatefulWidget {
  final PlaygroundController controller;

  const EvalBenchmarkDialog({super.key, required this.controller});

  static Future<void> show(BuildContext context, PlaygroundController controller) {
    return showDialog(
      context: context,
      builder: (ctx) => EvalBenchmarkDialog(controller: controller),
    );
  }

  @override
  State<EvalBenchmarkDialog> createState() => _EvalBenchmarkDialogState();
}

class _EvalBenchmarkDialogState extends State<EvalBenchmarkDialog> {
  final TextEditingController _taskNameCtrl = TextEditingController();
  final TextEditingController _promptCtrl = TextEditingController();
  final TextEditingController _expectedCtrl = TextEditingController();

  @override
  void dispose() {
    _taskNameCtrl.dispose();
    _promptCtrl.dispose();
    _expectedCtrl.dispose();
    super.dispose();
  }

  Future<void> _runBenchmark() async {
    final evalCtrl = widget.controller.evalController;
    final allTools = [
      ...widget.controller.localTools.map((t) => t.toMCPTool()),
      ...widget.controller.externalTools,
    ];

    await evalCtrl.runEvaluationSuite(
      llmConfig: widget.controller.activeLlmConfig,
      tools: allTools,
      suiteName: 'Agent Benchmark (${widget.controller.activeLlmConfig.model})',
    );
    if (mounted) setState(() {});
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Eval Test Task', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _taskNameCtrl,
              decoration: const InputDecoration(labelText: 'Task Name'),
            ),
            TextField(
              controller: _promptCtrl,
              decoration: const InputDecoration(labelText: 'Prompt / Instruction'),
              maxLines: 2,
            ),
            TextField(
              controller: _expectedCtrl,
              decoration: const InputDecoration(
                labelText: 'Expected Substrings (comma separated)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = _taskNameCtrl.text.trim();
              final prompt = _promptCtrl.text.trim();
              final expected = _expectedCtrl.text.trim();
              if (name.isNotEmpty && prompt.isNotEmpty) {
                widget.controller.evalController.addTask(
                  EvalTask(
                    id: 'task-${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    prompt: prompt,
                    expectedOutput: expected.isNotEmpty ? expected : null,
                  ),
                );
                _taskNameCtrl.clear();
                _promptCtrl.clear();
                _expectedCtrl.clear();
                Navigator.of(ctx).pop();
                setState(() {});
              }
            },
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final evalCtrl = widget.controller.evalController;
    final isEvaluating = evalCtrl.isEvaluating;
    final report = evalCtrl.lastReport;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    child: Icon(
                      Icons.speed_outlined,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agent Evaluation & Benchmarking',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Target: ${widget.controller.activeLlmConfig.model} (${widget.controller.activeLlmConfig.provider.name})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Benchmark Summary Card
              if (report != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: report.passRate >= 0.8
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: report.passRate >= 0.8
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(
                        'Pass Rate',
                        '${(report.passRate * 100).toStringAsFixed(1)}%',
                        report.passRate >= 0.8 ? Colors.green : Colors.orange,
                      ),
                      _buildMetric(
                        'Passed / Total',
                        '${report.passedTasks} / ${report.totalTasks}',
                        theme.colorScheme.onSurface,
                      ),
                      _buildMetric(
                        'Total Tokens',
                        '${report.totalTokens}',
                        theme.colorScheme.onSurface,
                      ),
                      _buildMetric(
                        'Avg Latency',
                        '${report.averageDurationMs} ms',
                        theme.colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Running progress
              if (isEvaluating) ...[
                LinearProgressIndicator(value: evalCtrl.progress),
                const SizedBox(height: 6),
                Text(
                  'Evaluating: ${evalCtrl.currentTaskName ?? "running..."} (${(evalCtrl.progress * 100).toInt()}%)',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Task List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Evaluation Tasks (${evalCtrl.tasks.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Task', style: TextStyle(fontSize: 12)),
                        onPressed: isEvaluating ? null : _showAddTaskDialog,
                      ),
                      TextButton(
                        onPressed: isEvaluating
                            ? null
                            : () {
                                evalCtrl.resetTasksToDefault();
                                setState(() {});
                              },
                        child: const Text('Reset', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Task Items
              Expanded(
                child: ListView.separated(
                  itemCount: evalCtrl.tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final task = evalCtrl.tasks[idx];
                    final result = report?.results.firstWhere(
                      (r) => r.taskId == task.id,
                      orElse: () => EvalResult(
                        taskId: task.id,
                        isSuccess: false,
                        score: 0.0,
                        rationale: 'Pending execution',
                        durationMs: 0,
                      ),
                    );

                    final hasResult = report != null &&
                        report.results.any((r) => r.taskId == task.id);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: hasResult
                            ? Icon(
                                result!.isSuccess
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: result.isSuccess ? Colors.green : Colors.red,
                              )
                            : const Icon(Icons.hourglass_empty, size: 20),
                        title: Text(task.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          task.prompt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: hasResult
                            ? Text(
                                '${result!.durationMs} ms',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16),
                                onPressed: () {
                                  evalCtrl.removeTask(task.id);
                                  setState(() {});
                                },
                              ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              // Run Benchmark Action
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: isEvaluating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(isEvaluating ? 'Evaluating Benchmark...' : 'Run Benchmark'),
                  onPressed: isEvaluating ? null : _runBenchmark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}

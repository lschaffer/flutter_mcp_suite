/// Represents the execution state of an autonomous child/sub-agent delegated by the main agent.
class SubAgentExecution {
  /// Unique identifier of the sub-agent execution.
  final String id;

  /// High-level task assigned to the sub-agent.
  final String task;

  /// Delegation recursion depth (0 = top-level agent, 1 = direct child, etc.).
  final int depth;

  /// When the sub-agent started execution.
  final DateTime startedAt;

  /// When the sub-agent completed execution, or null if still running.
  DateTime? completedAt;

  /// Current execution status: 'running', 'completed', 'failed', or 'cancelled'.
  String status;

  /// Final output produced by the sub-agent.
  String? result;

  /// Error message if the sub-agent failed.
  String? error;

  /// Stream of progress notifications or milestone messages.
  final List<String> progressUpdates;

  /// Optional list of tool calls performed by the sub-agent.
  final List<String> toolCalls;

  SubAgentExecution({
    required this.id,
    required this.task,
    required this.depth,
    required this.startedAt,
    this.completedAt,
    this.status = 'running',
    this.result,
    this.error,
    List<String>? progressUpdates,
    List<String>? toolCalls,
  })  : progressUpdates = progressUpdates ?? [],
        toolCalls = toolCalls ?? [];

  bool get isRunning => status == 'running';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  Duration get duration =>
      (completedAt ?? DateTime.now()).difference(startedAt);

  void addProgress(String update) {
    progressUpdates.add(update);
  }

  void addToolCall(String toolCall) {
    toolCalls.add(toolCall);
  }

  void complete(String finalResult) {
    status = 'completed';
    result = finalResult;
    completedAt = DateTime.now();
  }

  void fail(String errorMessage) {
    status = 'failed';
    error = errorMessage;
    completedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'task': task,
        'depth': depth,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'status': status,
        'result': result,
        'error': error,
        'progressUpdates': progressUpdates,
        'toolCalls': toolCalls,
      };

  factory SubAgentExecution.fromJson(Map<String, dynamic> json) =>
      SubAgentExecution(
        id: json['id'] as String,
        task: json['task'] as String,
        depth: (json['depth'] as num?)?.toInt() ?? 1,
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
            DateTime.now(),
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
        status: json['status'] as String? ?? 'completed',
        result: json['result'] as String?,
        error: json['error'] as String?,
        progressUpdates: (json['progressUpdates'] as List?)
            ?.map((e) => e.toString())
            .toList(),
        toolCalls:
            (json['toolCalls'] as List?)?.map((e) => e.toString()).toList(),
      );

  @override
  String toString() =>
      'SubAgentExecution(id: $id, depth: $depth, status: $status, task: ${task.length > 40 ? '${task.substring(0, 40)}...' : task})';
}

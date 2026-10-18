import '../models/models.dart';

/// Defines a test case/task for evaluating agent performance.
class EvalTask {
  final String id;
  final String name;
  final String description;
  final String prompt;
  final String? expectedOutput;
  final List<String>? expectedTools;
  final String? rubric;
  final Map<String, dynamic>? metadata;

  const EvalTask({
    required this.id,
    required this.name,
    this.description = '',
    required this.prompt,
    this.expectedOutput,
    this.expectedTools,
    this.rubric,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'prompt': prompt,
        if (expectedOutput != null) 'expectedOutput': expectedOutput,
        if (expectedTools != null) 'expectedTools': expectedTools,
        if (rubric != null) 'rubric': rubric,
        if (metadata != null) 'metadata': metadata,
      };

  factory EvalTask.fromJson(Map<String, dynamic> json) => EvalTask(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        prompt: json['prompt'] as String? ?? '',
        expectedOutput: json['expectedOutput'] as String?,
        expectedTools: (json['expectedTools'] as List?)?.cast<String>(),
        rubric: json['rubric'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// Outcome of evaluating a single [EvalTask].
class EvalResult {
  final String taskId;
  final bool isSuccess;
  final double score; // 0.0 to 1.0
  final String rationale;
  final int totalTokens;
  final int durationMs;
  final List<ChatMessage> trajectory;

  const EvalResult({
    required this.taskId,
    required this.isSuccess,
    required this.score,
    required this.rationale,
    this.totalTokens = 0,
    this.durationMs = 0,
    this.trajectory = const [],
  });

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'isSuccess': isSuccess,
        'score': score,
        'rationale': rationale,
        'totalTokens': totalTokens,
        'durationMs': durationMs,
        'trajectory': trajectory.map((m) => m.toJson()).toList(),
      };

  factory EvalResult.fromJson(Map<String, dynamic> json) => EvalResult(
        taskId: json['taskId'] as String,
        isSuccess: json['isSuccess'] as bool? ?? false,
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        rationale: json['rationale'] as String? ?? '',
        totalTokens: json['totalTokens'] as int? ?? 0,
        durationMs: json['durationMs'] as int? ?? 0,
        trajectory: (json['trajectory'] as List? ?? [])
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

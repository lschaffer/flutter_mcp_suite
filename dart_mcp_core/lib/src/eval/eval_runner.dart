import '../agents/agents_engine.dart';
import '../models/models.dart';
import 'eval_grader.dart';
import 'eval_task.dart';

/// Aggregated report of an evaluation suite run.
class EvalReport {
  final String suiteName;
  final int totalTasks;
  final int passedTasks;
  final int failedTasks;
  final double passRate;
  final int totalTokens;
  final int averageDurationMs;
  final List<EvalResult> results;
  final DateTime executedAt;

  const EvalReport({
    required this.suiteName,
    required this.totalTasks,
    required this.passedTasks,
    required this.failedTasks,
    required this.passRate,
    required this.totalTokens,
    required this.averageDurationMs,
    required this.results,
    required this.executedAt,
  });

  Map<String, dynamic> toJson() => {
        'suiteName': suiteName,
        'totalTasks': totalTasks,
        'passedTasks': passedTasks,
        'failedTasks': failedTasks,
        'passRate': passRate,
        'totalTokens': totalTokens,
        'averageDurationMs': averageDurationMs,
        'executedAt': executedAt.toIso8601String(),
        'results': results.map((r) => r.toJson()).toList(),
      };
}

/// Runner that executes evaluation tasks against an agent.
class EvalRunner {
  final EvalGrader defaultGrader;

  const EvalRunner({
    this.defaultGrader = const ExactMatchGrader(),
  });

  /// Runs a list of [tasks] using [engine] with the agent identified by [agentKey].
  Future<EvalReport> runSuite({
    required String suiteName,
    required List<EvalTask> tasks,
    required McpAgentEngine engine,
    required String agentKey,
    EvalGrader? customGrader,
    void Function(EvalTask task, EvalResult result)? onTaskCompleted,
  }) async {
    final results = <EvalResult>[];
    int totalTokens = 0;
    int totalDuration = 0;

    final baseAgent = engine.getAgent(agentKey);
    if (baseAgent == null) {
      throw ArgumentError('Agent "$agentKey" not found in engine.');
    }

    final grader = customGrader ?? defaultGrader;

    for (final task in tasks) {
      final sw = Stopwatch()..start();
      String actualOutput = '';
      final trajectory = <ChatMessage>[];
      int taskTokens = 0;

      // Create a test instance of the agent with the task's prompt
      final testAgent = baseAgent.copyWith(
        initialMessages: [],
        prompts: [SubPromptStep(text: task.prompt)],
      );

      engine.setAgents([testAgent]);

      try {
        final stream = engine.runAsync(testAgent.key);
        await for (final event in stream) {
          if (event is AgentFinalResultEvent) {
            actualOutput = event.response;
            trajectory.addAll(event.trajectory);
          } else if (event is AgentUsageEvent) {
            taskTokens += event.totalTokens;
          }
        }
      } catch (err) {
        actualOutput = 'ERROR: $err';
      } finally {
        sw.stop();
      }

      final duration = sw.elapsedMilliseconds;
      totalDuration += duration;
      totalTokens += taskTokens;

      final grade = await grader.grade(
        task: task,
        actualOutput: actualOutput,
        trajectory: trajectory,
      );

      final result = EvalResult(
        taskId: task.id,
        isSuccess: grade.isSuccess,
        score: grade.score,
        rationale: grade.rationale,
        totalTokens: taskTokens,
        durationMs: duration,
        trajectory: trajectory,
      );

      results.add(result);
      onTaskCompleted?.call(task, result);
    }

    final passed = results.where((r) => r.isSuccess).length;
    final total = results.length;
    final passRate = total > 0 ? passed / total : 0.0;
    final avgDuration = total > 0 ? (totalDuration / total).round() : 0;

    return EvalReport(
      suiteName: suiteName,
      totalTasks: total,
      passedTasks: passed,
      failedTasks: total - passed,
      passRate: passRate,
      totalTokens: totalTokens,
      averageDurationMs: avgDuration,
      results: results,
      executedAt: DateTime.now(),
    );
  }
}

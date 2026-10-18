import '../models/models.dart';
import 'eval_task.dart';

/// Grading result produced by an [EvalGrader].
class EvalGradingResult {
  final bool isSuccess;
  final double score;
  final String rationale;

  const EvalGradingResult({
    required this.isSuccess,
    required this.score,
    required this.rationale,
  });

  const EvalGradingResult.pass([this.rationale = 'Passed'])
      : isSuccess = true,
        score = 1.0;

  const EvalGradingResult.fail([this.rationale = 'Failed'])
      : isSuccess = false,
        score = 0.0;
}

/// Abstract grader interface for evaluating task outputs and trajectories.
abstract class EvalGrader {
  const EvalGrader();

  Future<EvalGradingResult> grade({
    required EvalTask task,
    required String actualOutput,
    required List<ChatMessage> trajectory,
  });
}

/// Grader that checks whether the actual output contains or matches an exact substring.
class ExactMatchGrader extends EvalGrader {
  final bool caseSensitive;
  final bool substringMatch;

  const ExactMatchGrader({
    this.caseSensitive = false,
    this.substringMatch = true,
  });

  @override
  Future<EvalGradingResult> grade({
    required EvalTask task,
    required String actualOutput,
    required List<ChatMessage> trajectory,
  }) async {
    final expected = task.expectedOutput;
    if (expected == null || expected.isEmpty) {
      return const EvalGradingResult.pass('No expected output defined.');
    }

    final target = caseSensitive ? actualOutput : actualOutput.toLowerCase();
    final query = caseSensitive ? expected : expected.toLowerCase();

    final matches =
        substringMatch ? target.contains(query) : target.trim() == query.trim();

    if (matches) {
      return EvalGradingResult.pass(
        'Output matched expected pattern: "$expected"',
      );
    } else {
      return EvalGradingResult.fail(
        'Output did not match expected: "$expected". Actual: "$actualOutput"',
      );
    }
  }
}

/// Grader that tests actual output against regular expression patterns.
class RegexGrader extends EvalGrader {
  final RegExp regex;

  const RegexGrader(this.regex);

  @override
  Future<EvalGradingResult> grade({
    required EvalTask task,
    required String actualOutput,
    required List<ChatMessage> trajectory,
  }) async {
    if (regex.hasMatch(actualOutput)) {
      return EvalGradingResult.pass('Output matched regex: ${regex.pattern}');
    } else {
      return EvalGradingResult.fail(
        'Output did not match regex: ${regex.pattern}',
      );
    }
  }
}

/// Grader that verifies specific tools were called during the task execution trajectory.
class ToolCallGrader extends EvalGrader {
  final List<String>? requiredToolNames;

  const ToolCallGrader([this.requiredToolNames]);

  @override
  Future<EvalGradingResult> grade({
    required EvalTask task,
    required String actualOutput,
    required List<ChatMessage> trajectory,
  }) async {
    final expectedTools = requiredToolNames ?? task.expectedTools;
    if (expectedTools == null || expectedTools.isEmpty) {
      return const EvalGradingResult.pass('No required tools defined.');
    }

    final calledTools = <String>{};
    for (final msg in trajectory) {
      if (msg.toolName != null) {
        calledTools.add(msg.toolName!);
      }
      if (msg.toolArguments != null && msg.toolArguments!['tool'] != null) {
        calledTools.add(msg.toolArguments!['tool'].toString());
      }
    }

    final missing = expectedTools.where((t) => !calledTools.contains(t)).toList();
    if (missing.isEmpty) {
      return EvalGradingResult.pass(
        'All expected tools called: ${expectedTools.join(", ")}',
      );
    } else {
      return EvalGradingResult.fail(
        'Missing expected tool calls: ${missing.join(", ")} (Called: ${calledTools.join(", ")})',
      );
    }
  }
}

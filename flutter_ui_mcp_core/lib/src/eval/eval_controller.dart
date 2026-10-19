import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';

/// State and execution controller for running agent evaluation benchmarks in Flutter.
class EvalController extends ChangeNotifier {
  final List<EvalTask> _tasks = [];
  EvalReport? _lastReport;
  bool _isEvaluating = false;
  double _progress = 0.0;
  String? _currentTaskName;
  String? _errorMessage;

  EvalController({List<EvalTask>? initialTasks}) {
    if (initialTasks != null && initialTasks.isNotEmpty) {
      _tasks.addAll(initialTasks);
    } else {
      _tasks.addAll(getDefaultTasks());
    }
  }

  List<EvalTask> get tasks => List.unmodifiable(_tasks);
  EvalReport? get lastReport => _lastReport;
  bool get isEvaluating => _isEvaluating;
  double get progress => _progress;
  String? get currentTaskName => _currentTaskName;
  String? get errorMessage => _errorMessage;

  /// Default baseline test tasks for quick agent sanity checking.
  static List<EvalTask> getDefaultTasks() => [
        const EvalTask(
          id: 'eval-math-sanity',
          name: 'Reasoning: Precise Calculation',
          prompt: 'What is 123 * 456? Reply only with the numerical product.',
          expectedOutput: '56088',
        ),
        const EvalTask(
          id: 'eval-format-json',
          name: 'Formatting: Valid JSON Structure',
          prompt:
              'Output a JSON object with keys "status" ("ok") and "code" (200). Output nothing else.',
          expectedOutput: '{"status": "ok", "code": 200}',
        ),
        const EvalTask(
          id: 'eval-tool-lookup',
          name: 'Tool Execution: Echo / Lookup',
          prompt:
              'Use the available echo or test tool to inspect the word "MCP_AGENT_PASS". If no tool is available, repeat it.',
          expectedOutput: 'MCP_AGENT_PASS',
        ),
      ];

  void addTask(EvalTask task) {
    _tasks.add(task);
    notifyListeners();
  }

  void removeTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void clearTasks() {
    _tasks.clear();
    notifyListeners();
  }

  void resetTasksToDefault() {
    _tasks.clear();
    _tasks.addAll(getDefaultTasks());
    notifyListeners();
  }

  /// Runs the full evaluation suite against the provided [llmConfig] and [tools].
  Future<EvalReport?> runEvaluationSuite({
    required LlmConfig llmConfig,
    required List<MCPTool> tools,
    String suiteName = 'Agent Capability Benchmark',
    EvalGrader? grader,
  }) async {
    if (_isEvaluating || _tasks.isEmpty) return null;

    _isEvaluating = true;
    _progress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      final engine = McpAgentEngine();
      final agent = Agent(
        key: 'benchmark-agent',
        name: 'Benchmark Agent',
        llmConfig: llmConfig,
        prompts: const [SubPromptStep(text: 'Run evaluation task')],
        systemPrompt:
            'You are an evaluation test subject. Follow user instructions with complete accuracy.',
      );
      engine.setAgents([agent]);

      final runner = EvalRunner(defaultGrader: grader ?? const ExactMatchGrader());
      int completed = 0;

      final report = await runner.runSuite(
        suiteName: suiteName,
        tasks: _tasks,
        engine: engine,
        agentKey: agent.key,
        customGrader: grader,
        onTaskCompleted: (task, result) {
          completed++;
          _progress = completed / _tasks.length;
          _currentTaskName = task.name;
          notifyListeners();
        },
      );

      _lastReport = report;
      _currentTaskName = null;
      return report;
    } catch (e) {
      _errorMessage = 'Evaluation run failed: $e';
      return null;
    } finally {
      _isEvaluating = false;
      _currentTaskName = null;
      notifyListeners();
    }
  }
}

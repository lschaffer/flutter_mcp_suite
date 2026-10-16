import '../models/models.dart';
import '../mcp/local_tools.dart';

/// Status of an individual task/step in an agent plan.
enum PlanStepStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case PlanStepStatus.pending:
        return 'pending';
      case PlanStepStatus.inProgress:
        return 'in_progress';
      case PlanStepStatus.completed:
        return 'completed';
      case PlanStepStatus.cancelled:
        return 'cancelled';
    }
  }

  static PlanStepStatus fromString(String? val) {
    if (val == null) return PlanStepStatus.pending;
    final clean = val.trim().toLowerCase().replaceAll('-', '_');
    switch (clean) {
      case 'in_progress':
      case 'inprogress':
      case 'running':
      case 'active':
        return PlanStepStatus.inProgress;
      case 'completed':
      case 'done':
      case 'finished':
        return PlanStepStatus.completed;
      case 'cancelled':
      case 'canceled':
      case 'skipped':
        return PlanStepStatus.cancelled;
      default:
        return PlanStepStatus.pending;
    }
  }
}

/// A discrete step or sub-goal in an agent's execution plan.
class PlanStep {
  final String id;
  final String description;
  final PlanStepStatus status;

  const PlanStep({
    required this.id,
    required this.description,
    this.status = PlanStepStatus.pending,
  });

  PlanStep copyWith({
    String? id,
    String? description,
    PlanStepStatus? status,
  }) {
    return PlanStep(
      id: id ?? this.id,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }

  factory PlanStep.fromJson(Map<String, dynamic> json) {
    return PlanStep(
      id: (json['id'] ?? '').toString(),
      description: (json['description'] ?? json['text'] ?? json['task'] ?? '').toString(),
      status: PlanStepStatus.fromString(json['status']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'status': status.label,
    };
  }
}

/// The collection of steps currently planned by an agent.
class PlanState {
  final List<PlanStep> steps;

  const PlanState({this.steps = const []});

  factory PlanState.fromJson(Map<String, dynamic> json) {
    final list = json['steps'] as List? ?? json['todos'] as List? ?? [];
    return PlanState(
      steps: list
          .whereType<Map>()
          .map((m) => PlanStep.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'steps': steps.map((s) => s.toJson()).toList(),
    };
  }

  bool get isEmpty => steps.isEmpty;
  bool get isNotEmpty => steps.isNotEmpty;
}

/// Tool injected into the agent loop when planning is enabled.
///
/// Enables models to maintain and update structured todo lists and progress.
class WriteTodosTool extends McpLocalTool {
  final void Function(PlanState plan)? onPlanUpdated;
  PlanState _currentPlan = const PlanState();

  WriteTodosTool({this.onPlanUpdated});

  PlanState get currentPlan => _currentPlan;

  @override
  String get name => 'write_todos';

  @override
  String get description =>
      'Create or update the step-by-step execution plan and task checklist for this goal. '
      'Call this to declare planned steps and update their status (pending, in_progress, completed, cancelled) as you make progress.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.read;

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'todos': {
            'type': 'array',
            'description': 'The ordered list of steps to accomplish the task.',
            'items': {
              'type': 'object',
              'properties': {
                'id': {
                  'type': 'string',
                  'description': 'Short identifier (e.g. step_1, analyze_files).',
                },
                'description': {
                  'type': 'string',
                  'description': 'Description of what this step achieves.',
                },
                'status': {
                  'type': 'string',
                  'enum': ['pending', 'in_progress', 'completed', 'cancelled'],
                  'description': 'Current status of this step.',
                },
              },
              'required': ['id', 'description', 'status'],
            },
          },
        },
        'required': ['todos'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final todosRaw = arguments['todos'] as List? ?? [];
    final steps = <PlanStep>[];

    for (var i = 0; i < todosRaw.length; i++) {
      final item = todosRaw[i];
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final id = (map['id'] ?? 'step_${i + 1}').toString();
        final desc = (map['description'] ?? map['task'] ?? '').toString();
        final status = PlanStepStatus.fromString(map['status']?.toString());
        steps.add(PlanStep(id: id, description: desc, status: status));
      }
    }

    _currentPlan = PlanState(steps: steps);
    onPlanUpdated?.call(_currentPlan);

    final summary = steps
        .map((s) => '[${s.status.label}] ${s.id}: ${s.description}')
        .join('\n');

    return MCPToolResult.text(
      'Plan updated (${steps.length} steps):\n$summary',
      metadata: {'plan': _currentPlan.toJson()},
    );
  }
}

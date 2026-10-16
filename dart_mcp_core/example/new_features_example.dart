import 'dart:async';
import 'package:dart_mcp_core/dart_mcp_core.dart';

/// 1. Example of a security / policy hook that intercepts tool calls.
class SafetyPolicyHook extends AgentHook {
  @override
  ToolCallDecision beforeToolCall(ToolCallHookContext context) {
    print('🛡️  [Hook:beforeToolCall] Checking "${context.toolName}" (risk: ${context.riskLevel.name})');

    // Block any attempt to delete or wipe
    if (context.toolName.contains('delete') || context.arguments['command'] == 'rm') {
      return const ToolCallDecision.deny('Execution blocked: Destructive operations forbidden by policy.');
    }

    // Rewrite/sanitize arguments if needed
    if (context.arguments.containsKey('city') && context.arguments['city'] == 'test') {
      final sanitized = Map<String, dynamic>.from(context.arguments);
      sanitized['city'] = 'Vienna';
      print('🔄 [Hook:beforeToolCall] Rewriting parameter city from "test" to "Vienna"');
      return ToolCallDecision.proceed(sanitized);
    }

    return const ToolCallDecision.proceed();
  }

  @override
  void afterToolCall(ToolResultHookContext context) {
    print('✅ [Hook:afterToolCall] Tool "${context.toolName}" finished (requestStop: ${context.result.requestStop})');
  }

  @override
  ModelCallDecision beforeModelCall(ModelCallHookContext context) {
    print('🤖 [Hook:beforeModelCall] Sending turn to ${context.config.provider.displayName} with ${context.tools.length} available tool(s)');
    return const ModelCallDecision.proceed();
  }
}

/// 2. Example tool that returns an explicit stop signal via [MCPToolResult.stop].
class FastFinishTool extends McpLocalTool {
  @override
  String get name => 'quick_summary';

  @override
  String get description => 'Produce an immediate summary and stop the agent loop.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'summary': {'type': 'string', 'description': 'The summary text.'},
        },
        'required': ['summary'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final text = arguments['summary']?.toString() ?? 'Done.';
    // Signals McpAgentEngine to finish execution immediately
    return MCPToolResult.stop(
      'Execution finished: $text',
      metadata: {'completedAt': DateTime.now().toIso8601String()},
    );
  }
}

Future<void> main() async {
  print('================================================================');
  print('🚀 Testing New dart_mcp_core Features');
  print('================================================================\n');

  // 1. Setup OS-Native Local AI delegate (e.g. Gemini Nano on Android / Apple FoundationModels)
  // No API key required!
  LLMService.localAiHandler = ({
    required LlmConfig config,
    required List<ChatMessage> messages,
    required List<MCPTool> tools,
    String? systemPrompt,
  }) async {
    print('📲 [Local AI Engine] Executing on-device Gemini Nano model...');
    final lastMsg = messages.last.content;

    // Simulate on-device reasoning and tool calls
    if (lastMsg.contains('plan') || lastMsg.contains('checklist')) {
      return LLMResponse(
        text: 'I will create a task plan for this goal.',
        toolCalls: [
          LLMToolCall(
            id: 'call_plan_1',
            name: 'write_todos',
            arguments: {
              'todos': [
                {'id': 'step_1', 'description': 'Inspect device sensors', 'status': 'completed'},
                {'id': 'step_2', 'description': 'Fetch weather forecast', 'status': 'in_progress'},
                {'id': 'step_3', 'description': 'Render GenUI weather card', 'status': 'pending'},
              ],
            },
          ),
        ],
      );
    } else if (lastMsg.contains('finish')) {
      return LLMResponse(
        text: 'Wrapping up task.',
        toolCalls: [
          const LLMToolCall(
            id: 'call_stop_1',
            name: 'quick_summary',
            arguments: {'summary': 'All on-device tasks completed successfully.'},
          ),
        ],
      );
    }

    return LLMResponse(text: 'On-device Gemini Nano analyzed your request: "$lastMsg".');
  };

  // 2. Configure Local AI Provider
  const localConfig = LlmConfig(
    provider: LlmProvider.localAi,
    model: 'gemini-nano',
    apiKey: '', // Zero API key required on-device
  );
  print('• Configured provider: ${localConfig.provider.displayName}');
  print('• Is configured: ${localConfig.isConfigured}\n');

  // 3. Create Agent with Planning, Progressive Discovery, and Hooks enabled
  final agent = Agent(
    key: 'advanced_agent',
    name: 'Advanced On-Device Agent',
    llmConfig: localConfig,
    enablePlanning: true, // Injects write_todos tool & PlanState
    progressiveMcpDiscovery: true, // Enables mcp_list_tools and mcp_call_tool
    hooks: [SafetyPolicyHook()], // Lifecycle interceptors
    dartTools: [FastFinishTool()],
    contextCompressor: const ContextCompressor(tokenThreshold: 2000), // Auto-summarizes long history
    prompts: [
      const SubPromptStep(text: 'Create a plan and checklist for my daily weather.'),
      const SubPromptStep(text: 'Now finish the task.'),
    ],
  );

  // 4. Run through McpAgentEngine and observe reactive stream events
  final engine = McpAgentEngine();
  engine.setAgents([agent]);

  final sub = engine.agentEvents.listen((event) {
    if (event is AgentPlanEvent) {
      print('\n📋 [STREAM PLAN EVENT] Task checklist updated:');
      for (final step in event.plan.steps) {
        print('   [${step.status.label.padRight(11)}] ${step.id}: ${step.description}');
      }
      print('');
    } else if (event is AgentContextCompressedEvent) {
      print('⚡ [STREAM CONTEXT COMPRESSED] ${event.originalTokens} -> ${event.compressedTokens} tokens (${event.compressedTurnCount} turns)');
    } else if (event is AgentToolResultEvent) {
      print('🔧 [STREAM TOOL RESULT] ${event.toolName}: ${event.result}');
    } else if (event is AgentFinalResultEvent) {
      print('\n🏁 [STREAM FINAL RESULT]: ${event.response}');
    }
  });

  await engine.run('advanced_agent');
  await sub.cancel();

  print('\n================================================================');
  print('✨ All new features (Local AI, AgentHook, Planning, Stop signals, ContextCompressor) tested successfully!');
  print('================================================================');
}

import 'dart:async';
import '../models/models.dart';
import '../mcp/local_tools.dart';
import '../llm/llm_response.dart';

/// Context provided to [AgentHook.beforeToolCall].
class ToolCallHookContext {
  /// Name of the tool being called.
  final String toolName;

  /// The arguments provided by the model for this call.
  final Map<String, dynamic> arguments;

  /// Inferred or declared risk level of the tool.
  final ToolRiskLevel riskLevel;

  /// Identifying key of the executing agent.
  final String agentKey;

  /// The 0-based index of the current execution step.
  final int stepIndex;

  /// Read-only snapshot of current conversation messages.
  final List<ChatMessage> messages;

  const ToolCallHookContext({
    required this.toolName,
    required this.arguments,
    required this.riskLevel,
    required this.agentKey,
    required this.stepIndex,
    required this.messages,
  });
}

/// Decision returned by [AgentHook.beforeToolCall].
class ToolCallDecision {
  /// Whether the tool call was denied/rejected by this hook.
  final bool isDenied;

  /// Reason for denial if [isDenied] is true.
  final String? denialReason;

  /// Optional modified arguments to pass to the tool instead of the original arguments.
  final Map<String, dynamic>? modifiedArguments;

  /// Proceed with tool execution, optionally rewriting the arguments.
  const ToolCallDecision.proceed([this.modifiedArguments])
      : isDenied = false,
        denialReason = null;

  /// Deny/block tool execution with a specific reason returned to the LLM.
  const ToolCallDecision.deny(String reason)
      : isDenied = true,
        denialReason = reason,
        modifiedArguments = null;
}

/// Context provided to [AgentHook.afterToolCall].
class ToolResultHookContext {
  /// Name of the tool executed.
  final String toolName;

  /// Arguments used during execution.
  final Map<String, dynamic> arguments;

  /// Result produced by the tool.
  final MCPToolResult result;

  /// Identifying key of the executing agent.
  final String agentKey;

  const ToolResultHookContext({
    required this.toolName,
    required this.arguments,
    required this.result,
    required this.agentKey,
  });
}

/// Context provided to [AgentHook.beforeModelCall].
class ModelCallHookContext {
  /// Messages about to be sent to the model.
  final List<ChatMessage> messages;

  /// System prompt about to be sent.
  final String systemPrompt;

  /// Tools provided to the model.
  final List<MCPTool> tools;

  /// Configuration of the target LLM.
  final LlmConfig config;

  /// Identifying key of the executing agent.
  final String agentKey;

  const ModelCallHookContext({
    required this.messages,
    required this.systemPrompt,
    required this.tools,
    required this.config,
    required this.agentKey,
  });
}

/// Decision returned by [AgentHook.beforeModelCall].
class ModelCallDecision {
  /// Optionally rewritten message list.
  final List<ChatMessage>? modifiedMessages;

  /// Optionally rewritten system prompt.
  final String? modifiedSystemPrompt;

  const ModelCallDecision.proceed({
    this.modifiedMessages,
    this.modifiedSystemPrompt,
  });
}

/// Context provided to [AgentHook.afterModelCall].
class ModelResultHookContext {
  /// The response received from the model.
  final LLMResponse response;

  /// Identifying key of the executing agent.
  final String agentKey;

  const ModelResultHookContext({
    required this.response,
    required this.agentKey,
  });
}

/// Lifecycle interceptor hook for [McpAgentEngine] executions.
///
/// Implement this class to intercept and control the agent loop:
/// - Enforce security/permission policies on tool calls.
/// - Human-in-the-loop approvals.
/// - Rewrite model messages or inject transient runtime context.
/// - Log or inspect execution metrics.
abstract class AgentHook {
  const AgentHook();

  /// Called before a tool is executed. Can deny or modify arguments.
  FutureOr<ToolCallDecision> beforeToolCall(ToolCallHookContext context) {
    return const ToolCallDecision.proceed();
  }

  /// Called immediately after a tool finishes execution.
  FutureOr<void> afterToolCall(ToolResultHookContext context) {}

  /// Called before the engine issues a call to the LLM.
  FutureOr<ModelCallDecision> beforeModelCall(ModelCallHookContext context) {
    return const ModelCallDecision.proceed();
  }

  /// Called immediately after the LLM responds (or finishes streaming).
  FutureOr<void> afterModelCall(ModelResultHookContext context) {}
}

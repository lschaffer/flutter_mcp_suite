// Pure Dart core for AI Agent Playground.
// Agent execution engine, LLM adapters, MCP clients, and tool orchestration
// — no Flutter dependency.

// Models
export 'src/models/models.dart';
export 'src/models/skill_manifest.dart';

// LLM
export 'src/llm/llm_service.dart';
export 'src/llm/llm_response.dart';

// MCP
export 'src/mcp/mcp_client.dart';
export 'src/mcp/mcp_client_def.dart';
export 'src/mcp/local_tools.dart';
export 'src/mcp/progressive_tools.dart';
export 'src/mcp/local_mcp_client_stub.dart'
    if (dart.library.io) 'src/mcp/local_mcp_client.dart';

// Agents
export 'src/agents/agents_engine.dart';
export 'src/agents/agent_hook.dart';
export 'src/agents/agent_plan.dart';
export 'src/agents/delegate_task_tool.dart';
export 'src/context/context_compressor.dart';
export 'src/context/retrieve_memory_tool.dart';
export 'src/utils/change_notifier.dart';

// Skills
export 'src/skills/skill_storage_adapter.dart';
export 'src/skills/skill_exporter.dart';
export 'src/skills/skill_importer.dart';
export 'src/skills/skill_definition.dart';
export 'src/skills/dynamic_skill_tools.dart';

// Coding Tools
export 'src/tools/coding_tools_stub.dart'
    if (dart.library.io) 'src/tools/coding_tools.dart';

// Evaluation Harness
export 'src/eval/eval_task.dart';
export 'src/eval/eval_grader.dart';
export 'src/eval/eval_runner.dart';
export 'src/eval/trajectory_recorder.dart';

import 'dart:async';
import 'dart:io';
import 'package:dart_mcp_core/dart_mcp_core.dart';
import 'skill_tools.dart';

Future<Map<String, String>> _loadEnv() async {
  final env = <String, String>{};
  for (final key in ['LLM_PROVIDER', 'LLM_MODEL', 'LLM_URL', 'LLM_API_KEY']) {
    final val = Platform.environment[key];
    if (val != null && val.isNotEmpty) env[key] = val;
  }
  var dir = Directory.current;
  for (var i = 0; i < 5; i++) {
    final envFile = File('${dir.path}/.env');
    if (await envFile.exists()) {
      final lines = await envFile.readAsLines();
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final idx = line.indexOf('=');
        if (idx == -1) continue;
        final k = line.substring(0, idx).trim();
        final v = line.substring(idx + 1).trim();
        if (k.isNotEmpty && v.isNotEmpty && !env.containsKey(k)) env[k] = v;
      }
      break;
    }
    dir = dir.parent;
  }
  return env;
}

Future<void> main() async {
  print('═══ MCP Playground — Git Diff Reviewer Skill ═══\n');

  final env = await _loadEnv();
  final skillFile = File('skill.md');
  if (!await skillFile.exists()) {
    print('Error: skill.md not found in ${Directory.current.path}');
    exit(1);
  }

  final skillContent = await skillFile.readAsString();
  final importer = SkillImporter();
  final SkillManifest manifest;
  try {
    manifest = importer.parseSkillMd(skillContent);
    print('✓ Loaded skill: "${manifest.name}"');
    print('  Steps: ${manifest.promptSteps.length}');
    print('  Declared Tools: ${manifest.tools.map((t) => t.name).join(', ')}\n');
  } catch (e) {
    print('Error parsing SKILL.md: $e');
    exit(1);
  }

  final providerStr = env['LLM_PROVIDER']?.trim().toLowerCase() ?? 'openai';
  LlmProvider provider;
  switch (providerStr) {
    case 'claude':
      provider = LlmProvider.claude;
    case 'gemini':
      provider = LlmProvider.gemini;
    case 'ollama':
      provider = LlmProvider.ollama;
    default:
      provider = LlmProvider.openai;
  }

  final llmConfig = LlmConfig(
    provider: provider,
    apiKey: env['LLM_API_KEY'] ?? '',
    model: env['LLM_MODEL'] ?? 'gpt-4o-mini',
    baseUrl: env['LLM_URL'] ?? '',
    useNativeToolCall: true,
  );

  final localTools = <McpLocalTool>[
    GitStatusTool(),
    GitDiffTool(),
    RunAnalyzerTool(),
    ExportPrSummaryTool(),
  ];

  final promptSteps = manifest.promptSteps.map((s) {
    return SubPromptStep(
      text: s.text,
      enabledToolNames: s.enabledToolNames,
      stopAfterToolCall: s.stopAfterToolCall,
    );
  }).toList();

  final agent = Agent(
    key: 'git_review_agent',
    name: manifest.name,
    llmConfig: llmConfig,
    systemPrompt: manifest.systemPrompt,
    prompts: promptSteps,
    dartTools: localTools,
  );

  final engine = McpAgentEngine();
  engine.setAgents([agent]);

  print('═══ Executing Agent Workflow ═══');
  final sub = engine.agentEvents.listen((event) {
    if (event is AgentLogEvent) {
      print('[LOG] ${event.message}');
    } else if (event is AgentToolResultEvent) {
      print('\n┌─ TOOL: ${event.toolName}');
      final result = event.result;
      if (result.length > 500) {
        print('│ ${result.substring(0, 500)}...');
      } else {
        for (final line in result.split('\n')) {
          print('│ $line');
        }
      }
      print('└─\n');
    } else if (event is AgentTextChunkEvent) {
      stdout.write(event.chunk);
    } else if (event is AgentFinalResultEvent) {
      print('\n═══ Final Response ═══');
      print(event.response);
      print('═════════════════════\n');
    } else if (event is AgentErrorEvent) {
      print('\nERROR: ${event.error}');
    }
  });

  try {
    final stream = engine.runAsync(agent.key);
    await stream.firstWhere(
      (event) => event is AgentFinalResultEvent || event is AgentErrorEvent,
    );
  } finally {
    await sub.cancel();
    await engine.dispose();
  }
}

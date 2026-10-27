import 'dart:typed_data';
import 'package:dart_mcp_core/dart_mcp_core.dart';

void main() async {
  print('================================================================');
  print('🚀 dart_mcp_core v1.3.0 Feature Demonstrations');
  print('================================================================\n');

  // ─────────────────────────────────────────────────────────────
  // 1. Multimodal Content Parts (ChatContentPart)
  // ─────────────────────────────────────────────────────────────
  print('--- [1] Typed Multimodal Messages (ChatContentPart) ---');
  final fakeImageBytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
  final userMessage = ChatMessage.user(
    'Please inspect this diagram:',
    parts: [
      const TextPart('Please inspect this diagram:'),
      ImagePart.fromUrl('https://raw.githubusercontent.com/lschaffer/tealkit/main/logo.png'),
      ImagePart.fromBytes(fakeImageBytes, mimeType: 'image/png'),
    ],
  );

  print('Constructed Multimodal Message with ${userMessage.parts?.length} parts:');
  for (final part in userMessage.parts!) {
    if (part is TextPart) {
      print('  • TextPart: "${part.text}"');
    } else if (part is ImagePart) {
      print('  • ImagePart: url=${part.url != null} bytes=${part.bytes?.length}B (mimeType: ${part.mimeType})');
    }
  }
  print('');

  // ─────────────────────────────────────────────────────────────
  // 2. Episodic Memory Store & RetrieveMemoryTool
  // ─────────────────────────────────────────────────────────────
  print('--- [2] Episodic Memory Store & Recall (retrieve_memory) ---');
  final memoryStore = EpisodicMemoryStore();

  // Simulate storing a compressed turn block
  final historicalEntry = EpisodicMemoryEntry(
    archiveId: 'mem_auth_turn_2',
    startTurnIndex: 0,
    endTurnIndex: 3,
    timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    rawMessages: [
      ChatMessage.user('Generate a secure API token with secret prefix TLK_LIVE'),
      ChatMessage.assistant('Generated token: TLK_LIVE_9876543210_SECURE'),
    ],
    summary: 'Assistant generated API token with TLK_LIVE prefix.',
  );
  memoryStore.addEntry(historicalEntry);
  print('Stashed turn archive "${historicalEntry.archiveId}" into EpisodicMemoryStore.');

  // The model calls retrieve_memory when asked for the exact secret token
  final retrieveTool = RetrieveMemoryTool(
    memoryStore: memoryStore,
    onMemoryRetrieved: (id, turns, query) {
      print('🧠 [Engine Callback] Stashed memory recalled: $id ($turns turns, query: "$query")');
    },
  );

  final recallResult = await retrieveTool.execute({'query': 'TLK_LIVE'});
  print('Tool retrieve_memory returned:\n${recallResult.text}\n');

  // ─────────────────────────────────────────────────────────────
  // 3. Autonomous Sub-Agent Delegation (delegate_task)
  // ─────────────────────────────────────────────────────────────
  print('--- [3] Autonomous Sub-Agent Delegation (delegate_task) ---');
  final delegateTool = DelegateTaskTool(
    availableAssignees: ['clone', 'researcher', 'coder'],
    runner: ({required String assignee, required String task, List<String>? enabledTools, String? model}) async {
      print('🤖 [Sub-Agent Runner] Delegated to "$assignee" (tools: ${enabledTools?.join(", ") ?? "all"}):');
      print('   Task: "$task"');
      return 'Sub-agent "$assignee" completed analysis. Found 3 critical performance bottlenecks.';
    },
  );

  final subAgentResult = await delegateTool.execute({
    'assignee': 'researcher',
    'task': 'Benchmark the JSON parser latency across 10,000 records',
    'enabledTools': ['fs_read_file', 'terminal_exec'],
  });
  print('Tool delegate_task returned: "${subAgentResult.text}"\n');

  // ─────────────────────────────────────────────────────────────
  // 4. Dynamic Runtime Skill Activation (SkillDefinition)
  // ─────────────────────────────────────────────────────────────
  print('--- [4] Dynamic Skills (SkillDefinition & On-Demand Toggling) ---');
  final activeSkills = <String>{};

  final activateTool = ActivateSkillsTool(
    availableSkills: ['git_review', 'sqlite_analyst'],
    onActivate: (skillNames) async {
      activeSkills.addAll(skillNames);
      return 'Skills activated: ${skillNames.join(", ")}';
    },
  );

  final deactivateTool = DeactivateSkillsTool(
    onDeactivate: (skillNames) async {
      activeSkills.removeAll(skillNames);
      return 'Skills deactivated: ${skillNames.join(", ")}';
    },
  );

  print('Current active skills: ${activeSkills.isEmpty ? "None (Lean context)" : activeSkills.join(", ")}');
  await activateTool.execute({'skills': ['git_review']});
  print('After agent activated git_review: ${activeSkills.join(", ")}');
  await deactivateTool.execute({'skills': ['git_review']});
  print('After agent finished and deactivated skill: ${activeSkills.isEmpty ? "None (Context cleared)" : activeSkills.join(", ")}\n');

  // ─────────────────────────────────────────────────────────────
  // 5. Evaluation Harness & Trajectory Recorder
  // ─────────────────────────────────────────────────────────────
  print('--- [5] Agent Evaluation Harness & Trajectory Replay ---');
  const task = EvalTask(
    id: 'weather_verification_1',
    name: 'Weather Forecast Check',
    prompt: 'Check the weather in Paris',
    expectedTools: ['get_weather'],
    expectedOutput: 'Paris',
  );

  const grader = ToolCallGrader();
  final testTrajectory = [
    ChatMessage(
      id: 'step_1',
      content: 'Fetching weather for Paris...',
      role: ChatRole.assistant,
      timestamp: DateTime.now(),
      toolName: 'get_weather',
      toolArguments: {'city': 'Paris'},
    ),
  ];

  final grade = await grader.grade(
    task: task,
    actualOutput: 'The weather in Paris is sunny, 22°C.',
    trajectory: testTrajectory,
  );

  print('Eval Grade: isSuccess=${grade.isSuccess} score=${grade.score}');
  print('Rationale: "${grade.rationale}"');

  // Export trajectory to JSON transcript
  final jsonTranscript = TrajectoryRecorder.exportToJson(testTrajectory);
  print('Serialized trajectory (${jsonTranscript.length} characters):');
  print('  ${jsonTranscript.substring(0, 80)}...');

  final restoredTrajectory = TrajectoryRecorder.importFromJson(jsonTranscript);
  print('Restored ${restoredTrajectory.length} message(s) from transcript successfully.\n');

  print('================================================================');
  print('✅ All v1.3.0 Feature Demonstrations Completed Successfully!');
  print('================================================================');
}

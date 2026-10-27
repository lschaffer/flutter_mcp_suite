import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_ui_mcp/flutter_ui_mcp.dart';
import 'env_loader.dart';
import 'example_local_tools.dart';
import 'progressive_discovery_example.dart';

// Standalone Flutter MCP Examples (imported with prefix aliases to avoid collisions)
import 'package:example_progressive_tools/main.dart' as progressive_demo;
import 'package:example_progressive_tools/env_loader.dart' as progressive_env;
import 'package:example_dynamic_skills/main.dart' as dynamic_skills_demo;
import 'package:example_dynamic_skills/env_loader.dart' as dynamic_skills_env;
import 'package:example_subagents_orchestrator/main.dart' as subagents_demo;
import 'package:example_subagents_orchestrator/env_loader.dart' as subagents_env;
import 'package:example_episodic_memory/main.dart' as episodic_memory_demo;
import 'package:example_episodic_memory/env_loader.dart' as episodic_memory_env;
import 'package:example_agent_eval/main.dart' as agent_eval_demo;
import 'package:example_agent_eval/env_loader.dart' as agent_eval_env;
import 'package:example_multimodal_vision/main.dart' as multimodal_vision_demo;
import 'package:example_multimodal_vision/env_loader.dart' as multimodal_vision_env;
import 'package:example_audio_notes/main.dart' as audio_notes_demo;
import 'package:example_audio_notes/env_loader.dart' as audio_notes_env;
import 'package:example_github_triage/main.dart' as github_triage_demo;
import 'package:example_github_triage/env_loader.dart' as github_triage_env;
import 'package:example_device_diagnostics/main.dart' as device_diagnostics_demo;
import 'package:example_device_diagnostics/env_loader.dart' as device_diagnostics_env;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  await Future.wait([
    progressive_env.EnvLoader.load(),
    dynamic_skills_env.EnvLoader.load(),
    subagents_env.EnvLoader.load(),
    episodic_memory_env.EnvLoader.load(),
    agent_eval_env.EnvLoader.load(),
    multimodal_vision_env.EnvLoader.load(),
    audio_notes_env.EnvLoader.load(),
    github_triage_env.EnvLoader.load(),
    device_diagnostics_env.EnvLoader.load(),
  ]);
  runApp(const McpPlaygroundShowcaseApp());
}

/// Available showcase demos in the Flutter UI MCP Gallery.
enum FlutterMcpDemo {
  playground(
    id: 'playground',
    title: 'Consolidated MCP Playground',
    subtitle: 'Weather, SSH/SFTP, Canvas Charts & Local MCP Servers',
    icon: Icons.dashboard_rounded,
    badge: 'Flagship',
    examplePrompts: [
      'What is the current weather and 3-day forecast in Vienna and Zurich? Create a temperature comparison chart.',
      'Generate a bar chart showing quarterly cloud revenue: Q1 \$42k, Q2 \$58k, Q3 \$73k, Q4 \$91k.',
      'List the files in the current directory and display git branch status.',
    ],
  ),
  progressiveTools(
    id: 'progressive_tools',
    title: 'Progressive Tool Discovery',
    subtitle: 'On-demand schema introspection via mcp_list_tools & mcp_call_tool (95% token savings)',
    icon: Icons.auto_awesome_rounded,
    badge: 'v1.4.0',
    examplePrompts: [
      'Check cloud cluster telemetry for prod-us-east-1 and notify the #devops-alerts channel on Slack.',
      'Inspect the Redis cache store and calculate compute costs for 8 instances with 8 vCPUs and 32 GB RAM on AWS.',
      'Query the users database table for recent records and benchmark HTTP latency to https://api.github.com.',
    ],
  ),
  dynamicSkills(
    id: 'dynamic_skills',
    title: 'Dynamic Skills Dock',
    subtitle: 'On-demand skill activation/deactivation for specialized roles & prompt injection',
    icon: Icons.extension_rounded,
    badge: 'Skills',
    examplePrompts: [
      'Explain the PostgreSQL query plan for "SELECT * FROM orders WHERE customer_id = 42 ORDER BY created_at DESC;" and recommend indexes.',
      'Parse git commit history and draft formatted release notes following Keep a Changelog.',
      'Audit HTTP response security headers for https://example.com and check CORS policies.',
    ],
  ),
  subAgents(
    id: 'subagents',
    title: 'Sub-Agent Orchestrator',
    subtitle: 'Principal Architect delegating tasks across specialized security & telemetry child agents',
    icon: Icons.account_tree_rounded,
    badge: 'Multi-Agent',
    examplePrompts: [
      'Audit payment infrastructure: delegate security audit to Security Analyst, and telemetry investigation to Performance Engineer.',
      'Spawn research sub-agent to analyze API latency metrics and recommend connection pool sizing.',
      'Coordinate security and performance sub-agents to prepare an executive incident response report.',
    ],
  ),
  episodicMemory(
    id: 'episodic_memory',
    title: 'Episodic Memory & Recall',
    subtitle: 'Cross-session associative recall, key architectural preferences & knowledge retention',
    icon: Icons.psychology_rounded,
    badge: 'Memory',
    examplePrompts: [
      'Remember that my preferred deployment region is eu-central-1 and our database is PostgreSQL 16.',
      'What are my saved infrastructure preferences and database versions?',
      'Recall recent architectural decisions and list all stored long-term memories.',
    ],
  ),
  agentEval(
    id: 'agent_eval',
    title: 'Agent Evaluation & Benchmarks',
    subtitle: 'Automated scoring of tool accuracy, precision, latency & hallucination rate',
    icon: Icons.fact_check_rounded,
    badge: 'Eval',
    examplePrompts: [
      'Run full evaluation benchmark suite across 5 multi-turn tool calling scenarios.',
      'Score assistant trajectory for tool selection accuracy, argument precision, and latency.',
      'Generate an agent quality scorecard comparing model performance on weather queries.',
    ],
  ),
  multimodalVision(
    id: 'multimodal_vision',
    title: 'Multimodal Vision & OCR',
    subtitle: 'Visual UI inspection, diagram analysis, OCR table extraction & design audit',
    icon: Icons.image_search_rounded,
    badge: 'Vision',
    examplePrompts: [
      'Analyze the attached UI screenshot and inspect contrast ratios against WCAG AA standards.',
      'Extract tabular financial data and totals from this invoice screenshot.',
      'Examine this architecture diagram and list all microservices and communication channels.',
    ],
  ),
  audioNotes(
    id: 'audio_notes',
    title: 'Audio Notes & Meeting Minutes',
    subtitle: 'Speech-to-text transcript analysis, action item extraction & meeting summaries',
    icon: Icons.mic_rounded,
    badge: 'Audio',
    examplePrompts: [
      'Transcribe meeting recording and extract key action items, owners, and deadlines.',
      'Generate executive bullet points and follow-up tasks from client conference call.',
      'Search audio transcripts for discussions related to Q3 enterprise pricing.',
    ],
  ),
  githubTriage(
    id: 'github_triage',
    title: 'GitHub Triage Assistant',
    subtitle: 'Automated pull request review, label recommendations, bug triage & changelog drafting',
    icon: Icons.code_rounded,
    badge: 'DevOps',
    examplePrompts: [
      'Fetch open pull requests and triage by review readiness, label recommendations, and CI status.',
      'Review issue #218, categorize severity, and suggest possible reproduction steps.',
      'Compile weekly developer summary of merged pull requests and community contributions.',
    ],
  ),
  deviceDiagnostics(
    id: 'device_diagnostics',
    title: 'Device Diagnostics & Health',
    subtitle: 'Hardware sensor inspection, memory pressure, battery metrics & network telemetry',
    icon: Icons.developer_board_rounded,
    badge: 'Hardware',
    examplePrompts: [
      'Run comprehensive device hardware diagnostic suite and show memory and battery stats.',
      'Inspect network connectivity, ping round-trip times, and active network interfaces.',
      'Profile UI frame rendering pipeline and report any frame drop or jank anomalies.',
    ],
  );

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final List<String> examplePrompts;

  const FlutterMcpDemo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.examplePrompts,
  });
}

class McpPlaygroundShowcaseApp extends StatefulWidget {
  const McpPlaygroundShowcaseApp({super.key});

  @override
  State<McpPlaygroundShowcaseApp> createState() =>
      _McpPlaygroundShowcaseAppState();
}

/// Backwards compatibility alias for [McpPlaygroundShowcaseApp].
typedef McpPlaygroundExampleApp = McpPlaygroundShowcaseApp;

class _McpPlaygroundShowcaseAppState extends State<McpPlaygroundShowcaseApp> {
  ThemeMode _themeMode = ThemeMode.system;
  FlutterMcpDemo _currentDemo = FlutterMcpDemo.playground;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _selectDemo(FlutterMcpDemo demo) {
    setState(() {
      _currentDemo = demo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter UI MCP - Feature Showcase',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0067C0),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF60CDFF),
          brightness: Brightness.dark,
        ),
      ),
      home: ShowcaseGalleryShell(
        currentDemo: _currentDemo,
        onSelectDemo: _selectDemo,
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class ShowcaseGalleryShell extends StatelessWidget {
  final FlutterMcpDemo currentDemo;
  final ValueChanged<FlutterMcpDemo> onSelectDemo;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const ShowcaseGalleryShell({
    super.key,
    required this.currentDemo,
    required this.onSelectDemo,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  void _showPromptsDialog(BuildContext context, FlutterMcpDemo demo) {
    ExamplePromptsDialog.show(
      context,
      title: demo.title,
      subtitle: demo.subtitle,
      icon: demo.icon,
      badge: demo.badge,
      prompts: demo.examplePrompts,
    );
  }

  void _showFeaturePicker(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.auto_awesome_mosaic_rounded,
                          size: 18,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Showcase Features',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Select any feature to test or inspect prompts',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: FlutterMcpDemo.values.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final demo = FlutterMcpDemo.values[index];
                        final isSelected = demo == currentDemo;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            onSelectDemo(demo);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primaryContainer
                                      .withValues(alpha: 0.35)
                                  : colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.primaryContainer,
                                      child: Icon(
                                        demo.icon,
                                        size: 16,
                                        color: isSelected
                                            ? colorScheme.onPrimary
                                            : colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        demo.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? colorScheme.primary
                                              : null,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        demo.badge,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 18,
                                        color: colorScheme.primary,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  demo.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.3,
                                  ),
                                ),
                                if (demo.examplePrompts.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.lightbulb_outline_rounded,
                                        size: 14,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          demo.examplePrompts.first,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: colorScheme.outline,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.tips_and_updates_rounded,
                                            size: 16),
                                        tooltip: 'View Prompts',
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          _showPromptsDialog(context, demo);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    final promptTooltipText = currentDemo.examplePrompts.isNotEmpty
        ? '💡 Example Prompts:\n• ${currentDemo.examplePrompts.join('\n• ')}'
        : 'View Example Prompts';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        elevation: 1,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.terminal_rounded,
                    size: 16,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 6),
                    Text(
                      'FLUTTER UI MCP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: isMobile
                  ? InkWell(
                      onTap: () => _showFeaturePicker(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(currentDemo.icon, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                currentDemo.title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                currentDemo.badge,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_drop_down_rounded, size: 18),
                          ],
                        ),
                      ),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<FlutterMcpDemo>(
                        isExpanded: true,
                        menuWidth: 420,
                        value: currentDemo,
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        items: FlutterMcpDemo.values.map((demo) {
                          final isFlagship = demo.badge == 'Flagship';
                          return DropdownMenuItem<FlutterMcpDemo>(
                            value: demo,
                            child: Row(
                              children: [
                                Icon(demo.icon, size: 18),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    demo.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isFlagship
                                        ? colorScheme.primary
                                            .withValues(alpha: 0.15)
                                        : colorScheme.secondary
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    demo.badge,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isFlagship
                                          ? colorScheme.primary
                                          : colorScheme.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) onSelectDemo(val);
                        },
                      ),
                    ),
            ),
            const SizedBox(width: 4),
            // Example Prompts button placed directly beside the dropdown
            Tooltip(
              message: promptTooltipText,
              waitDuration: const Duration(milliseconds: 300),
              showDuration: const Duration(seconds: 5),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              textStyle: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
              child: IconButton.filledTonal(
                icon: const Icon(
                  Icons.tips_and_updates_rounded,
                  size: 18,
                  color: Colors.amber,
                ),
                tooltip: 'Example Prompts (Click to View & Copy)',
                onPressed: () => _showPromptsDialog(context, currentDemo),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: KeyedSubtree(
        key: ValueKey(currentDemo.id),
        child: _buildCurrentDemoView(context),
      ),
    );
  }

  Widget _buildCurrentDemoView(BuildContext context) {
    switch (currentDemo) {
      case FlutterMcpDemo.playground:
        return const McpPlaygroundScreen();
      case FlutterMcpDemo.progressiveTools:
        return const progressive_demo.ProgressiveToolsScreen();
      case FlutterMcpDemo.dynamicSkills:
        return const dynamic_skills_demo.DynamicSkillsScreen();
      case FlutterMcpDemo.subAgents:
        return const subagents_demo.SubAgentsScreen();
      case FlutterMcpDemo.episodicMemory:
        return const episodic_memory_demo.EpisodicMemoryScreen();
      case FlutterMcpDemo.agentEval:
        return const agent_eval_demo.AgentEvalScreen();
      case FlutterMcpDemo.multimodalVision:
        return const multimodal_vision_demo.MultimodalVisionScreen();
      case FlutterMcpDemo.audioNotes:
        return const audio_notes_demo.AudioNotesPlaygroundScreen();
      case FlutterMcpDemo.githubTriage:
        return const github_triage_demo.GithubTriageScreen();
      case FlutterMcpDemo.deviceDiagnostics:
        return const device_diagnostics_demo.DiagnosticsPlaygroundScreen();
    }
  }
}

/// Dialog displaying selectable example prompts with 1-tap copy functionality.
class ExamplePromptsDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final List<String> prompts;

  const ExamplePromptsDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.prompts,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
    required List<String> prompts,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ExamplePromptsDialog(
        title: title,
        subtitle: subtitle,
        icon: icon,
        badge: badge,
        prompts: prompts,
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Copied prompt to clipboard!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(icon, size: 20, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // Prompts section header
              Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates_rounded,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tested Example Prompts',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Select any text or tap the copy button to copy into the chat input:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: 12),
              // Prompts List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: prompts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final prompt = prompts[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _copyToClipboard(context, prompt),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SelectableText(
                                prompt,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              tooltip: 'Copy Prompt',
                              onPressed: () => _copyToClipboard(context, prompt),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// McpPlaygroundScreen (Flagship consolidated implementation)
// ─────────────────────────────────────────────────────────────────────────────

class McpPlaygroundScreen extends StatelessWidget {
  const McpPlaygroundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Register custom local (Dart-native) MCP tools ──────────────
    final sshDefaults = <String, dynamic>{
      'host': EnvLoader.get('LOCAL_MCP_SSH_HOST'),
      'port': int.tryParse(EnvLoader.get('LOCAL_MCP_SSH_PORT')) ?? 22,
      'username': EnvLoader.get('LOCAL_MCP_SSH_USER'),
      'password': EnvLoader.get('LOCAL_MCP_SSH_PASSW'),
    };

    final List<McpLocalTool> demoLocalTools = [
      // --- Weather tools (free Open-Meteo API, no key required) ---
      GetCurrentWeatherTool(),
      GetHourlyForecastTool(),
      GetDailyForecastTool(),
      GeocodeWeatherCityTool(),

      // --- SSH/SFTP tools (requires the dartssh2 package) ---
      SshListDirectoryTool(() => sshDefaults),
      SshReadFileTool(() => sshDefaults),
      SshDownloadFileTool(() => sshDefaults),
      SshUploadFileTool(() => sshDefaults),
      SshExecuteCommandTool(() => sshDefaults),
      SshMakeDirectoryTool(() => sshDefaults),
      SshRemoveDirectoryTool(() => sshDefaults),

      // --- Chart tools ---
      CreateChartPngTool(), // JSON config -> rendered via fl_chart in host
      Chart2PngTool(), // Canvas-based -> returns direct PNG image
    ];

    // Load initial LLM configuration if configured in .env
    final initialLlm = LlmConfig(
      provider: EnvLoader.getProvider(),
      model: EnvLoader.get('LLM_MODEL', defaultValue: 'gpt-4o'),
      apiKey: EnvLoader.get('LLM_API_KEY'),
      baseUrl: EnvLoader.get('LLM_URL'),
    );

    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);

    // Initial local MCP servers setup with git and filesystem configs (desktop only)
    final List<LocalMcpServerSetup>? initialLocalServers = isDesktop
        ? [
            LocalMcpServerSetup(
              name: 'Filesystem',
              type: 'node',
              method: 'npx',
              packageOrServerName: '@modelcontextprotocol/server-filesystem',
              launchArguments: currentDirectoryPath(),
              reinstall: false,
            ),
            const LocalMcpServerSetup(
              name: 'Git',
              type: 'python',
              method: 'uvx',
              packageOrServerName: 'mcp-server-git',
              launchArguments: '',
              reinstall: false,
            ),
          ]
        : null;

    return McpPlayground(
      initialLlmConfig: initialLlm.provider != LlmProvider.none
          ? initialLlm
          : null,
      customLocalTools: demoLocalTools,
      initialLocalMcpServers: initialLocalServers,
      initialEnabledTools: const [
        'get_weather_forecast',
        'get_current_weather',
        'get_hourly_forecast',
        'get_daily_forecast',
        'geocode_weather_city',
      ],
      customAppBarActions: [
        IconButton(
          icon: const Icon(Icons.auto_awesome),
          tooltip: 'Progressive MCP Tool Discovery Demo',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProgressiveDiscoveryExampleScreen(),
              ),
            );
          },
        ),
      ],
      messageContentBuilder: (context, message) {
        if (message == null) return null;
        if (message.type != MessageType.toolResponse) return null;
        if (message.toolName != 'create_chart_png') return null;
        final contentText = message.content.trim();
        if (!((contentText.startsWith('{') && contentText.endsWith('}')) ||
            (contentText.startsWith('[') && contentText.endsWith(']')))) {
          return null;
        }

        try {
          final decoded = jsonDecode(contentText);
          if (decoded is! Map<String, dynamic>) return null;

          final chartType =
              ((decoded['chart_type'] ?? decoded['chartType']) as String? ??
                      'line')
                  .trim()
                  .toLowerCase();
          final labels =
              ((decoded['labels'] ?? decoded['xAxis']) as List?)
                  ?.cast<String>() ??
              [];
          final dataList =
              ((decoded['data'] ?? decoded['yAxis']) as List?)
                  ?.map((d) => (d as num).toDouble())
                  .toList() ??
              [];

          if (labels.isEmpty || dataList.isEmpty) return null;

          final theme = Theme.of(context);
          final title = (decoded['title'] ?? decoded['chartTitle'] ?? 'Chart')
              .toString();

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  child: _renderFlChart(chartType, labels, dataList, theme),
                ),
              ],
            ),
          );
        } catch (_) {
          return null;
        }
      },
    );
  }

  Widget _renderFlChart(
    String type,
    List<String> labels,
    List<double> data,
    ThemeData theme,
  ) {
    if (type == 'pie') {
      final List<PieChartSectionData> sections = [];
      for (int i = 0; i < data.length; i++) {
        sections.add(
          PieChartSectionData(
            color: Colors.primaries[i % Colors.primaries.length],
            value: data[i],
            title: '${labels.length > i ? labels[i] : ""}\n${data[i]}',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
      return PieChart(PieChartData(sections: sections, centerSpaceRadius: 40));
    }

    if (type == 'bar') {
      final List<BarChartGroupData> groups = [];
      for (int i = 0; i < data.length; i++) {
        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i],
                color: theme.colorScheme.primary,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }

      return BarChart(
        BarChartData(
          barGroups: groups,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 32),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx >= 0 && idx < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        labels[idx],
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
        ),
      );
    }

    // Default: Line chart
    final List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      labels[idx],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mcp_playground_flutter/mcp_playground_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GithubTriageApp());
}

class GithubTriageApp extends StatelessWidget {
  const GithubTriageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Issue Triage & PR Review Copilot',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF24292E),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF58A6FF),
          brightness: Brightness.dark,
        ),
      ),
      home: const GithubTriageScreen(),
    );
  }
}

class GithubTriageScreen extends StatelessWidget {
  const GithubTriageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<McpLocalTool> tools = [
      ListRepoIssuesTool(),
      TriageIssueTool(),
      DraftPrReviewTool(),
    ];

    const initialLlm = LlmConfig(
      provider: LlmProvider.openai,
      model: 'gpt-4o-mini',
      apiKey: '',
      useStreaming: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.hub, color: Color(0xFF2EA44F)),
            SizedBox(width: 8),
            Text('GitHub Triage & Code Review'),
          ],
        ),
      ),
      body: McpPlayground(
        initialLlmConfig: initialLlm,
        customLocalTools: tools,
        messageContentBuilder: (context, message) {
          if (message == null || message.type != MessageType.toolResponse) {
            return null;
          }
          final content = message.content.trim();
          if (!content.startsWith('{') || !content.endsWith('}')) return null;

          try {
            final data = jsonDecode(content) as Map<String, dynamic>;
            if (message.toolName == 'list_repo_issues') {
              return _buildIssuesCard(context, data);
            }
          } catch (_) {}
          return null;
        },
      ),
    );
  }

  Widget _buildIssuesCard(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final issues = (data['issues'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Repository Issues (${issues.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            for (final issue in issues)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${issue['number']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue['title']?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: [
                              for (final label in (issue['labels'] as List? ?? []))
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    label.toString(),
                                    style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tool to list repository issues.
class ListRepoIssuesTool extends McpLocalTool {
  @override
  String get name => 'list_repo_issues';

  @override
  String get description => 'List open issues and bug reports from repository.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'repo': {'type': 'string', 'description': 'Repository name, e.g. "flutter/flutter"'},
          'filter': {'type': 'string', 'description': 'Filter by state (open, closed, all)'},
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final issues = [
      {
        'number': 142,
        'title': 'Memory leak in image caching pipeline on Android',
        'author': 'dev_alex',
        'labels': ['bug', 'platform-android', 'p1'],
        'comments': 4,
      },
      {
        'number': 143,
        'title': 'Add support for custom LLM headers in Anthropic adapter',
        'author': 'sarah_m',
        'labels': ['enhancement', 'ai-sdk'],
        'comments': 2,
      },
      {
        'number': 144,
        'title': 'Update documentation for GenUI dynamic schema binding',
        'author': 'chris_k',
        'labels': ['documentation', 'good-first-issue'],
        'comments': 0,
      },
    ];

    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({'success': true, 'issues': issues}),
        ),
      ],
    );
  }
}

/// Tool to triage issue with priority and auto-labeling.
class TriageIssueTool extends McpLocalTool {
  @override
  String get name => 'triage_issue';

  @override
  String get description => 'Triage an issue by assigning priority, labels, and recommended engineer.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'issue_number': {'type': 'number'},
          'priority': {'type': 'string'},
          'assigned_labels': {'type': 'array', 'items': {'type': 'string'}},
          'assignee': {'type': 'string'},
          'reasoning': {'type': 'string'},
        },
        'required': ['issue_number', 'priority', 'assigned_labels'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({'success': true, 'triage_result': arguments}),
        ),
      ],
    );
  }
}

/// Tool to draft pull request review.
class DraftPrReviewTool extends McpLocalTool {
  @override
  String get name => 'draft_pr_review';

  @override
  String get description => 'Draft a comprehensive code review with inline comments and approval state.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'pr_number': {'type': 'number'},
          'decision': {'type': 'string', 'description': 'APPROVE, REQUEST_CHANGES, COMMENT'},
          'comments': {'type': 'array', 'items': {'type': 'string'}},
          'summary': {'type': 'string'},
        },
        'required': ['pr_number', 'decision', 'summary'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    return MCPToolResult(
      content: [
        MCPContent(
          type: 'text',
          text: jsonEncode({'success': true, 'review_status': 'submitted', 'review': arguments}),
        ),
      ],
    );
  }
}

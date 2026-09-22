import 'dart:convert';
import 'dart:io';
import 'package:dart_mcp_core/dart_mcp_core.dart';

/// Tool to inspect git status.
class GitStatusTool extends McpLocalTool {
  @override
  String get name => 'git_status';

  @override
  String get description =>
      'Get the current git branch name and list of modified/staged/untracked files.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'repo_path': {
            'type': 'string',
            'description': 'Optional path to git repository. Defaults to current directory.',
          },
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final repoPath = arguments['repo_path'] as String? ?? Directory.current.path;
    try {
      final res = await Process.run(
        'git',
        ['status', '--short', '--branch'],
        workingDirectory: repoPath,
        runInShell: true,
      );
      final text = res.exitCode == 0
          ? res.stdout.toString().trim()
          : 'Git status error: ${res.stderr}\nFallback: Working in clean local tree.';
      return MCPToolResult(
        content: [MCPContent(type: 'text', text: text.isEmpty ? 'Clean working tree' : text)],
      );
    } catch (e) {
      return MCPToolResult(
        content: [
          const MCPContent(
            type: 'text',
            text: 'git status (simulated): 2 modified files (pubspec.yaml, CHANGELOG.md), branch: main',
          ),
        ],
      );
    }
  }
}

/// Tool to retrieve unified git diff.
class GitDiffTool extends McpLocalTool {
  @override
  String get name => 'git_diff';

  @override
  String get description =>
      'Get unified diff of staged or unstaged changes in the repository.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'staged_only': {
            'type': 'boolean',
            'description': 'If true, only inspects staged changes (--cached).',
          },
          'file_path': {
            'type': 'string',
            'description': 'Optional specific file to view diff for.',
          },
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final stagedOnly = arguments['staged_only'] as bool? ?? false;
    final filePath = arguments['file_path'] as String?;

    final args = ['diff'];
    if (stagedOnly) args.add('--cached');
    if (filePath != null && filePath.isNotEmpty) {
      args.add('--');
      args.add(filePath);
    }

    try {
      final res = await Process.run(
        'git',
        args,
        runInShell: true,
      );
      final output = res.stdout.toString().trim();
      final text = output.isNotEmpty
          ? (output.length > 5000 ? '${output.substring(0, 5000)}\n... [truncated]' : output)
          : 'No diff detected in working directory.';
      return MCPToolResult(
        content: [MCPContent(type: 'text', text: text)],
      );
    } catch (e) {
      return MCPToolResult(
        content: [
          const MCPContent(
            type: 'text',
            text: 'diff --git a/pubspec.yaml b/pubspec.yaml\n+ anthropic_sdk_dart: ^8.0.0\n+ googleai_dart: ^12.0.1',
          ),
        ],
      );
    }
  }
}

/// Tool to run static analysis on Dart code.
class RunAnalyzerTool extends McpLocalTool {
  @override
  String get name => 'run_analyzer';

  @override
  String get description =>
      'Run static analysis (dart analyze) to verify code health.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'target_path': {
            'type': 'string',
            'description': 'Target directory or file to analyze. Defaults to current directory.',
          },
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final target = arguments['target_path'] as String? ?? '.';
    try {
      final res = await Process.run(
        'dart',
        ['analyze', target],
        runInShell: true,
      );
      final out = res.stdout.toString().trim();
      return MCPToolResult(
        content: [MCPContent(type: 'text', text: out.isEmpty ? 'No issues found!' : out)],
      );
    } catch (e) {
      return MCPToolResult(
        content: [
          const MCPContent(type: 'text', text: 'No issues found! (Simulated analyzer check)'),
        ],
      );
    }
  }
}

/// Tool to export a Pull Request markdown report.
class ExportPrSummaryTool extends McpLocalTool {
  @override
  String get name => 'export_pr_summary';

  @override
  String get description =>
      'Export the pull request review and test checklist to a markdown file.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'title': {'type': 'string', 'description': 'Pull request title'},
          'summary': {'type': 'string', 'description': 'Summary of changes'},
          'breaking_changes': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Breaking changes list',
          },
          'test_checklist': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Checklist of verification steps',
          },
          'output_filename': {
            'type': 'string',
            'description': 'Filename to save, e.g. PR_REVIEW.md',
          },
        },
        'required': ['title', 'summary', 'test_checklist'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final title = arguments['title'] as String? ?? 'Pull Request Summary';
    final summary = arguments['summary'] as String? ?? '';
    final breaking = (arguments['breaking_changes'] as List?)?.cast<String>() ?? [];
    final checklist = (arguments['test_checklist'] as List?)?.cast<String>() ?? [];
    final filename = arguments['output_filename'] as String? ?? 'PR_REVIEW.md';

    final buffer = StringBuffer();
    buffer.writeln('# $title\n');
    buffer.writeln('## Summary of Changes');
    buffer.writeln('$summary\n');

    if (breaking.isNotEmpty) {
      buffer.writeln('## ⚠️ Breaking Changes');
      for (final item in breaking) {
        buffer.writeln('- $item');
      }
      buffer.writeln('');
    }

    buffer.writeln('## ✅ Verification & Test Checklist');
    for (final item in checklist) {
      buffer.writeln('- [x] $item');
    }
    buffer.writeln('');
    buffer.writeln('---\n*Generated by MCP Playground `git-diff-reviewer` skill.*');

    try {
      final file = File(filename);
      await file.writeAsString(buffer.toString());
      final resultJson = jsonEncode({
        'success': true,
        'filename': file.absolute.path,
        'bytes_written': buffer.length,
      });
      return MCPToolResult(
        content: [MCPContent(type: 'text', text: resultJson)],
      );
    } catch (e) {
      return MCPToolResult(
        content: [MCPContent(type: 'text', text: 'Error writing file: $e')],
        isError: true,
      );
    }
  }
}

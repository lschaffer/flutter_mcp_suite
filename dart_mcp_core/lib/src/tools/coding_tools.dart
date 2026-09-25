import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../mcp/local_tools.dart';
import '../models/models.dart';

/// Base tool helper providing working directory resolution and normalization.
abstract class BaseCodingTool extends McpLocalTool {
  final String workingDirectory;

  BaseCodingTool({String? workingDirectory})
      : workingDirectory = workingDirectory ?? Directory.current.path;

  /// Resolves relative path against [workingDirectory].
  String resolvePath(String relativeOrAbsolutePath) {
    if (p.isAbsolute(relativeOrAbsolutePath)) {
      return p.normalize(relativeOrAbsolutePath);
    }
    return p.normalize(p.join(workingDirectory, relativeOrAbsolutePath));
  }

  /// Verifies file or directory is inside workspace (or returns canonical path).
  String getCanonicalPath(String filePath) {
    return resolvePath(filePath);
  }
}

/// Tool: `fs_find` - Find files and directories using glob-like patterns.
class FsFindTool extends BaseCodingTool {
  FsFindTool({super.workingDirectory});

  @override
  String get name => 'fs_find';

  @override
  String get description =>
      'Find files and directories in the workspace matching a pattern (e.g., "*.csproj", "*.dart", "global.json"). Ignores .git, bin, obj, build, and node_modules by default.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'pattern': {
            'type': 'string',
            'description':
                'Filename or wildcard pattern to search for (e.g., "*.csproj", "tasks.md", "README*").',
          },
          'directory': {
            'type': 'string',
            'description':
                'Relative subdirectory to search in. Defaults to root workspace.',
          },
          'maxResults': {
            'type': 'integer',
            'description': 'Maximum number of results to return. Default is 50.',
          },
        },
        'required': ['pattern'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final pattern = (arguments['pattern'] as String? ?? '').trim();
    final subDir = arguments['directory'] as String?;
    final maxResults = (arguments['maxResults'] as int?) ?? 50;

    final targetDir = subDir != null ? resolvePath(subDir) : workingDirectory;
    final dir = Directory(targetDir);

    if (!dir.existsSync()) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(
            type: 'text',
            text: 'Directory does not exist: $targetDir',
          ),
        ],
      );
    }

    final ignoreDirs = {
      '.git',
      '.dart_tool',
      'node_modules',
      'bin',
      'obj',
      'build',
      '.idea',
      '.vscode',
    };

    final normalizedPattern = pattern.replaceAll(r'\', '/');
    final reg = _patternToRegex(normalizedPattern);
    final matches = <String>[];

    try {
      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        final relative = p.relative(entity.path, from: workingDirectory).replaceAll(r'\', '/');
        final parts = relative.split('/');
        if (parts.any((segment) => ignoreDirs.contains(segment))) {
          continue;
        }

        final basename = p.basename(entity.path);
        if (reg.hasMatch(basename) || reg.hasMatch(relative)) {
          final isDir = entity is Directory ? '/' : '';
          matches.add('$relative$isDir');
          if (matches.length >= maxResults) break;
        }
      }

      if (matches.isEmpty) {
        return MCPToolResult(
          content: [
            MCPContent(
              type: 'text',
              text: 'No files or directories matching "$pattern" found.',
            ),
          ],
        );
      }

      return MCPToolResult(
        content: [
          MCPContent(
            type: 'text',
            text:
                'Found ${matches.length} matches:\n${matches.map((m) => '  $m').join('\n')}',
          ),
        ],
      );
    } catch (e) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(type: 'text', text: 'Error searching directory: $e'),
        ],
      );
    }
  }

  RegExp _patternToRegex(String pattern) {
    if (pattern.isEmpty) return RegExp('.*');
    final normalized = pattern.replaceAll(r'\', '/');
    final escaped = RegExp.escape(normalized)
        .replaceAll(r'\*', '.*')
        .replaceAll(r'\?', '.');
    return RegExp('^$escaped\$', caseSensitive: false);
  }
}

/// Tool: `fs_read_file` - Read text content from a file with line numbers & pagination.
class FsReadFileTool extends BaseCodingTool {
  FsReadFileTool({super.workingDirectory});

  @override
  String get name => 'fs_read_file';

  @override
  String get description =>
      'Read file content with line numbers. Supports optional startLine and endLine (1-indexed) to read slices of large files.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'path': {
            'type': 'string',
            'description': 'Relative path to file in workspace.',
          },
          'startLine': {
            'type': 'integer',
            'description': 'Start line number (1-indexed).',
          },
          'endLine': {
            'type': 'integer',
            'description': 'End line number (inclusive, 1-indexed).',
          },
        },
        'required': ['path'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final relPath = arguments['path'] as String? ?? '';
    final fullPath = resolvePath(relPath);
    final file = File(fullPath);

    if (!file.existsSync()) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(
            type: 'text',
            text: 'File does not exist: $relPath',
          ),
        ],
      );
    }

    try {
      final lines = file.readAsLinesSync();
      final totalLines = lines.length;
      final start = (arguments['startLine'] as int?) ?? 1;
      final end = (arguments['endLine'] as int?) ?? totalLines;

      final int clampedStart = start.clamp(1, totalLines > 0 ? totalLines : 1);
      final int clampedEnd = end.clamp(clampedStart, totalLines > 0 ? totalLines : 1);

      if (totalLines == 0) {
        return MCPToolResult(
          content: [
            MCPContent(type: 'text', text: 'File "$relPath" is empty (0 lines).'),
          ],
        );
      }

      final hasExplicitRange = arguments['endLine'] != null || arguments['startLine'] != null;
      int effectiveEnd = clampedEnd;
      bool truncated = false;
      if (!hasExplicitRange && totalLines > 800) {
        effectiveEnd = (clampedStart + 799).clamp(clampedStart, totalLines);
        truncated = true;
      } else if (effectiveEnd - clampedStart > 800) {
        effectiveEnd = clampedStart + 799;
        truncated = true;
      }

      final buffer = StringBuffer();
      buffer.writeln('File: $relPath ($clampedStart-$effectiveEnd of $totalLines lines):');
      for (int i = clampedStart; i <= effectiveEnd; i++) {
        buffer.writeln('${i.toString().padLeft(4)}: ${lines[i - 1]}');
      }
      if (truncated) {
        buffer.writeln('');
        buffer.writeln(
          '[... Truncated: showing lines $clampedStart-$effectiveEnd of $totalLines lines. '
          'Use startLine=${effectiveEnd + 1} and endLine=${(effectiveEnd + 800).clamp(1, totalLines)} to view more ...]',
        );
      }

      return MCPToolResult(
        content: [MCPContent(type: 'text', text: buffer.toString())],
      );
    } catch (e) {
      return MCPToolResult(
        isError: true,
        content: [MCPContent(type: 'text', text: 'Error reading $relPath: $e')],
      );
    }
  }
}

/// Tool: `fs_write_file` - Create or overwrite a file.
class FsWriteFileTool extends BaseCodingTool {
  FsWriteFileTool({super.workingDirectory});

  @override
  String get name => 'fs_write_file';

  @override
  String get description =>
      'Create a new file or completely overwrite an existing file with the provided content. Creates parent directories automatically.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.write;

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'path': {
            'type': 'string',
            'description': 'Relative path to file in workspace.',
          },
          'content': {
            'type': 'string',
            'description': 'Full text content to write into file.',
          },
        },
        'required': ['path', 'content'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final relPath = arguments['path'] as String? ?? '';
    final content = arguments['content'] as String? ?? '';
    final fullPath = resolvePath(relPath);
    final file = File(fullPath);

    try {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
      final lineCount = content.split('\n').length;
      return MCPToolResult(
        content: [
          MCPContent(
            type: 'text',
            text: 'Successfully wrote $lineCount lines to $relPath.',
          ),
        ],
      );
    } catch (e) {
      return MCPToolResult(
        isError: true,
        content: [MCPContent(type: 'text', text: 'Error writing to $relPath: $e')],
      );
    }
  }
}

/// Tool: `fs_replace_text` - Surgical search and replace of exact text in a file.
class FsReplaceTextTool extends BaseCodingTool {
  FsReplaceTextTool({super.workingDirectory});

  @override
  String get name => 'fs_replace_text';

  @override
  String get description =>
      'Replace an exact, unique target code snippet with replacement text in a file. Very reliable for modifying specific blocks, config lines, or functions without rewriting the entire file.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.write;

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'path': {
            'type': 'string',
            'description': 'Relative path to file in workspace.',
          },
          'search': {
            'type': 'string',
            'description':
                'Exact string snippet to search for. Must be unique in the file to avoid accidental multi-edits.',
          },
          'replace': {
            'type': 'string',
            'description': 'Replacement string snippet.',
          },
        },
        'required': ['path', 'search', 'replace'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final relPath = arguments['path'] as String? ?? '';
    final search = arguments['search'] as String? ?? '';
    final replace = arguments['replace'] as String? ?? '';

    final fullPath = resolvePath(relPath);
    final file = File(fullPath);

    if (!file.existsSync()) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(type: 'text', text: 'File does not exist: $relPath'),
        ],
      );
    }

    try {
      final content = file.readAsStringSync();
      final normalizedContent = content.replaceAll('\r\n', '\n');
      final normalizedSearch = search.replaceAll('\r\n', '\n');
      final normalizedReplace = replace.replaceAll('\r\n', '\n');

      if (!normalizedContent.contains(normalizedSearch)) {
        return MCPToolResult(
          isError: true,
          content: [
            MCPContent(
              type: 'text',
              text:
                  'Target search text not found in $relPath. Verify whitespace and line numbers using fs_read_file.',
            ),
          ],
        );
      }

      final occurrences = normalizedSearch.allMatches(normalizedContent).length;
      if (occurrences > 1) {
        return MCPToolResult(
          isError: true,
          content: [
            MCPContent(
              type: 'text',
              text:
                  'Search text occurred $occurrences times in $relPath. Please provide a more unique code snippet with surrounding context lines.',
            ),
          ],
        );
      }

      final updated =
          normalizedContent.replaceFirst(normalizedSearch, normalizedReplace);
      final finalContent = content.contains('\r\n')
          ? updated.replaceAll('\n', '\r\n')
          : updated;

      file.writeAsStringSync(finalContent);

      return MCPToolResult(
        content: [
          MCPContent(
            type: 'text',
            text:
                'Successfully replaced target text block in $relPath (1 substitution applied).',
          ),
        ],
      );
    } catch (e) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(type: 'text', text: 'Error editing file $relPath: $e'),
        ],
      );
    }
  }
}

/// Tool: `terminal_exec` - Run CLI commands in the workspace (e.g. dotnet build, git diff, dart test).
class TerminalExecTool extends BaseCodingTool {
  TerminalExecTool({super.workingDirectory});

  @override
  String get name => 'terminal_exec';

  @override
  String get description =>
      'Execute a command line command in the terminal inside the workspace directory (e.g., "dotnet --version", "dotnet build", "git status", "dart test"). Returns stdout and stderr.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.execute;

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'command': {
            'type': 'string',
            'description': 'The terminal command string to execute.',
          },
          'timeoutSeconds': {
            'type': 'integer',
            'description':
                'Maximum execution time in seconds. Defaults to 60 seconds.',
          },
        },
        'required': ['command'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final command = (arguments['command'] as String? ?? '').trim();
    final timeoutSec = (arguments['timeoutSeconds'] as int?) ?? 60;

    if (command.isEmpty) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(type: 'text', text: 'Command cannot be empty.'),
        ],
      );
    }

    try {
      final String shell;
      final List<String> shellArgs;

      if (Platform.isWindows) {
        shell = 'cmd.exe';
        shellArgs = ['/c', command];
      } else {
        shell = '/bin/sh';
        shellArgs = ['-c', command];
      }

      final result = await Process.run(
        shell,
        shellArgs,
        workingDirectory: workingDirectory,
        runInShell: true,
      ).timeout(
        Duration(seconds: timeoutSec),
        onTimeout: () => ProcessResult(
          -1,
          -1,
          '',
          'Command timed out after $timeoutSec seconds.',
        ),
      );

      final buffer = StringBuffer();
      buffer.writeln('Exit Code: ${result.exitCode}');
      if (result.stdout.toString().trim().isNotEmpty) {
        buffer.writeln('STDOUT:\n${result.stdout.toString().trim()}');
      }
      if (result.stderr.toString().trim().isNotEmpty) {
        buffer.writeln('STDERR:\n${result.stderr.toString().trim()}');
      }

      return MCPToolResult(
        isError: result.exitCode != 0,
        content: [
          MCPContent(type: 'text', text: buffer.toString().trim()),
        ],
      );
    } catch (e) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(
            type: 'text',
            text: 'Failed to run command "$command": $e',
          ),
        ],
      );
    }
  }
}

/// Tool: `fetch_web` - Fetch content from a URL via HTTP GET request (useful for pub.dev API, NuGet, docs, and JSON endpoints).
class FetchWebTool extends BaseCodingTool {
  FetchWebTool({super.workingDirectory});

  @override
  String get name => 'fetch_web';

  @override
  String get description =>
      'Fetch web page content, API JSON, or documentation via HTTP GET request (e.g., https://pub.dev/api/packages/dart_mcp_core, https://registry.npmjs.org/express/latest).';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.network;

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'url': {
            'type': 'string',
            'description': 'The full HTTP/HTTPS URL to fetch.',
          },
          'maxChars': {
            'type': 'integer',
            'description':
                'Maximum characters of response body to return. Defaults to 20000.',
          },
        },
        'required': ['url'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final urlStr = (arguments['url'] as String? ?? '').trim();
    final maxChars = (arguments['maxChars'] as int?) ?? 20000;

    if (urlStr.isEmpty) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(type: 'text', text: 'URL parameter cannot be empty.'),
        ],
      );
    }

    final uri = Uri.tryParse(urlStr);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(
            type: 'text',
            text: 'Invalid URL scheme. Only http:// and https:// are supported.',
          ),
        ],
      );
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'TealKit-Agent/1.1.0 (Dart/Pure)');
      request.headers.set('Accept', 'application/json, text/plain, text/html, */*');

      final response = await request.close().timeout(const Duration(seconds: 20));
      final rawBody = await response.transform(utf8.decoder).join();
      client.close();

      final truncatedBody = rawBody.length > maxChars
          ? '${rawBody.substring(0, maxChars)}\n\n[... truncated ${rawBody.length - maxChars} additional characters ...]'
          : rawBody;

      return MCPToolResult(
        isError: response.statusCode >= 400,
        content: [
          MCPContent(
            type: 'text',
            text:
                'HTTP ${response.statusCode} (${response.reasonPhrase})\n\n$truncatedBody',
          ),
        ],
      );
    } catch (e) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(type: 'text', text: 'Failed to fetch "$urlStr": $e'),
        ],
      );
    }
  }
}

/// Tool: `fs_list_dir` - List contents of a directory.
class FsListDirTool extends BaseCodingTool {
  FsListDirTool({super.workingDirectory});

  @override
  String get name => 'fs_list_dir';

  @override
  String get description =>
      'List files and subdirectories in a directory with file sizes and type tags.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.read;

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'path': {
            'type': 'string',
            'description':
                'Relative path of directory to list. Defaults to workspace root (".").',
          },
          'recursive': {
            'type': 'boolean',
            'description': 'Whether to list subdirectories recursively. Default is false.',
          },
          'maxResults': {
            'type': 'integer',
            'description': 'Maximum number of items to return. Default is 100.',
          },
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final relPath = (arguments['path'] as String? ?? '.').trim();
    final recursive = (arguments['recursive'] as bool?) ?? false;
    final maxResults = (arguments['maxResults'] as int?) ?? 100;

    final targetPath = resolvePath(relPath.isEmpty ? '.' : relPath);
    final dir = Directory(targetPath);

    if (!dir.existsSync()) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(
            type: 'text',
            text: 'Directory not found: $relPath',
          ),
        ],
      );
    }

    try {
      final entities = dir.listSync(recursive: recursive, followLinks: false);
      final entries = <String>[];

      for (final e in entities) {
        final rel = p.relative(e.path, from: workingDirectory).replaceAll(r'\', '/');
        if (e is Directory) {
          entries.add('[DIR]  $rel/');
        } else if (e is File) {
          final size = e.lengthSync();
          entries.add('[FILE] $rel ($size bytes)');
        } else {
          entries.add('[OTHER] $rel');
        }
        if (entries.length >= maxResults) break;
      }

      if (entries.isEmpty) {
        return MCPToolResult(
          content: [
            MCPContent(
              type: 'text',
              text: 'Directory "$relPath" is empty.',
            ),
          ],
        );
      }

      return MCPToolResult(
        content: [
          MCPContent(
            type: 'text',
            text:
                'Directory listing for "$relPath" (${entries.length} items):\n${entries.join('\n')}',
          ),
        ],
      );
    } catch (e) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(type: 'text', text: 'Failed to list directory "$relPath": $e'),
        ],
      );
    }
  }
}

/// Tool: `fs_create_dir` - Create directory and parent directories.
class FsCreateDirTool extends BaseCodingTool {
  FsCreateDirTool({super.workingDirectory});

  @override
  String get name => 'fs_create_dir';

  @override
  String get description =>
      'Create a new directory (and any missing parent directories) in the workspace.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.write;

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'path': {
            'type': 'string',
            'description': 'Relative path of directory to create (e.g., "src/Core/Models").',
          },
        },
        'required': ['path'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final relPath = (arguments['path'] as String? ?? '').trim();
    if (relPath.isEmpty) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(type: 'text', text: 'Path parameter cannot be empty.'),
        ],
      );
    }

    final targetPath = resolvePath(relPath);
    final dir = Directory(targetPath);

    try {
      if (dir.existsSync()) {
        return MCPToolResult(
          content: [
            MCPContent(
              type: 'text',
              text: 'Directory already exists: $relPath',
            ),
          ],
        );
      }

      dir.createSync(recursive: true);
      return MCPToolResult(
        content: [
          MCPContent(
            type: 'text',
            text: 'Successfully created directory: $relPath',
          ),
        ],
      );
    } catch (e) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(type: 'text', text: 'Failed to create directory "$relPath": $e'),
        ],
      );
    }
  }
}

/// Tool: `fs_move` - Rename or move a file or directory.
class FsMoveTool extends BaseCodingTool {
  FsMoveTool({super.workingDirectory});

  @override
  String get name => 'fs_move';

  @override
  String get description =>
      'Move or rename a file or directory within the workspace (e.g., rename folder or file).';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.write;

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'sourcePath': {
            'type': 'string',
            'description': 'Current relative path of the file or directory.',
          },
          'destinationPath': {
            'type': 'string',
            'description': 'New relative path / destination.',
          },
          'overwrite': {
            'type': 'boolean',
            'description': 'Overwrite destination if it already exists. Default is false.',
          },
        },
        'required': ['sourcePath', 'destinationPath'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final srcStr = (arguments['sourcePath'] as String? ?? '').trim();
    final destStr = (arguments['destinationPath'] as String? ?? '').trim();
    final overwrite = (arguments['overwrite'] as bool?) ?? false;

    if (srcStr.isEmpty || destStr.isEmpty) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(
            type: 'text',
            text: 'Both sourcePath and destinationPath are required.',
          ),
        ],
      );
    }

    final srcResolved = resolvePath(srcStr);
    final destResolved = resolvePath(destStr);

    final isFile = File(srcResolved).existsSync();
    final isDir = Directory(srcResolved).existsSync();

    if (!isFile && !isDir) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(type: 'text', text: 'Source path not found: $srcStr'),
        ],
      );
    }

    try {
      if (isFile) {
        final srcFile = File(srcResolved);
        final destFile = File(destResolved);
        if (destFile.existsSync() && !overwrite) {
          return MCPToolResult(
            isError: true,
            content: [
              MCPContent(
                type: 'text',
                text: 'Destination file already exists: $destStr (set overwrite=true to replace).',
              ),
            ],
          );
        }
        destFile.parent.createSync(recursive: true);
        if (destFile.existsSync() && overwrite) {
          destFile.deleteSync();
        }
        srcFile.renameSync(destResolved);
        return MCPToolResult(
          content: [
            MCPContent(
              type: 'text',
              text: 'Successfully moved file from "$srcStr" to "$destStr".',
            ),
          ],
        );
      } else {
        final srcDir = Directory(srcResolved);
        final destDir = Directory(destResolved);
        if (destDir.existsSync()) {
          if (!overwrite) {
            return MCPToolResult(
              isError: true,
              content: [
                MCPContent(
                  type: 'text',
                  text: 'Destination directory already exists: $destStr',
                ),
              ],
            );
          }
          destDir.deleteSync(recursive: true);
        }
        destDir.parent.createSync(recursive: true);
        srcDir.renameSync(destResolved);
        return MCPToolResult(
          content: [
            MCPContent(
              type: 'text',
              text: 'Successfully moved directory from "$srcStr" to "$destStr".',
            ),
          ],
        );
      }
    } catch (e) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(type: 'text', text: 'Failed to move "$srcStr" to "$destStr": $e'),
        ],
      );
    }
  }
}

/// Tool: `fs_delete` - Delete file(s) or directory.
class FsDeleteTool extends BaseCodingTool {
  FsDeleteTool({super.workingDirectory});

  @override
  String get name => 'fs_delete';

  @override
  String get description =>
      'Delete a file or directory within the workspace. For non-empty directories, set recursive=true.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.write;

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'path': {
            'type': 'string',
            'description': 'Relative path of file or directory to delete.',
          },
          'recursive': {
            'type': 'boolean',
            'description':
                'If true, deletes directories and all their contents recursively. Default is false.',
          },
        },
        'required': ['path'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final relPath = (arguments['path'] as String? ?? '').trim();
    final recursive = (arguments['recursive'] as bool?) ?? false;

    if (relPath.isEmpty) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(type: 'text', text: 'Path parameter cannot be empty.'),
        ],
      );
    }

    final targetPath = resolvePath(relPath);

    // Prevent accidental deletion of workspace root
    if (p.normalize(targetPath) == p.normalize(workingDirectory)) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(
            type: 'text',
            text: 'Refusing to delete the workspace root directory.',
          ),
        ],
      );
    }

    final file = File(targetPath);
    final dir = Directory(targetPath);

    try {
      if (file.existsSync()) {
        file.deleteSync();
        return MCPToolResult(
          content: [
            MCPContent(type: 'text', text: 'Successfully deleted file: $relPath'),
          ],
        );
      } else if (dir.existsSync()) {
        dir.deleteSync(recursive: recursive);
        return MCPToolResult(
          content: [
            MCPContent(
              type: 'text',
              text: 'Successfully deleted directory: $relPath',
            ),
          ],
        );
      } else {
        return MCPToolResult(
          isError: true,
          content: [
            MCPContent(type: 'text', text: 'Path does not exist: $relPath'),
          ],
        );
      }
    } catch (e) {
      return MCPToolResult(
        isError: true,
        content: [
          MCPContent(type: 'text', text: 'Failed to delete "$relPath": $e'),
        ],
      );
    }
  }
}

/// Helper factory for creating standard coding tools for agents.
class CodingTools {
  /// Instantiates all standard coding tools bound to [workingDirectory].
  static List<McpLocalTool> createAll({String? workingDirectory}) => [
        FsFindTool(workingDirectory: workingDirectory),
        FsListDirTool(workingDirectory: workingDirectory),
        FsReadFileTool(workingDirectory: workingDirectory),
        FsWriteFileTool(workingDirectory: workingDirectory),
        FsReplaceTextTool(workingDirectory: workingDirectory),
        FsCreateDirTool(workingDirectory: workingDirectory),
        FsMoveTool(workingDirectory: workingDirectory),
        FsDeleteTool(workingDirectory: workingDirectory),
        TerminalExecTool(workingDirectory: workingDirectory),
        FetchWebTool(workingDirectory: workingDirectory),
      ];
}

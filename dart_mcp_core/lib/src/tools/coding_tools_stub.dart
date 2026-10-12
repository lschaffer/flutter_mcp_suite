// Stub implementation of coding tools for web/wasm where dart:io is unavailable.
import '../mcp/local_tools.dart';
import '../models/models.dart';

abstract class BaseCodingTool extends McpLocalTool {
  final String workingDirectory;
  BaseCodingTool({String? workingDirectory}) : workingDirectory = workingDirectory ?? '';
  String resolvePath(String relativeOrAbsolutePath) => relativeOrAbsolutePath;
  String getCanonicalPath(String filePath) => filePath;
}

class FsFindTool extends BaseCodingTool {
  FsFindTool({super.workingDirectory});
  @override
  String get name => 'fs_find';
  @override
  String get description => 'Find files and directories in the workspace.';
  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {'pattern': {'type': 'string'}},
      };
  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    throw UnsupportedError('FsFindTool is not supported on this platform.');
  }
}

class FsReadFileTool extends BaseCodingTool {
  FsReadFileTool({super.workingDirectory});
  @override
  String get name => 'fs_read_file';
  @override
  String get description => 'Read file contents.';
  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {'path': {'type': 'string'}},
      };
  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    throw UnsupportedError('FsReadFileTool is not supported on this platform.');
  }
}

class FsWriteFileTool extends BaseCodingTool {
  FsWriteFileTool({super.workingDirectory});
  @override
  String get name => 'fs_write_file';
  @override
  String get description => 'Write file contents.';
  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'path': {'type': 'string'},
          'content': {'type': 'string'},
        },
      };
  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    throw UnsupportedError('FsWriteFileTool is not supported on this platform.');
  }
}

class FsReplaceTextTool extends BaseCodingTool {
  FsReplaceTextTool({super.workingDirectory});
  @override
  String get name => 'fs_replace_text';
  @override
  String get description => 'Replace text in file.';
  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {'path': {'type': 'string'}},
      };
  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    throw UnsupportedError('FsReplaceTextTool is not supported on this platform.');
  }
}

class TerminalExecTool extends BaseCodingTool {
  TerminalExecTool({super.workingDirectory});
  @override
  String get name => 'terminal_exec';
  @override
  String get description => 'Execute terminal commands.';
  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {'command': {'type': 'string'}},
      };
  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    throw UnsupportedError('TerminalExecTool is not supported on this platform.');
  }
}

class FetchWebTool extends BaseCodingTool {
  FetchWebTool({super.workingDirectory});
  @override
  String get name => 'fetch_web';
  @override
  String get description => 'Fetch web content.';
  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {'url': {'type': 'string'}},
      };
  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    throw UnsupportedError('FetchWebTool is not supported on this platform.');
  }
}

class FsListDirTool extends BaseCodingTool {
  FsListDirTool({super.workingDirectory});
  @override
  String get name => 'fs_list_dir';
  @override
  String get description => 'List directory contents.';
  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {'directory': {'type': 'string'}},
      };
  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    throw UnsupportedError('FsListDirTool is not supported on this platform.');
  }
}

class FsCreateDirTool extends BaseCodingTool {
  FsCreateDirTool({super.workingDirectory});
  @override
  String get name => 'fs_create_dir';
  @override
  String get description => 'Create directory.';
  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {'path': {'type': 'string'}},
      };
  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    throw UnsupportedError('FsCreateDirTool is not supported on this platform.');
  }
}

class FsMoveTool extends BaseCodingTool {
  FsMoveTool({super.workingDirectory});
  @override
  String get name => 'fs_move';
  @override
  String get description => 'Move or rename file/directory.';
  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'source': {'type': 'string'},
          'destination': {'type': 'string'},
        },
      };
  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    throw UnsupportedError('FsMoveTool is not supported on this platform.');
  }
}

class FsDeleteTool extends BaseCodingTool {
  FsDeleteTool({super.workingDirectory});
  @override
  String get name => 'fs_delete';
  @override
  String get description => 'Delete file or directory.';
  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {'path': {'type': 'string'}},
      };
  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    throw UnsupportedError('FsDeleteTool is not supported on this platform.');
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

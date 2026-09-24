import '../models/models.dart';

/// Categorizes tool execution risk level for human-in-the-loop approvals.
enum ToolRiskLevel {
  /// Read-only / discovery (e.g. read_file, find, grep). Usually auto-approved.
  read,

  /// Modification of existing files or creating new ones (e.g. write_file, replace_text).
  write,

  /// Shell / subprocess command execution (e.g. terminal_exec, rm, dotnet).
  execute,

  /// External network requests or remote API actions.
  network,
}

/// Base class representing a Dart-native local tool.
abstract class McpLocalTool {
  /// The unique identifier name of the tool.
  String get name;

  /// A description of what the tool does, used by the LLM.
  String get description;

  /// The input parameters JSON schema mapping for the tool.
  Map<String, dynamic> get inputSchema;

  /// The risk level associated with executing this tool. Defaults to [ToolRiskLevel.read].
  ToolRiskLevel get riskLevel => ToolRiskLevel.read;

  /// Executes the tool actions using the supplied LLM arguments.
  Future<MCPToolResult> execute(Map<String, dynamic> arguments);

  /// Convert to standard MCPTool model representation.
  MCPTool toMCPTool() {
    return MCPTool(
      name: name,
      description: description,
      inputSchema: inputSchema,
    );
  }
}

// Stub implementation for platforms where `dart:io` and child processes are not available (web/wasm).
// ignore_for_file: avoid_print

import 'dart:async';
import 'package:dart_mcp_core/dart_mcp_core.dart';

/// Stub client for platforms that do not support stdio subprocess execution.
class LocalMCPClient extends MCPClient {
  final McpServerConfig serverConfig;

  LocalMCPClient(this.serverConfig, {super.logCallback})
    : super(serverConfig.url);

  @override
  bool get isConnected => false;

  @override
  List<MCPTool> get availableTools => const [];

  @override
  Future<void> connect() async {
    throw UnsupportedError(
      'Local MCP servers (stdio subprocess) are not supported on this platform. '
      'Use remote HTTP/SSE servers instead.',
    );
  }

  @override
  Future<MCPToolResult> callTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    throw UnsupportedError(
      'Local MCP tool execution is not supported on this platform.',
    );
  }

  @override
  Future<void> disconnect() async {}

  @override
  void dispose() {}
}

/// Stub — local server installation and runtime detection are not supported on this platform.
class LocalMcpRuntime {
  static Future<String> serverDir(String serverId) async {
    throw UnsupportedError('Local MCP runtime not supported on this platform.');
  }

  static String pythonVenvExe(String dir) => throw UnsupportedError(
    'Local MCP runtime not supported on this platform.',
  );

  static Map<String, String> augmentedEnv({
    Map<String, String>? baseEnv,
    String? extraPath,
  }) => throw UnsupportedError(
    'Local MCP runtime not supported on this platform.',
  );

  static Future<String?> detectUv() async => null;
  static Future<String?> detectNode() async => null;
  static Future<String?> findNpxCli(String nodePath) async => null;
  static Future<String?> detectPython() async => null;

  static List<String> buildLaunchArgs(McpServerConfig server) => [];

  static Future<String?> install(
    McpServerConfig server, {
    void Function(LocalInstallProgress progress)? onProgress,
  }) async {
    throw UnsupportedError('Local MCP runtime not supported on this platform.');
  }

  static Future<void> uninstall(McpServerConfig server) async {}
}

class LocalMcpException implements Exception {
  final String message;
  const LocalMcpException(this.message);
  @override
  String toString() => 'LocalMcpException: $message';
}

enum LocalInstallStep { detecting, installing, done, failed }

class LocalInstallProgress {
  final LocalInstallStep step;
  final String message;
  const LocalInstallProgress(this.step, this.message);
}

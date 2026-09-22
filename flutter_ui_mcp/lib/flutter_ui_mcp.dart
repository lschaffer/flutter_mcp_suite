library;

export 'package:dart_mcp_core/dart_mcp_core.dart'
    hide
        LocalMCPClient,
        LocalMcpRuntime,
        LocalMcpException,
        LocalInstallStep,
        LocalInstallProgress;
export 'package:flutter_ui_mcp_core/flutter_ui_mcp_core.dart';

export 'flutter_ui_mcp_widget.dart';
import 'flutter_ui_mcp_widget.dart';

/// Main drop-in conversational AI and MCP widget for Flutter.
typedef FlutterUiMcp = McpPlayground;



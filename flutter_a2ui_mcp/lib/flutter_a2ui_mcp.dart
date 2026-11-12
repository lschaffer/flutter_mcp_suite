library;

export 'package:a2ui_core/a2ui_core.dart'
    hide Action, Catalog, ExecutionContext, DataContext, DataModel;
export 'package:a2ui_flutter/a2ui_flutter.dart';
export 'package:a2ui_flutter/basic_catalog.dart';
export 'package:json_schema_builder/json_schema_builder.dart' show Schema, S;
export 'package:dart_mcp_core/dart_mcp_core.dart'
    hide
        LocalMCPClient,
        LocalMcpRuntime,
        LocalMcpException,
        LocalInstallStep,
        LocalInstallProgress;
export 'package:flutter_ui_mcp_core/flutter_ui_mcp_core.dart';

export 'src/a2ui_catalog.dart';
export 'src/a2ui_chat_controller.dart';
export 'src/a2ui_chat_view.dart';
export 'src/flutter_a2ui_mcp.dart';
export 'src/a2ui_bridge.dart';

import 'package:a2ui_core/a2ui_core.dart' hide Action;
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'src/a2ui_catalog.dart';
import 'src/a2ui_chat_controller.dart';
import 'src/a2ui_chat_view.dart';
import 'src/flutter_a2ui_mcp.dart';

/// Primary A2UI Chat View typedef.
typedef McpA2uiChatView = A2uiChatView;

/// Interactive A2UI AI Agent widget for Flutter.
typedef FlutterA2uiMcp = A2uiMcpPlayground;

/// Backwards compatibility typedef for GenUI migrations.
typedef GenuiMcpPlayground = A2uiMcpPlayground;

/// Backwards compatibility typedef for GenUI migrations.
typedef FlutterGenUiMcp = A2uiMcpPlayground;

/// Backwards compatibility typedef for GenUI migrations.
typedef GenuiCatalogItemDefinition = A2uiCatalogItemDefinition;

/// Backwards compatibility typedef for GenUI migrations.
typedef GenuiCatalogRegistry = A2uiCatalogRegistry;

/// Backwards compatibility typedef for GenUI migrations.
typedef GenuiWidgetBuilder = A2uiWidgetBuilder;

/// Backwards compatibility typedef for GenUI migrations.
typedef McpGenuiChatController = McpA2uiChatController;

/// Backwards compatibility typedef for GenUI migrations.
typedef McpGenuiChatView = McpA2uiChatView;

/// Backwards compatibility function for GenUI migrations.
CatalogImplementation buildGenuiCatalog({
  String? catalogJson,
  List<A2uiCatalogItemDefinition>? catalogItems,
  List<ComponentImplementation>? customComponents,
  List<FunctionImplementation>? customFunctions,
}) =>
    buildA2uiCatalog(
      catalogJson: catalogJson,
      catalogItems: catalogItems,
      customComponents: customComponents,
      customFunctions: customFunctions,
    );

library;

export 'package:genui/genui.dart'
    show
        Catalog,
        CatalogItem,
        CatalogItemContext,
        CatalogWidgetBuilder,
        BasicCatalogItems,
        ClientFunction,
        SynchronousClientFunction,
        ClientFunctionReturnType,
        ExecutionContext,
        DataContext,
        DataPath,
        DataModel,
        InMemoryDataModel,
        BasicFunctions,
        JsonMap;
export 'package:json_schema_builder/json_schema_builder.dart' show Schema, S;
export 'package:dart_mcp_core/dart_mcp_core.dart'
    hide
        LocalMCPClient,
        LocalMcpRuntime,
        LocalMcpException,
        LocalInstallStep,
        LocalInstallProgress;
export 'package:flutter_ui_mcp_core/flutter_ui_mcp_core.dart';

export 'src/genui_catalog.dart';
export 'src/genui_chat_controller.dart';
export 'src/genui_chat_view.dart';
export 'src/flutter_genui_mcp.dart';
import 'src/flutter_genui_mcp.dart';

/// Interactive GenUI AI Agent widget for Flutter.
typedef FlutterGenUiMcp = GenuiMcpPlayground;


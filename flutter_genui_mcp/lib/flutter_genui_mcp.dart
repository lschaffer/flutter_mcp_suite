library;

export 'package:a2ui_core/a2ui_core.dart'
    show
        A2uiReturnType,
        BasicCatalog,
        CancellationSignal,
        CommonSchemas,
        ComponentNode,
        DataContext,
        DataModel,
        FunctionImplementation,
        SurfaceModel;
export 'package:a2ui_flutter/a2ui_flutter.dart'
    show
        A2uiSurface,
        CatalogImplementation,
        ChildWidgetBuilder,
        ComponentImplementation,
        ComponentProps,
        ComponentWidgetBuilder;
export 'package:a2ui_flutter/v0_9/basic_catalog.dart'
    show BasicComponents, basicCatalog;
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


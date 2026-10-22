library;

import 'package:flutter_ui_mcp_core/flutter_ui_mcp_core.dart';
import 'src/embedded_llm_adapter.dart';

export 'src/embedded_llm_adapter.dart';

/// Entrypoint to initialize and register the embedded LLM engine for the
/// Flutter MCP Suite (`flutter_ui_mcp_core` & `flutter_ui_mcp`).
class FlutterUiMcpEmbedded {
  FlutterUiMcpEmbedded._();

  /// Registers [EmbeddedLlmAdapter.instance] as the active [EmbeddedLlmDriver]
  /// in [EmbeddedLlmRegistry].
  ///
  /// Call this once in your app's `main()` or before opening embedded model views:
  /// ```dart
  /// void main() {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   FlutterUiMcpEmbedded.register();
  ///   runApp(const MyApp());
  /// }
  /// ```
  static void register() {
    EmbeddedLlmRegistry.register(EmbeddedLlmAdapter.instance);
  }

  /// Unregisters the embedded engine driver.
  static void unregister() {
    EmbeddedLlmRegistry.unregister();
  }
}

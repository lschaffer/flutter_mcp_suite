import 'dart:async';
import 'package:dart_mcp_core/dart_mcp_core.dart';

/// Abstract contract for on-device GGUF / local embedded LLM engines.
///
/// Implemented by companion packages like `flutter_ui_mcp_embedded`
/// using native FFI bindings (`llamadart` / `llama.cpp` / WebGPU).
abstract class EmbeddedLlmDriver {
  /// Whether an embedded model is currently initialized and ready for inference.
  bool get isLoaded;

  /// The file path or URL of the currently loaded model, if any.
  String? get loadedModelPath;

  /// Initialize and load a GGUF model into memory.
  Future<void> initialize(
    String modelPath, {
    int gpuLayers = 0,
    int contextSize = 4096,
    void Function(double progress)? onProgress,
  });

  /// Generate a completion or streaming response using the loaded model.
  Future<LLMResponse> generateResponse({
    required List<ChatMessage> messages,
    List<MCPTool>? availableTools,
    double? temperature,
    int? maxTokens,
    int? topK,
    double? topP,
    double? penalty,
    void Function(String chunk)? onStreamChunk,
  });

  /// Release resources and unload the model.
  Future<void> dispose();

  /// Whether GPU acceleration is supported on the current host.
  Future<bool> isGpuSupported() async => false;

  /// Total and free VRAM in bytes if GPU is supported.
  Future<({int total, int free})> getVramInfo() async => (total: 0, free: 0);
}

/// Global registry for the on-device embedded LLM driver.
///
/// Keeps `flutter_ui_mcp_core` and `flutter_ui_mcp` completely decoupled from
/// heavy native C++ FFI / WebGPU dependencies.
class EmbeddedLlmRegistry {
  EmbeddedLlmRegistry._();

  static EmbeddedLlmDriver? _driver;

  /// Returns the registered [EmbeddedLlmDriver], or `null` if none registered.
  static EmbeddedLlmDriver? get driver => _driver;

  /// Alias for [driver] to support existing adapter access patterns.
  static EmbeddedLlmDriver? get instance => _driver;

  /// Whether an embedded LLM engine driver has been registered.
  static bool get isAvailable => _driver != null;

  /// Register an [EmbeddedLlmDriver] implementation (e.g. from `flutter_ui_mcp_embedded`).
  static void register(EmbeddedLlmDriver driver) {
    _driver = driver;
  }

  /// Unregister the active driver.
  static void unregister() {
    _driver = null;
  }
}

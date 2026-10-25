## 1.4.1

- Upgraded `llamadart` dependency to `^0.16.2`.
- Added standalone showcase application in `example/`.
- Completed 100% public API dartdoc coverage.
- Decoupled from core clipboard/UI dependencies via dedicated `embedded_llm.dart` entrypoint for full Web & WASM compatibility.

## 1.4.0

- Initial release of `flutter_ui_mcp_embedded`.
- Extracted `EmbeddedLlmAdapter` from `flutter_ui_mcp_core` into this dedicated companion package.
- Implements `EmbeddedLlmDriver` for on-device `.gguf` inference using `llamadart` (`llama.cpp` & WebGPU).
- Added `FlutterUiMcpEmbedded.register()` for simple single-line driver registration.

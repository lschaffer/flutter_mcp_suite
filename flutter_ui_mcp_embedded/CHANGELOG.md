## 1.4.0

- Initial release of `flutter_ui_mcp_embedded`.
- Extracted `EmbeddedLlmAdapter` from `flutter_ui_mcp_core` into this dedicated companion package.
- Implements `EmbeddedLlmDriver` for on-device `.gguf` inference using `llamadart` (`llama.cpp` & WebGPU).
- Upgraded `llamadart` dependency to `^0.15.6`.
- Added `FlutterUiMcpEmbedded.register()` for simple single-line driver registration.

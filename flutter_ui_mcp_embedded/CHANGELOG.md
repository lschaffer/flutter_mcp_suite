## 1.5.23

* **Synchronized Suite Upgrade**:
  * Aligned `flutter_ui_mcp_core` dependency to `^1.5.20` (fixes Android/iOS `"Share"` SnackBar action via `XFile.fromData`).

## 1.5.22

* **Synchronized Suite Upgrade (Web / WASM Support)**:
  * Aligned `flutter_ui_mcp_core` dependency to `^1.5.19` (fixes Flutter Web/WASM `dart2wasm` startup and document export crashes).

## 1.5.21

* **Synchronized Suite Upgrade**:
  * Aligned `flutter_ui_mcp_core` dependency to `^1.5.18` (Android/iOS `FilePicker.saveFile` / `ACTION_CREATE_DOCUMENT` export sheet allowing direct saves to `Downloads/`, `Documents/`, and Google Drive).

## 1.5.20

* **Upgraded `llamadart` Runtime (`^0.21.0`)**:
  * Bumped `llamadart` dependency to `^0.21.0` adopting native LiteRT-LM `v0.20.0` (C API 1.1.0), `@litert-lm/core@0.20.0`, WebGPU bridge `v0.1.94`, `stable-diffusion` `v0.4.0-1`, `GenerationParams.ignoreEos`, cancellable streamed Web GGUF loads, and bundled MTP on LiteRT-LM WebGPU.

## 1.5.19

* **Upgraded `llamadart` Runtime (`^0.20.7`) & Suite Synchronization**:
  * Bumped `llamadart` dependency to `^0.20.7`.
  * Aligned dependencies with `dart_mcp_core: ^1.5.16` and `flutter_ui_mcp_core: ^1.5.17`.

## 1.5.18

* **Synchronized Suite Upgrades**:
  * Aligned dependencies with `dart_mcp_core: ^1.5.15` (adds `GenerateImageTool` with static `embeddedImageHandler` hook) and `flutter_ui_mcp_core: ^1.5.16`.

## 1.5.17

* **Upgraded `llamadart` Runtime (`^0.20.4`)**:
  * Bumped `llamadart` dependency to `^0.20.4` adopting `llamadart-native@v1.0.0-4`, `LiteRT-LM v0.19.1-6`, and WebGPU bridge assets `v0.1.87` (fixes Qwen3-0.6B LiteRT-LM split emoji decoding, Qwen3-Coder thinking budget tool-call interruption, and LiteRT-LM Qwen3.5 request drift/echoes).

## 1.5.16

* **Upgraded `llamadart` Runtime (`^0.20.3`)**:
  * Bumped `llamadart` dependency to `^0.20.3` adopting `llamadart-native@v1.0.0-3` (Windows VC++ runtime and GPU memory fit fixes, Android Vulkan fallback settings, Gemma 4 tool-call parsing & prose preservation fixes, and Qwen3-ASR windowed streaming improvements).
* **Synchronized Suite Upgrades**:
  * Aligned dependencies with `dart_mcp_core: ^1.5.14` and `flutter_ui_mcp_core: ^1.5.15`.

## 1.5.15

* **LiteRT-LM (`.litertlm`) Loading & Logging Fixes**:
  * Fixed `EmbeddedLlmAdapter` passing llama.cpp-specific `splitMode` and partial `gpuLayers` to `LiteRtLmBackend` when loading `.litertlm` models; `.litertlm` models now omit `splitMode` and map `gpuLayers` to all-or-CPU (`0` or `ModelParams.maxGpuLayers`).
  * Changed default `LlamaLogging` level from `debug` to `warn` to suppress excessive native LiteRT/llama.cpp debug log spam.

## 1.5.14

* **Upgraded `llamadart` Runtime (`^0.20.1`)**:
  * Bumped `llamadart` dependency to `^0.20.1` (`llamadart-native@v1.0.0-2` / upstream `llama.cpp v1.0.0`, `LiteRT-LM v0.19.1-5`, Windows CUDA `gpuMemoryFit` VRAM accounting, and model cache concurrency fix).
  * Supports automatic routing of both `.gguf` (`llama.cpp`) and `.litertlm` (`LiteRT-LM`) bundles via `LlamaBackend()`.
* **Synchronized Suite Upgrades**:
  * Aligned `flutter_ui_mcp_core` dependency to `^1.5.14` (multi-format `.gguf` and `.litertlm` HuggingFace discovery and local file picker support).

## 1.5.13

* **Upgraded llamadart Runtime (0.20.0 & llama.cpp v1.0.0)**:
  * Bumped `llamadart` dependency to `^0.20.0` adopting `llamadart-native@v1.0.0-1` (upstream llama.cpp `v1.0.0`), WebGPU bridge assets `v0.1.86`, and GPU memory fitting.
* **Synchronized Suite Upgrades**:
  * Aligned dependencies with `dart_mcp_core: ^1.5.13` and `flutter_ui_mcp_core: ^1.5.13`.

## 1.5.12

* **Synchronized Suite Upgrades**:
  * Aligned dependencies with `dart_mcp_core: ^1.5.12` and `flutter_ui_mcp_core: ^1.5.12`.

## 1.5.11

* **Synchronized Suite Upgrades**:
  * Aligned dependencies with `dart_mcp_core: ^1.5.11` and `flutter_ui_mcp_core: ^1.5.11`.

## 1.5.10

* **Synchronized Suite Upgrades**:
  * Aligned dependencies with `dart_mcp_core: ^1.5.10` and `flutter_ui_mcp_core: ^1.5.10`.

## 1.5.9

* **Synchronized Suite Upgrades**:
  * Aligned dependencies with `dart_mcp_core: ^1.5.9` and `flutter_ui_mcp_core: ^1.5.9`.

## 1.5.8

* **Synchronized Suite Upgrades**:
  * Aligned dependencies with `dart_mcp_core: ^1.5.8` and `flutter_ui_mcp_core: ^1.5.8`.

## 1.5.7

* **Synchronized Suite Upgrades**:
  * Aligned dependencies with `dart_mcp_core: ^1.5.7` and `flutter_ui_mcp_core: ^1.5.7`.

## 1.5.6

* **Synchronized Suite Upgrades**:
  * Aligned dependencies with `dart_mcp_core: ^1.5.6` and `flutter_ui_mcp_core: ^1.5.6`.

## 1.5.5

- **Dependency Upgrades**:
  - Upgraded `llamadart` to `^0.17.5`.
  - Synchronized dependencies with `dart_mcp_core: ^1.5.5` and `flutter_ui_mcp_core: ^1.5.5`.

## 1.5.0

- Synchronized dependencies with `dart_mcp_core: ^1.5.0` and `flutter_ui_mcp_core: ^1.5.0`.
- Inherited safe post-frame build phase notifications and multi-LLM configuration profile support.

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

# Flutter UI MCP Embedded Example

This example demonstrates how to use the `flutter_ui_mcp_embedded` companion package to register and execute local GGUF models on-device using `llamadart` (`llama.cpp` and WebGPU).

## Features Showcased

- Registering the embedded LLM driver with `FlutterUiMcpEmbedded.register()`.
- Checking hardware acceleration status (`isGpuSupported`, VRAM metrics).
- Initializing and loading GGUF models with progress monitoring.
- Executing streaming on-device inference via `EmbeddedLlmAdapter.instance.generateResponse()`.

## Getting Started

1. Navigate to this directory:
   ```bash
   cd example
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

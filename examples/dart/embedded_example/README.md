# Pure Dart Embedded Model Runner (`embedded_example`)

A standalone Dart console application that downloads an on-device GGUF model (`Qwen2.5-3B-Instruct`) from Hugging Face with real-time download progress, initializes `llamadart` locally, registers native Dart MCP tools, and runs an offline AI agent.

---

## ✨ Features

- **Automated GGUF Download**: Streams and caches quantized GGUF weights directly from Hugging Face to `~/.models` with console progress bars.
- **Pure Dart + C++ LLM Engine**: Runs local inference using [`llamadart`](https://pub.dev/packages/llamadart) bindings with zero cloud/network dependencies during generation.
- **Native Tool Execution**: Registers Open-Meteo local weather tools and executes agent loops via `mcp_playground_dart`.
- **Token-by-Token Streaming**: Streams output directly to stdout in real time.

---

## 🚀 How to Run

```bash
cd examples/dart/embedded_example
dart pub get
dart run main.dart
```

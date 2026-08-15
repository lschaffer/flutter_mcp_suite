# Embedded LLM Playground Showcase (`example_embedded`)

A complete Flutter application configured to run local, on-device GGUF language models with zero external network dependencies, powered by [`llamadart`](https://pub.dev/packages/llamadart) and [`mcp_playground_flutter`](https://pub.dev/packages/mcp_playground_flutter).

---

## ✨ Features

- **On-Device Offline LLM Execution**: Runs local GGUF models directly on device via `llamadart` (C++ llama.cpp bindings).
- **Hugging Face Model Discovery**: Search, browse, and download quantized GGUF models directly within the application with progress bars.
- **Native Dart Tool Execution**: Equipped with Open-Meteo weather tools and dynamic chart generation (`fl_chart` to PNG).
- **Real-Time Token Streaming**: Real-time token-by-token generation with live Agent Inspector tracing.

---

## 🚀 How to Run

```bash
cd examples/flutter/example_embedded
flutter pub get
flutter run -d windows # or macos / linux / android / ios
```

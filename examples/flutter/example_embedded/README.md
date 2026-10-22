# Embedded LLM Playground Showcase (`example_embedded`)

A complete Flutter application configured to run local, on-device language models with zero external network dependencies, powered by [`flutter_ui_mcp_embedded`](../../../flutter_ui_mcp_embedded) and [`llamadart`](https://pub.dev/packages/llamadart) (`.gguf`).

---

## ✨ Features

- **On-Device Offline LLM Execution**:
  - Runs local GGUF models directly in-process via `llamadart` (`llama.cpp` bindings) across desktop (Windows, macOS, Linux), mobile (Android, iOS), and web (WebGPU).
  - Resilient, crash-safe execution with graceful Dart error handling.
- **Hugging Face Model Discovery**: Search, browse, and download quantized GGUF models directly within the application with progress bars.
- **Custom TopBar Builder**:
  - Uses `topBarBuilder` to render a customized `AppBar` with an offline GGUF indicator and tailored action buttons.
- **Headless Chat View Mode (`McpChatView`)**:
  - Demonstrates single-tap switching between full playground mode and a standalone headless chat view.
- **Native Dart Tool Execution**: Equipped with Open-Meteo weather tools and dynamic chart generation (`fl_chart` to PNG).
- **Real-Time Token Streaming**: Real-time token-by-token generation with live Agent Inspector tracing.

---

## 💡 Example Prompts to Try

The embedded agent comes equipped with native local weather tools and dynamic chart generators:

### 1. 🌦️ Weather Tool Execution
```text
What is the current weather and next 24 hours forecast for Rome, Italy?
```
> **What to look for**:
> - The local GGUF model invokes `get_current_weather` and `get_hourly_forecast`.
> - The Agent Inspector traces the tool invocation arguments and return payloads in real time.

### 2. 📊 Dynamic Bar Chart Generation
```text
Create a bar chart comparing weekly revenue: Mon 150, Tue 230, Wed 180, Thu 310, Fri 420. Use create_chart_png.
```
> **What to look for**:
> - The model calls `create_chart_png` with JSON chart data.
> - The custom `messageContentBuilder` intercepts the tool response and renders an interactive `fl_chart` bar widget directly within the chat bubble.

### 3. 🥧 Portfolio Pie Chart
```text
Generate a pie chart breakdown for my savings: Stocks 45%, Real Estate 25%, Crypto 15%, Cash 15%. Use create_chart_png.
```

---

## 🚀 How to Run

```bash
cd examples/flutter/example_embedded
flutter pub get
flutter run -d windows # or macos / linux / android / ios
```

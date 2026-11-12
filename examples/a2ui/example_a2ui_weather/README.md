# GenUI Weather Generator Example (`example_genui_weather`)

An interactive Flutter application demonstrating Google GenUI (`A2UI`) in action with Open-Meteo weather forecasts, live `fl_chart` visualizations, JPG export, and cross-platform on-device embedded LLM inference powered by [`llamadart`](https://pub.dev/packages/llamadart) (`.gguf`).

## Features

- **Interactive Parameter Form (`WeatherForm`)**: Custom form widget allowing users to select city, duration (24h, 48h, 72h, 7 days), and channels (temperature, wind speed, wind direction, cloud cover, precipitation).
- **Multi-Line Forecast Chart (`WeatherChart`)**: Rendered using `fl_chart` with colored channel indicators and data table.
- **Export to JPG**: Direct graphics snapshot export via `RepaintBoundary` + pure Dart image encoding.
- **Open-Meteo MCP Tool**: No API key required for weather data.
- **On-Device Embedded LLM Inference**:
  - **`.gguf` models** (e.g. Qwen 2.5, Gemma 2, SmolLM, Llama 3) execute in-process via `llamadart` (`llama.cpp`) across all platforms (Android, iOS, Windows, macOS, Linux, Web).
  - Robust error handling and in-process execution without crashing on unexpected tensor schemas.

## Running

```bash
cd examples/genui/example_genui_weather
flutter pub get
flutter run -d "SM S938B" # or windows / macos / linux / chrome
```

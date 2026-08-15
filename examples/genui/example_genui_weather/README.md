# GenUI Weather Generator Example (`example_genui_weather`)

An interactive Flutter application demonstrating Google GenUI (`A2UI`) in action with Open-Meteo weather forecasts, live `fl_chart` visualizations, and JPG export.

## Features

- **Interactive Parameter Form (`WeatherForm`)**: Custom form widget allowing users to select city, duration (24h, 48h, 72h, 7 days), and channels (temperature, wind speed, wind direction, cloud cover, precipitation).
- **Multi-Line Forecast Chart (`WeatherChart`)**: Rendered using `fl_chart` with colored channel indicators and data table.
- **Export to JPG**: Direct graphics snapshot export via `RepaintBoundary` + pure Dart image encoding.
- **Open-Meteo MCP Tool**: No API key required for weather data.

## Running

```bash
cd examples/genui/example_genui_weather
flutter run -d windows # or macos / linux / chrome
```

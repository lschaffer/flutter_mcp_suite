# GenUI Smart Home Studio (Generative UI Example)

Demonstrates interactive generative UI widgets rendered by AI agents inside `GenuiMcpPlayground`.
The agent connects to smart home MCP tools, updates climate devices, and dynamically streams interactive controls:
- **ThermostatCard**: Temperature slider, +/- buttons, mode chips (Comfort, Eco, Sleep).
- **DeviceGrid**: Interactive toggle switches for lights, AC, and door locks.
- **EnergyChart**: Dynamic `fl_chart` bar chart showing room-by-room energy consumption.

## Features
- Dynamic A2UI / GenUI protocol widget generation
- Two-way interaction (user touches sliders/switches in the chat UI)
- Smart home state discovery and control tools
- FlChart data visualizations

## Running
```bash
cd examples/genui/example_genui_smarthome
flutter pub get
flutter run
```

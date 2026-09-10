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

## 💡 Example Prompts
Try asking the assistant:
- *"Check current smart home status and show an interactive thermostat card for the Living Room."*
- *"Show all connected lights and appliances with toggle switches so I can adjust them."*
- *"Analyze our energy usage today and render a room-by-room consumption bar chart."*

## Running
```bash
cd examples/genui/example_genui_smarthome
flutter pub get
flutter run -d windows # or -d chrome
```

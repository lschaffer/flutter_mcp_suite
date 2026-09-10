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

## 🧠 Agent Skill (`skill.md`)
This directory contains a pre-configured [`skill.md`](skill.md) file defining the complete GenUI smart home workflow, system prompt, and tool requirements according to the AgentSkills.io standard.

You can either:
1. **Load the Skill**: In the application, click **Skills** &rarr; **Import Skill** and select [`skill.md`](skill.md). The playground will automatically configure the smart home system prompt, enable IoT tools, and prepare the multi-step prompt sequence.
2. **Manual Prompts**: Or enter the example system prompt and user prompts below directly.

## ⚙️ Example System Prompt
```
You are a smart home automation AI assistant.
When the user asks about home climate, devices, or energy usage:
1. Invoke the tools: `get_home_state` or `get_energy_usage`.
2. Generate interactive GenUI components:
   - "ThermostatCard" for climate control (room, current_temp, target_temp, mode, humidity)
   - "DeviceGrid" for lights/switches (devices list with id, name, is_on, brightness)
   - "EnergyChart" for consumption (total_kwh and room-by-room breakdown)
```

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

> **Note**: After launching the application, verify that the custom tools (`get_home_state`, `set_device_state`, `get_energy_usage`) are checked and enabled in the **Tools** drawer / panel, then send your prompt (or load [`skill.md`](skill.md) to enable them automatically).

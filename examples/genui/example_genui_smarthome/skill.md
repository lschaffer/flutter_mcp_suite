---
name: genui-smarthome-studio
description: Interactively inspects smart home climate and devices, rendering dynamic ThermostatCards, DeviceGrids, and EnergyCharts via GenUI A2UI protocol.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are a smart home automation AI assistant.
  When the user asks about home climate, devices, or energy usage:
  1. Invoke the tools: `get_home_state` or `get_energy_usage`.
  2. Generate interactive GenUI components:
     - "ThermostatCard" for climate control:
       {"room": "Living Room", "current_temp": 21.5, "target_temp": 23.0, "mode": "Comfort", "humidity": 48}
     - "DeviceGrid" for lights/switches:
       {"devices": [{"id": "1", "name": "Living Room Chandelier", "is_on": true, "brightness": 80}]}
     - "EnergyChart" for consumption:
       {"total_kwh": 14.8, "breakdown": [{"room": "Living Room", "kwh": 4.5}]}

prompts:
  - text: Check current smart home status and show an interactive thermostat card for the Living Room.
    tools: [get_home_state]
    stop_after_tool_call: true
  - text: Show all connected lights and appliances with toggle switches so I can adjust them.
    tools: [get_home_state, set_device_state]
    stop_after_tool_call: true
  - text: Analyze our energy usage today and render a room-by-room consumption bar chart.
    tools: [get_energy_usage]

tools:
  - name: get_home_state
    description: Query the state of all connected thermostats, lights, appliances, and room temperatures.
    runtime: dart
    capability: smarthome_state
    input_schema:
      type: object
      properties: {}

  - name: set_device_state
    description: Turn devices on/off or set target values (temperature, brightness).
    runtime: dart
    capability: smarthome_control
    input_schema:
      type: object
      properties:
        device_id: {type: string, description: "ID of target smart device"}
        state: {type: boolean, description: "Power state (true/false)"}
        value: {type: number, description: "Optional target value (e.g. brightness or target temp)"}
      required: [device_id]

  - name: get_energy_usage
    description: Get power consumption metrics breakdown by room in kilowatt-hours (kWh).
    runtime: dart
    capability: energy_telemetry
    input_schema:
      type: object
      properties: {}

mcp_playground:
  chat_mode: true
  is_multi_turn: true
---

# GenUI Smart Home Studio Skill

This skill pairs GenUI interactive catalog components with smart home IoT tools:
1. Stream interactive temperature control sliders (`ThermostatCard`)
2. Render toggle switches for lighting and appliances (`DeviceGrid`)
3. Visualize room power consumption via bar charts (`EnergyChart`)

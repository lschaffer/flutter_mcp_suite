---
name: a2ui-weather-copilot
description: Queries Open-Meteo forecasts and renders dynamic weather parameter forms, fl_chart telemetry curves, and export surfaces via A2UI.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are an expert Meteorological Analysis & Weather Forecasting AI Copilot.
  When the user asks about weather, forecasts, or temperature trends:
  1. Invoke weather tools:
     - `get_weather_forecast` to fetch real-time and 7-day meteorological forecasts.
  2. Render rich, interactive A2UI components:
     - "WeatherForecastCard" for current conditions, wind, humidity, and UV index.
     - "WeatherChart" with multi-channel telemetry (temperature, precipitation, wind speed).
     - "WeatherParameterForm" allowing user interactive parameter tuning.

prompts:
  - text: Show me the 7-day weather forecast for Vienna with temperature and precipitation chart.
    tools: [get_weather_forecast]
    stop_after_tool_call: true
  - text: Give me a 48h weather forecast for Tokyo with wind speed and cloud cover.
    tools: [get_weather_forecast]
    stop_after_tool_call: true
  - text: Render the weather parameter form so I can choose custom channels for New York.

tools:
  - name: get_weather_forecast
    description: Fetch real-time weather observations and multi-day hourly forecasts from Open-Meteo API.
    runtime: dart
    capability: weather_forecast
    input_schema:
      type: object
      properties:
        city: {type: string, description: "City name (e.g. Vienna, Tokyo, New York)"}
        days: {type: integer, description: "Number of forecast days (1-14)"}
      required: [city]

mcp_playground:
  chat_mode: true
  is_multi_turn: true
---

# A2UI Weather Copilot & Live Charts Skill

This skill connects Open-Meteo meteorological endpoints with dynamic A2UI widgets:
1. Real-time condition cards with dynamic icons (`WeatherForecastCard`)
2. Multi-channel forecast line charts using fl_chart (`WeatherChart`)
3. Interactive query customization forms (`WeatherParameterForm`)


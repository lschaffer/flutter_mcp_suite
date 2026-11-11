# A2UI Patterns & Surface Emission Reference

This document illustrates how LLMs emit structured JSON surfaces for `flutter_a2ui_mcp`.

## 1. Surface Protocol Structure

An A2UI surface message emitted by an LLM is a JSON object containing `surfaceId`, `catalogId`, and a list of component instances:

```json
{
  "surfaceId": "weather_surface_01",
  "catalog": "a2ui_default",
  "components": [
    {
      "type": "TravelHeroCard",
      "props": {
        "destination": "Kyoto",
        "country": "Japan",
        "headline": "Autumn foliage & historic shrines",
        "bestTimeToVisit": "October – November"
      }
    },
    {
      "type": "HotelCard",
      "props": {
        "name": "Kyoto Heritage Ryokan",
        "pricePerNight": "¥28,000 / night",
        "rating": 4.9,
        "amenities": ["Traditional Onsen", "Garden View", "Kaiseki Dinner"]
      }
    }
  ]
}
```

## 2. Dynamic Streaming & Parser

`McpA2uiChatController` recognizes either:
- Inline tags: `<a2ui-json>{ ... }</a2ui-json>`
- Markdown code fences:
  ````markdown
  ```json
  {
    "surfaceId": "...",
    ...
  }
  ```
  ````

The text outside the JSON fence is rendered as standard assistant markdown chat, while the surface is rendered as native Flutter widgets immediately upon completion.


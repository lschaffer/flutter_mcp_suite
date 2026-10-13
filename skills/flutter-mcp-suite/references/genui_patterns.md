# Generative UI (GenUI / A2UI) Patterns & Schemas

When using `flutter_genui_mcp`, agents emit structured JSON objects that are dynamically parsed and rendered into native Flutter widgets.

---

## Standard GenUI Component Contract

Every GenUI component has a `type` identifier and a typed `props` payload:

```json
{
  "type": "component_type",
  "id": "unique_component_id",
  "props": { ... }
}
```

---

## Supported Component Types

### 1. KPI Metric Card (`kpi_metric`)
Displays a key numerical metric with trend indicator:

```json
{
  "type": "kpi_metric",
  "id": "metric_mrr",
  "props": {
    "title": "Monthly Recurring Revenue",
    "value": "$42,500",
    "changePercent": 12.4,
    "isPositive": true,
    "icon": "trending_up"
  }
}
```

### 2. Chart Card (`chart_card`)
Renders interactive line, bar, or pie charts:

```json
{
  "type": "chart_card",
  "id": "revenue_trend",
  "props": {
    "title": "Revenue Growth (2026)",
    "chartType": "line",
    "labels": ["Jan", "Feb", "Mar", "Apr", "May", "Jun"],
    "datasets": [
      {
        "label": "Gross Revenue",
        "values": [12000, 15000, 18000, 24000, 31000, 42500]
      }
    ]
  }
}
```

### 3. Date Range Selector (`date_range_picker`)
Provides interactive calendar selection:

```json
{
  "type": "date_range_picker",
  "id": "travel_dates",
  "props": {
    "label": "Select Travel Dates",
    "initialStart": "2026-06-01",
    "initialEnd": "2026-06-15"
  }
}
```

### 4. Interactive Chip Filter (`chip_selector`)
Single-select or multi-select option chips:

```json
{
  "type": "chip_selector",
  "id": "stay_style",
  "props": {
    "label": "Accommodation Style",
    "multiSelect": true,
    "options": ["Boutique Hotel", "Private Apartment", "Eco Resort", "Glamping"],
    "selected": ["Boutique Hotel"]
  }
}
```

### 5. Action Items Checklist (`checklist`)
Interactive task tracker with checkable items:

```json
{
  "type": "checklist",
  "id": "meeting_actions",
  "props": {
    "title": "Follow-Up Action Items",
    "items": [
      {"id": "task_1", "text": "Deploy MCP server update to staging", "done": false, "owner": "Alex"},
      {"id": "task_2", "text": "Draft Agensi skill package", "done": true, "owner": "Laszlo"}
    ]
  }
}
```

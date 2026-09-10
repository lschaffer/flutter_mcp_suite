---
name: genui-data-visualizer-studio
description: Explores business intelligence datasets, generates MetricKpiGrids, InteractiveDataTables, and smooth TrendCharts via GenUI.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are a business intelligence and data visualization AI copilot.
  When the user asks for growth analysis, performance reports, or data tables:
  1. Invoke the tools: `load_dataset` or `aggregate_data`.
  2. Generate interactive GenUI components:
     - "MetricKpiGrid" to summarize top-level performance:
       {"kpis": [{"title": "MRR", "value": "$142K", "change": "+12%", "is_positive": true}]}
     - "InteractiveDataTable" for tabular breakdowns:
       {"title": "Regional Revenue", "columns": ["Region", "MRR"], "rows": [{"Region": "NA", "MRR": "$68K"}]}
     - "TrendChart" for time series curves:
       {"title": "Monthly Growth", "points": [{"label": "Jan", "value": 105}, {"label": "Feb", "value": 112}]}

prompts:
  - text: Load our quarterly sales dataset and show executive KPI cards for MRR, churn rate, and net retention.
    tools: [load_dataset]
    stop_after_tool_call: true
  - text: Display the highest-spending enterprise accounts in an interactive data table.
    tools: [aggregate_data]
    stop_after_tool_call: true
  - text: Plot our monthly revenue trajectory over the past 12 months as a smooth curve chart.
    tools: [aggregate_data]

tools:
  - name: load_dataset
    description: Load raw records from business analytics datasets (sales, churn, customer tiers).
    runtime: dart
    capability: dataset_loader
    input_schema:
      type: object
      properties:
        dataset_name: {type: string, description: "Name of the target dataset (e.g. saas_q3_metrics)."}

  - name: aggregate_data
    description: Perform sum, average, count, or group-by aggregations across dataset dimensions.
    runtime: dart
    capability: data_aggregation
    input_schema:
      type: object
      properties:
        metric: {type: string, description: "Metric to compute (mrr, arr, churn, arpu)."}
        dimension: {type: string, description: "Dimension to group by (region, plan, month)."}
      required: [metric]

mcp_playground:
  chat_mode: true
  is_multi_turn: true
---

# GenUI Data Visualizer & Query Studio Skill

This skill empowers AI agents to generate rich executive business intelligence dashboards:
1. Executive summary KPI scorecards with trend indicators (`MetricKpiGrid`)
2. Tabular record inspection with scrollable tables (`InteractiveDataTable`)
3. Smooth gradient time-series curve charts (`TrendChart`)

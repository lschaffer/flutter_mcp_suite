# GenUI Data Visualizer & Query Studio (Generative UI Example)

Demonstrates how AI agents render interactive business intelligence dashboards and query widgets inside `GenuiMcpPlayground`.
Users can explore datasets, query aggregations, and dynamically stream interactive GenUI widgets:
- **MetricKpiGrid**: KPI cards with values and green/red trend percentage change badges.
- **InteractiveDataTable**: Clean scrollable tabular data with styled headers and cells.
- **TrendChart**: Dynamic `fl_chart` time-series line chart with smooth curves and gradient fills.

## Features
- Dynamic A2UI / GenUI catalog integration
- Interactive table and chart generation
- FlChart line chart trends
- Analytics and dataset discovery tools

## 🧠 Agent Skill (`skill.md`)
This directory contains a pre-configured [`skill.md`](skill.md) file defining the complete GenUI analytics and dashboard workflow, system prompt, and tool requirements according to the AgentSkills.io standard.

You can either:
1. **Load the Skill**: In the application, click **Skills** &rarr; **Import Skill** and select [`skill.md`](skill.md). The playground will automatically configure the business intelligence system prompt, enable dataset discovery tools, and prepare the multi-step prompt sequence.
2. **Manual Prompts**: Or enter the example system prompt and user prompts below directly.

## ⚙️ Example System Prompt
```
You are a business intelligence and data visualization AI copilot.
When the user asks for growth analysis, performance reports, or data tables:
1. Invoke the tools: `load_dataset` or `aggregate_data`.
2. Generate interactive GenUI components:
   - "MetricKpiGrid" to summarize top-level performance (KPIs with title, value, change, is_positive)
   - "InteractiveDataTable" for tabular breakdowns (title, columns, rows)
   - "TrendChart" for time series curves (title, points with label and value)
```

## 💡 Example Prompts
Try asking the assistant:
- *"Load our quarterly sales dataset and show executive KPI cards for MRR, churn rate, and net retention."*
- *"Display the highest-spending enterprise accounts in an interactive data table."*
- *"Plot our monthly revenue trajectory over the past 12 months as a smooth curve chart."*

## Running
```bash
cd examples/genui/example_genui_data_studio
flutter pub get
flutter run -d windows # or -d chrome
```

> **Note**: After launching the application, verify that the custom tools (`load_dataset`, `aggregate_data`) are checked and enabled in the **Tools** drawer / panel, then send your prompt (or load [`skill.md`](skill.md) to enable them automatically).

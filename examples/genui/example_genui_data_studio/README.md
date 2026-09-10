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

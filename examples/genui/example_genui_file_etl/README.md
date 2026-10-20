# GenUI File ETL & Data Transformation Studio

Demonstrates how AI agents parse raw uploaded datasets, clean schemas, and stream interactive data transformation widgets using `flutter_genui_mcp`, `flutter_ui_mcp_core`, and resilient file attachment decoding (`allowMalformed: true`).

Users can attach CSV or JSON records and interactively inspect, filter, and export datasets:
- **`DatasetSummaryCard`**: Displays row/column dimensions, delimiter, encoding, and attachment token footprint in prompt context.
- **`SchemaTransformerWidget`**: Interactive attribute list showing column names, detected data types (Strings, Dates, Enums, Numerics), and sample values.
- **`DataPreviewTable`**: Interactive scrollable data table with clean header styling and record count indicators.
- **`ExportPipelineCard`**: Interactive export card with 1-click **"Copy Artifact"** button for CSV, SQL schema, or Dart data models.

## Features
- **Resilient File Attachment Handling**: Leverages UTF-8 decoding with malformed byte recovery and token accounting.
- **Interactive Data Wrangling**: Dynamic filtering and column transformations directly from natural language prompts.
- **Agent Inspector Integration**: Inspect real-time tokens, costs, and execution traces with the top action bar toggle.

## 🧠 Agent Skill (`skill.md`)
This directory contains a pre-configured [`skill.md`](skill.md) file adhering to the AgentSkills.io standard.

You can either:
1. **Load the Skill**: In the application, click **Skills** &rarr; **Import Skill** and select [`skill.md`](skill.md). The playground will automatically configure the ETL copilot system prompt, enable data tools, and prepare sample prompt queries.
2. **Manual Prompts**: Or enter the prompts below directly.

## 💡 Example Prompts
Try asking the assistant:
- *"Inspect our attached customer orders CSV file and display the dataset summary card and detected schema."*
- *"Filter the customer orders for high-value paid enterprise deals (order_value >= 4000) and show an interactive data preview table."*
- *"Export the transformed high-value dataset as a production-ready SQL table creation and insert schema."*

## Running
```bash
cd examples/genui/example_genui_file_etl
flutter pub get
flutter run -d windows # or -d chrome
```

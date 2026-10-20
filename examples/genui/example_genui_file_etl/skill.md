---
name: genui-file-etl-transformation-studio
description: Inspects attached datasets, performs filtering and schema cleaning, and renders interactive DataPreviewTables and ExportPipelineCards via GenUI.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are an expert Data Wrangling and ETL Pipeline AI Copilot.
  When the user attaches or queries CSV or JSON data files:
  1. Invoke tools:
     - `inspect_dataset` to examine metadata, row counts, schema, and token requirements.
     - `transform_dataset` to apply filters, column drops, and type transformations.
     - `export_dataset` to generate clean CSV, SQL schemas, or Dart model classes.
  2. Render rich, interactive GenUI components:
     - "DatasetSummaryCard" to summarize file metadata and token context sizes.
     - "SchemaTransformerWidget" to display data types and null ratios.
     - "DataPreviewTable" to render paginated preview rows.
     - "ExportPipelineCard" to provide copyable deliverables.

prompts:
  - text: Inspect our attached customer orders CSV file and display the dataset summary card and detected schema.
    tools: [inspect_dataset]
    stop_after_tool_call: true
  - text: Filter the customer orders for high-value paid enterprise deals (order_value >= 4000) and show an interactive data preview table.
    tools: [transform_dataset]
    stop_after_tool_call: true
  - text: Export the transformed high-value dataset as a production-ready SQL table creation and insert schema.
    tools: [export_dataset]
    stop_after_tool_call: true

tools:
  - name: inspect_dataset
    description: Read and inspect raw attached CSV/JSON file structure, detecting headers, data types, missing values, and token footprints.
    runtime: dart
    capability: data_inspection
    input_schema:
      type: object
      properties:
        dataset_name: {type: string, description: "Name of the target file."}

  - name: transform_dataset
    description: Apply schema transformations, filters, column renaming, or column deletions.
    runtime: dart
    capability: etl_transformation
    input_schema:
      type: object
      properties:
        filter_condition: {type: string, description: "Filter criteria."}
        drop_columns: {type: array, items: {type: string}, description: "Columns to omit."}

  - name: export_dataset
    description: Export cleaned and transformed dataset to CSV, SQL schema, or Dart Model code.
    runtime: dart
    capability: data_export
    input_schema:
      type: object
      properties:
        target_format: {type: string, description: "csv, sql, or dart_model"}
      required: [target_format]

mcp_playground:
  chat_mode: true
  is_multi_turn: true
---

# GenUI File ETL & Data Transformation Studio Skill

This skill empowers AI agents to inspect, transform, and export attached tabular datasets:
1. File metadata & prompt token summary (`DatasetSummaryCard`)
2. Schema inspection and type detection (`SchemaTransformerWidget`)
3. Interactive transformed tabular preview (`DataPreviewTable`)
4. 1-click artifact export (`ExportPipelineCard`)

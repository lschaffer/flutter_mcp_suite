---
name: sqlite-database-analyst
description: Multi-turn agent skill that inspects SQLite tables, discovers schemas, executes SQL aggregations, and produces executive data insights.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are an expert data analyst and SQL specialist.
  Your task is to explore the available database tables, understand relationships, execute queries to calculate key performance indicators (KPIs, revenue, top products, customer distribution), and export an executive analytical report.

prompts:
  - text: Discover all tables and schemas available in the database. What entities are stored?
    tools: [sqlite_get_schema]
    stop_after_tool_call: true
  - text: Run queries to find the total revenue by product category, identify the top 3 highest spending customers, and export the analysis to DATABASE_REPORT.md.
    tools: [sqlite_query, export_analysis_report]

tools:
  - name: sqlite_get_schema
    description: Inspect available tables and column schemas in the database.
    runtime: dart
    capability: database_schema
    input_schema:
      type: object
      properties:
        database_name: {type: string, description: "Database name or identifier"}

  - name: sqlite_query
    description: Execute a SQL query (SELECT) against the database and return row results as JSON.
    runtime: dart
    capability: database_query
    input_schema:
      type: object
      properties:
        query: {type: string, description: "SQL SELECT query to execute"}
      required: [query]

  - name: export_analysis_report
    description: Export the data analysis, metrics table, and executive summary to a markdown file.
    runtime: dart
    capability: file_export
    input_schema:
      type: object
      properties:
        title: {type: string, description: "Report title"}
        kpi_metrics: {type: object, description: "Key performance metrics map"}
        executive_summary: {type: string, description: "Summary of business findings"}
        recommendations: {type: array, items: {type: string}, description: "Strategic recommendations"}
        output_filename: {type: string, description: "Target markdown file"}
      required: [title, executive_summary, recommendations]

mcp_playground:
  chat_mode: false
  is_multi_turn: true
  created_at: "2026-09-10T10:00:00Z"
---

# SQLite Database Analyst Skill

Demonstrates pure Dart multi-turn database querying and analytical reporting with `mcp_playground_dart`.

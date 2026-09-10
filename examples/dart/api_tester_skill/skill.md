---
name: api-endpoint-prober
description: Multi-turn agent skill that executes HTTP requests against APIs, validates response JSON schemas, measures roundtrip latency, and exports a diagnostic test report.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are an expert site reliability engineer and API diagnostic tester.
  Your task is to probe target API endpoints, inspect status codes, benchmark latency, validate payload schemas, and generate a clear diagnostic health report.

prompts:
  - text: Probe the public JSONPlaceholder API at https://jsonplaceholder.typicode.com/todos/1 and https://jsonplaceholder.typicode.com/posts. Check status code and measure latency.
    tools: [http_probe]
    stop_after_tool_call: true
  - text: Validate that the /todos/1 payload contains userId, id, title, completed fields, and export the test findings to API_DIAGNOSTICS.md.
    tools: [validate_schema, export_diagnostic_report]

tools:
  - name: http_probe
    description: Send HTTP GET or POST request to an API endpoint and record status, headers, latency, and response body.
    runtime: dart
    capability: http_client
    input_schema:
      type: object
      properties:
        url: {type: string, description: "Full URL of endpoint"}
        method: {type: string, description: "HTTP method: GET, POST, PUT, DELETE"}
        headers: {type: object, description: "Optional request headers"}
        body: {type: string, description: "Optional request body string"}
      required: [url]

  - name: validate_schema
    description: Validate whether a JSON object or string contains expected property keys.
    runtime: dart
    capability: schema_validator
    input_schema:
      type: object
      properties:
        json_string: {type: string, description: "JSON string to validate"}
        required_keys: {type: array, items: {type: string}, description: "List of required key names"}
      required: [json_string, required_keys]

  - name: export_diagnostic_report
    description: Write the API diagnostic findings and latency benchmarks into a markdown report.
    runtime: dart
    capability: file_export
    input_schema:
      type: object
      properties:
        title: {type: string, description: "Report title"}
        tested_endpoints: {type: array, items: {type: string}, description: "List of endpoints tested"}
        results_summary: {type: string, description: "Overall health and status summary"}
        output_filename: {type: string, description: "Destination file name"}
      required: [title, tested_endpoints, results_summary]

mcp_playground:
  chat_mode: false
  is_multi_turn: true
  created_at: "2026-09-10T10:00:00Z"
---

# API Endpoint Prober Skill

Demonstrates pure Dart agent orchestration for API regression testing and endpoint monitoring.

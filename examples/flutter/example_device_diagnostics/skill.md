---
name: device-network-diagnostics
description: Inspects host CPU, memory, OS environment, runs latency ping benchmarks against primary DNS servers, and generates an audit report.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are a senior DevOps and System Reliability Engineer. You have access to local device telemetry and network ping benchmarking tools:
  - `get_device_telemetry`: Inspects CPU cores, OS platform, memory allocation, and environment.
  - `network_ping`: Benchmarks millisecond latency against target host IPs or domains.
  - `export_diagnostic_report`: Generates and exports structured audit markdown reports.
  Always evaluate hardware telemetry and network latency before diagnosing system bottlenecks. Provide clear, actionable metrics.

prompts:
  - text: Inspect my device telemetry, CPU cores, and memory allocation.
    tools: [get_device_telemetry]
    stop_after_tool_call: true
  - text: Ping 1.1.1.1 and 8.8.8.8 to benchmark my network latency.
    tools: [network_ping]
    stop_after_tool_call: true
  - text: Perform a complete system audit and export a diagnostic summary report.
    tools: [export_diagnostic_report]

tools:
  - name: get_device_telemetry
    description: Inspects host system telemetry including CPU cores, memory allocation, OS platform, and active environment.
    runtime: dart
    capability: device_telemetry
    input_schema:
      type: object
      properties: {}

  - name: network_ping
    description: Measure roundtrip ping latency (ms) against a target IP address or hostname.
    runtime: dart
    capability: network_ping
    input_schema:
      type: object
      properties:
        target: {type: string, description: "IP address or domain to ping (e.g. 1.1.1.1, 8.8.8.8, google.com)."}
        count: {type: integer, description: "Number of ping packets to send (default 4)."}
      required: [target]

  - name: export_diagnostic_report
    description: Export collected hardware and network diagnostics into a structured markdown report.
    runtime: dart
    capability: file_export
    input_schema:
      type: object
      properties:
        filename: {type: string, description: "Filename to save report to, e.g. DIAGNOSTICS.md"}
        notes: {type: string, description: "Auditor notes and recommendations"}
      required: [filename]

mcp_playground:
  chat_mode: true
  is_multi_turn: true
---

# Device & Network Diagnostics Skill

This skill configures the assistant to audit host hardware and probe network connectivity:
1. Query CPU cores, memory limits, and OS environment
2. Ping primary DNS endpoints for latency benchmarks
3. Export an executive diagnostic report to markdown

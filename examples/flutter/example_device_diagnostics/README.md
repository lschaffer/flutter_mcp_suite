# Device & Network Diagnostics Copilot (Flutter MCP Example)

Demonstrates embedding `McpPlayground` with native device telemetry and network probing tools.
The agent inspects host CPU cores, platform OS, locale, pings endpoints (Google DNS, Cloudflare), and renders custom visual status cards inside the chat.

## Features
- Embedded `McpPlayground` with custom tool registration
- Hardware and runtime telemetry inspection (`get_device_telemetry`)
- Live network roundtrip latency pinging (`network_ping`)
- Custom Flutter UI builder (`messageContentBuilder`) rendering telemetry cards

## 🧠 Agent Skill (`skill.md`)
This directory contains a pre-configured [`skill.md`](skill.md) file defining the complete workflow, system prompt, and tool requirements according to the AgentSkills.io standard.

You can either:
1. **Load the Skill**: In the application, click **Skills** &rarr; **Import Skill** and select [`skill.md`](skill.md). The playground will automatically configure the system prompt, enable the diagnostic tools, and prepare the multi-step prompt sequence.
2. **Manual Prompts**: Or enter the example system prompt and user prompts below directly.

## ⚙️ Example System Prompt
```
You are a senior DevOps and System Reliability Engineer. You have access to local device telemetry and network ping benchmarking tools:
- `get_device_telemetry`: Inspects CPU cores, OS platform, memory allocation, and environment.
- `network_ping`: Benchmarks millisecond latency against target host IPs or domains.
- `export_diagnostic_report`: Generates and exports structured audit markdown reports.
Always evaluate hardware telemetry and network latency before diagnosing system bottlenecks. Provide clear, actionable metrics.
```

## 💡 Example Prompts
Try asking the assistant:
- *"Inspect my device telemetry, CPU cores, and memory allocation."*
- *"Ping 1.1.1.1 and 8.8.8.8 to benchmark my network latency."*
- *"Perform a complete system audit and export a diagnostic summary report."*

## Running
```bash
cd examples/flutter/example_device_diagnostics
flutter pub get
flutter run -d windows # or -d chrome
```

> **Note**: After launching the application, verify that the custom tools (`get_device_telemetry`, `network_ping`, `export_diagnostic_report`) are checked and enabled in the **Tools** drawer / panel, then send your prompt (or load [`skill.md`](skill.md) to enable them automatically).

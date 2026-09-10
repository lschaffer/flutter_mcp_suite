# Device & Network Diagnostics Copilot (Flutter MCP Example)

Demonstrates embedding `McpPlayground` with native device telemetry and network probing tools.
The agent inspects host CPU cores, platform OS, locale, pings endpoints (Google DNS, Cloudflare), and renders custom visual status cards inside the chat.

## Features
- Embedded `McpPlayground` with custom tool registration
- Hardware and runtime telemetry inspection (`get_device_telemetry`)
- Live network roundtrip latency pinging (`network_ping`)
- Custom Flutter UI builder (`messageContentBuilder`) rendering telemetry cards

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

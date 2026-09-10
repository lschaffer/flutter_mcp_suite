# API Endpoint Tester Skill (Pure Dart)

Demonstrates how to use `mcp_playground_dart` to execute an automated API prober skill.
The agent connects to live HTTP endpoints, measures latency, inspects headers, validates JSON schemas, and writes a diagnostic summary to `API_DIAGNOSTICS.md`.

## Features
- Pure Dart execution with zero GUI overhead
- Multi-step orchestration defined in `skill.md`
- HTTP request prober with precise latency measurements
- Schema key validator
- Markdown test artifact generator

## Running
```bash
cd examples/dart/api_tester_skill
dart pub get
dart run main.dart
```

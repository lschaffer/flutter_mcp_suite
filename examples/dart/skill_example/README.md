# Skill Importer Example (`skill_example`)

A headless Dart console example demonstrating how to import and execute an [agentskills.io](https://agentskills.io)-compatible [`skill.md`](skill.md) file using `mcp_playground_dart`.

---

## ✨ Features

- **Standard `skill.md` Execution**: Imports agent manifests with YAML frontmatter, declarations, tool mappings, and multi-turn prompt pipelines.
- **Automated Workflow Pipeline**: Orchestrates a multi-turn agent workflow that executes web search tools, synthesizes data, and generates interactive HTML charts.
- **Headless `McpAgentEngine`**: Registers agents from manifests and executes turns programmatically.

---

## 🚀 How to Run

Ensure your `.env` is configured with an LLM provider:

```bash
cd examples/dart/skill_example
dart pub get
dart run main.dart
```

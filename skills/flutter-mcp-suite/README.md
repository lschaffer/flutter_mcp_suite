# Flutter MCP Suite Skill

Turn your AI agent (Claude Code, Cursor, Copilot, OpenClaw, Codex CLI) into an expert Flutter & Dart engineer with native Model Context Protocol (MCP) orchestration and dynamic Generative UI (GenUI / A2UI) capabilities.

---

## ⚡ What This Skill Does

- **Expert Flutter & Dart Guidance**: Enforces clean widget tree construction, `const` optimizations, sound null-safety, and lightweight vanilla state management (`ChangeNotifier` / `ValueNotifier`).
- **Dynamic Generative UI (GenUI / A2UI)**: Directs the agent to emit structured UI components (KPI cards, charts, interactive filters, date pickers) that render natively in Flutter apps using `flutter_genui_mcp`.
- **MCP Server Orchestration**: Connects your AI agent to local or remote Dart MCP servers to run static analysis (`dart analyze`), inspect git status/diffs, benchmark REST APIs, or execute SQLite queries.
- **Automated Code Auditing**: Guides agents through multi-step review workflows, detecting breaking changes and compiling structured PR summaries.

---

## 🚀 Compatibility

- **Claude Code**
- **Cursor**
- **GitHub Copilot**
- **Codex CLI**
- **Windsurf**
- **OpenClaw**
- **Any Agent supporting the open SKILL.md specification**

---

## 📦 How to Use

1. Place `SKILL.md` into your agent's skills directory (e.g., `~/.claude/skills/flutter-mcp-suite/` or your workspace root).
2. Configure your agent's MCP settings using the included `references/mcp_config.json`.
3. Ask your agent to build Flutter screens, generate GenUI schemas, or run code reviews.

---
name: flutter-mcp-suite
description: Comprehensive Flutter and Dart development skill for AI agents. Provides step-by-step guidance, MCP tool orchestration, GenUI (A2UI) component generation, code analysis, and high-performance widget patterns for Claude Code, Cursor, Copilot, and Codex CLI.
version: 1.0.0
author: lschaffer
tags:
  - flutter
  - dart
  - mcp
  - mobile-development
  - frontend-web-apps
  - agents-orchestration
---

# Flutter MCP Suite Skill

This skill equips AI agents (Claude Code, Cursor, Copilot, OpenClaw, Codex CLI) with domain expertise for Flutter and Dart development, Model Context Protocol (MCP) tool integration, and Generative UI (GenUI / A2UI) workflows.

---

## 🎯 When to Activate This Skill

Activate this skill whenever the user asks to:
1. **Build or Architect Flutter Apps**: Create new widgets, screens, responsive layouts, or state management logic.
2. **Use Flutter MCP Suite Tools**: Connect or orchestrate tools from `dart_mcp_core`, `flutter_ui_mcp`, or `flutter_genui_mcp`.
3. **Generate Dynamic GenUI (A2UI)**: Emit structured UI component schemas for real-time rendering in Flutter.
4. **Audit and Analyze Dart Code**: Run static analysis (`dart analyze` / `flutter analyze`), inspect git diffs, or enforce Flutter best practices.
5. **Configure MCP in Developer Environments**: Set up `.cursor/mcp.json`, Claude Desktop config, or stdio/SSE server connections for Flutter.

---

## 🏗️ Core Engineering Guidelines for Flutter

When generating or editing Flutter and Dart code, adhere to these fundamental principles:

### 1. State Management
- **Default to Vanilla Flutter**: Use `ChangeNotifier`, `ValueNotifier`, and `StatefulWidget` for lightweight, modular state management.
- Avoid introducing heavy third-party state frameworks (Riverpod, Bloc, MobX) unless explicitly requested by the user.

### 2. Dependency Policy
- Keep dependencies minimal. Prefer standard Dart/Flutter SDK capabilities over third-party packages whenever possible.
- When adding dependencies, verify compatibility with the latest Dart 3.x sound null-safety standards.

### 3. Cross-Platform & Sandbox Safety
- Restrict `dart:io` and subprocess operations to desktop platforms (Windows, macOS, Linux).
- For Web and Mobile targets, use platform abstraction or graceful fallbacks to avoid runtime crashes.
- Account for Web CORS limitations when calling external APIs or MCP servers.

### 4. Code Quality & Formatting
- Always structure widgets cleanly: separate UI presentation from business logic controllers.
- Use `const` constructors wherever possible to optimize Flutter widget rebuild trees.
- Run `dart analyze` or `flutter analyze` after creating or modifying Dart code.

---

## 🔌 MCP Server Configuration for Agents

To connect the agent to a local or remote Dart MCP server, reference the configuration template in [references/mcp_config.json](references/mcp_config.json):

### Claude Desktop (`claude_desktop_config.json`)
```json
{
  "mcpServers": {
    "flutter-mcp-suite": {
      "command": "dart",
      "args": ["run", "dart_mcp_core:mcp_server"]
    }
  }
}
```

### Cursor (`.cursor/mcp.json`)
```json
{
  "mcpServers": {
    "flutter-mcp-suite": {
      "command": "dart",
      "args": ["run", "dart_mcp_core:mcp_server"]
    }
  }
}
```

---

## 🎨 Generative UI (GenUI / A2UI) Patterns

When asked to output dynamic UI components for `flutter_genui_mcp`:
1. Emit JSON schema objects matching the GenUI component specification (see [references/genui_patterns.md](references/genui_patterns.md)).
2. Supported components include:
   - **Data Visualizations**: `chart_card`, `kpi_metric`, `data_table`
   - **Form Controls**: `date_range_picker`, `slider_control`, `chip_selector`, `toggle_switch`
   - **Content Displays**: `photo_gallery_card`, `itinerary_step`, `summary_card`
3. Always validate that data fields (labels, values, units) are properly typed and populated.

---

## 📋 Standard Multi-Step Workflows

### Workflow A: New Flutter Widget / Screen
1. Clarify requirements, layout, and interaction states.
2. Define a clean data model class with `copyWith`, `toJson`, and `fromJson`.
3. Create a `ChangeNotifier` or `ValueNotifier` controller handling business logic.
4. Implement the Flutter `StatelessWidget` / `StatefulWidget` using responsive layout widgets (`LayoutBuilder`, `Wrap`, `Flex`).
5. Run `flutter analyze` to ensure zero lints or warnings.

### Workflow B: Automated PR / Diff Inspection
1. Inspect git status and staged changes.
2. Run static analysis across modified files (`dart analyze`).
3. Check for breaking API changes and null-safety issues.
4. Generate a structured review with:
   - Summary of modifications
   - Breaking change assessment
   - Verification and testing checklist

---

## 📚 References & Resources

- [Architecture Guidelines](references/flutter_guidelines.md)
- [MCP Configuration Templates](references/mcp_config.json)
- [GenUI / A2UI Component Schema](references/genui_patterns.md)

---
name: flutter-a2ui-mcp
description: Comprehensive guide for AI coding agents to integrate, architect, and use flutter_a2ui_mcp (Google A2UI standard with MCP tools and material_ui).
version: 1.0.0
author: lschaffer
tags:
  - flutter
  - dart
  - a2ui
  - genui
  - mcp
  - agentic-ui
  - dynamic-surfaces
---

# Flutter A2UI MCP Skill

This skill equips AI coding agents (Claude Code, Cursor, Copilot, Antigravity, Gemini CLI, OpenClaw) with expert knowledge on integrating and utilizing **`flutter_a2ui_mcp`** — the modern Agent-to-User Interface (A2UI) standard combined with Model Context Protocol (MCP) tool execution in Flutter.

---

## 🎯 When to Activate This Skill

Activate this skill whenever the user or task involves:
1. **Building Generative / Agentic UI in Flutter**: Dynamically rendering interactive forms, cards, charts, or dashboards generated on-the-fly by LLMs.
2. **Using `flutter_a2ui_mcp`**: Configuring `A2uiMcpPlayground`, `McpA2uiChatController`, or `A2uiChatView`.
3. **Migrating from `flutter_genui_mcp`**: Modernizing code from the discontinued `genui` package to Google's official `a2ui_flutter: ^0.3.0` and `a2ui_core: ^0.7.0` stack.
4. **Creating Custom A2UI Catalogs**: Defining JSON schemas with `A2uiCatalogItemDefinition` and registering component builders with `A2uiCatalogRegistry`.
5. **Connecting MCP Tools to Dynamic UI**: Creating `McpLocalTool` implementations that return data for dynamic A2UI surface synthesis.

---

## 📦 Package Dependencies & Core Stack

```yaml
dependencies:
  flutter_a2ui_mcp: ^1.0.0
  a2ui_flutter: ^0.3.0
  a2ui_core: ^0.7.0
  a2ui_agent: ^0.3.0
  dart_mcp_core: ^1.5.10
  flutter_ui_mcp_core: ^1.5.10
```

> [!IMPORTANT]
> **Strict Material UI Policy**: `flutter_a2ui_mcp` re-exports `package:material_ui/material_ui.dart` via `flutter_ui_mcp_core`.
> **Never** import `package:flutter/material.dart` together with `package:flutter_a2ui_mcp/flutter_a2ui_mcp.dart` in the same file to prevent ambiguous import clashes (e.g. `MaterialApp`, `ThemeData`, `Card`, `Icons`).
> Simply import `package:flutter_a2ui_mcp/flutter_a2ui_mcp.dart` which already provides all Material UI elements.

---

## 🚀 Quick Setup & Architecture

### 1. Minimal Integration (`A2uiMcpPlayground`)

```dart
import 'package:flutter_a2ui_mcp/flutter_a2ui_mcp.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: A2uiMcpPlayground(
          initialLlmConfig: LlmConfig(
            provider: LlmProvider.gemini,
            model: 'gemini-2.5-flash',
            apiKey: 'YOUR_GEMINI_API_KEY',
          ),
        ),
      ),
    );
  }
}
```

---

## 🧩 Defining Custom A2UI Catalog Components

A2UI surface rendering relies on catalog definitions:
1. **Register the Builder** in `A2uiCatalogRegistry`:
   The builder receives `(context, node, props, buildChild)`:
   - `props.string('key')` -> extracts string property
   - `props.value('key')` -> extracts arbitrary/numerical property
2. **Declare the Definition** in `A2uiCatalogItemDefinition`:
   Specifies the component `type`, `builder` registration key, and JSON `schema` using `json_schema_builder` (`S.object(...)`).

### Example: Custom Metric Card

```dart
void registerCatalog() {
  A2uiCatalogRegistry.register('kpi_metric_card', (context, node, props, buildChild) {
    final theme = Theme.of(context);
    final title = props.string('title') ?? 'Metric';
    final value = props.string('value') ?? '-';
    final change = props.string('change') ?? '';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (change.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(change, style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  });
}
```

Attach to playground:

```dart
A2uiMcpPlayground(
  a2uiCatalogItems: [
    A2uiCatalogItemDefinition(
      type: 'KpiMetricCard',
      builder: 'kpi_metric_card',
      description: 'Displays a key metric summary card with title, value, and change indicator.',
      schema: S.object(
        properties: {
          'title': S.string(description: 'Metric title'),
          'value': S.string(description: 'Formatted metric value'),
          'change': S.string(description: 'Optional change trend description'),
        },
        required: ['title', 'value'],
      ),
    ),
  ],
)
```

---

## 🛠️ Registering Custom MCP Tools

Local tools extend LLM capabilities. To return JSON structured output to the model:

```dart
import 'dart:convert';
import 'package:flutter_a2ui_mcp/flutter_a2ui_mcp.dart';

class SystemStatusTool extends McpLocalTool {
  @override
  String get name => 'get_system_status';

  @override
  String get description => 'Retrieves CPU, Memory, and Network telemetry.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'system': {'type': 'string', 'description': 'System identifier'},
    },
    'required': ['system'],
  };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final data = {
      'system': arguments['system'],
      'cpuUsage': '24%',
      'memoryFree': '12.4 GB',
      'activeNodes': 8,
      'status': 'HEALTHY',
    };
    return MCPToolResult.text(jsonEncode(data));
  }
}
```

Pass tool instances to `A2uiMcpPlayground(customLocalTools: [SystemStatusTool()])`.

---

## 🧠 LLM System Prompting for A2UI

Instruct your model to emit valid A2UI JSON either in `<a2ui-json>` tags or in markdown ` ```json ` blocks:

```markdown
### Agent-to-User Interface (A2UI) Instructions
You can render rich, interactive user interface surfaces using the A2UI standard.
To display a UI surface, emit valid A2UI JSON either inside `<a2ui-json>...</a2ui-json>` tags or a ```json code block.
```

`McpA2uiChatController` automatically detects these blocks, streams the chat text, builds the `SurfaceModel`, and renders the native Flutter widget seamlessly.

---

## 🔄 Migration Guide from `flutter_genui_mcp`

| Old API (`flutter_genui_mcp`) | New API (`flutter_a2ui_mcp`) |
| :--- | :--- |
| `import 'package:flutter_genui_mcp/flutter_genui_mcp.dart';` | `import 'package:flutter_a2ui_mcp/flutter_a2ui_mcp.dart';` |
| `FlutterGenUiMcp` / `GenuiMcpPlayground` | `A2uiMcpPlayground` *(typedefs preserved for compatibility)* |
| `McpGenuiChatController` | `McpA2uiChatController` |
| `GenuiCatalogItemDefinition` | `A2uiCatalogItemDefinition` |
| `GenuiCatalogRegistry` | `A2uiCatalogRegistry` |
| `genuiCatalogItems:` parameter | `a2uiCatalogItems:` parameter |
| `genuiCatalog:` parameter | `a2uiCatalog:` parameter |
| `buildGenuiCatalog(...)` | `buildA2uiCatalog(...)` |
| `genui: ^0.10.4` (discontinued) | `a2ui_flutter: ^0.3.0` & `a2ui_core: ^0.7.0` |

---

## 🧪 Testing Guidelines

When writing widget or unit tests for `flutter_a2ui_mcp`:
1. Use `TestWidgetsFlutterBinding.ensureInitialized();`
2. **Never** import `package:flutter/material.dart` in the test file.
3. Import `package:flutter_test/flutter_test.dart` and `package:flutter_a2ui_mcp/flutter_a2ui_mcp.dart`.
4. Run tests with `flutter test`.


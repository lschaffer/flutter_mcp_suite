# MCP Playground Example Showcase

This directory contains a complete showcase application demonstrating how to integrate the [`flutter_ui_mcp`](https://pub.dev/packages/flutter_ui_mcp) widget into a Flutter project.

It initializes the playground widget with custom local Dart-native tools (Weather, SSH/SFTP, and Chart Generator) and registers local MCP subprocesses (`Git` and `Filesystem`) automatically.

---

## 🎨 Visual Preview

Here is how the playground and its configuration interfaces look:

### LLM Provider Setup
![LLM Config](../screenshots/example_ui/playground_config_llm.png)

### Remote MCP Server configuration
![LLM Config](../screenshots/example_ui/playground_config_remote_mcp.png)

### Local MCP Server configuration
![LLM Config](../screenshots/example_ui/playground_config_local_mcp.png)

### Local MCP Server add custom configuration
![LLM Config](../screenshots/example_ui/playground_config_add_local_mcp.png)


### Local MCP Subprocesses Setup (Desktop Mode)
![Local MCP Config](../screenshots/example_ui/playground_config_local_mcp.png)

### Filesystem (nodejs) MCP Server Test
![Filesystem MCP Test](../screenshots/example_ui/filesystem_mcp_test.png)

### Git (python) MCP Server Test
![Git MCP Test](../screenshots/example_ui/git_mcp_test.png)

### Custom (dart) MCP Servers (Weather, Chart) Test
![Custom MCP Test](../screenshots/example_ui/local_dart_mcp_test.png)

---

## 🚀 How to Run

1. Navigate to the `example/` directory:
   ```bash
   cd example/
   ```
2. Copy the template `.env` and fill in your provider keys and parameters:
   ```env
   LLM_PROVIDER=openai
   LLM_MODEL=gpt-4o-mini
   LLM_API_KEY=your_key_here
   ```
3. Run the application:
   ```bash
   flutter pub get
   flutter run
   ```

---

## 📦 Features Demonstrated

- **GenUI Weather Showcase (`enableGenUi: true`)**:
  - Demonstrates embedding GenUI (A2UI) widgets directly in `McpPlayground`.
  - The model outputs interactive form (`WeatherForm`) and multi-line interactive chart (`WeatherChart` via `fl_chart`) components.
- **Custom Local Dart-native Tools**:
  - **Weather**: Fetch conditions and forecasts using the Open-Meteo API.
  - **SSH/SFTP**: List, read, download, upload files and execute commands.
  - **Chart Generator**:
    - **Interactive Rendering (`messageContentBuilder`)**: The `create_chart_png` tool outputs a custom JSON description of the chart. The host application intercepts this response using the `messageContentBuilder` callback parameter on the widget and renders a fully interactive chart using the `fl_chart` library.
    - **Direct PNG Generation (`chart2png`)**: The `chart2png` tool uses an offscreen canvas to rasterize the chart into raw PNG bytes, returning it as a base64-encoded image attachment so it is rendered by the playground's built-in image preview widget.
- **Local MCP Subprocesses (Subprocesses Mode)**:
  - Spawns local stdio-based MCP servers:
    - **Git** (runs `mcp-server-git` via `uvx`)
    - **Filesystem** (runs `@modelcontextprotocol/server-filesystem` via `npx` or `npm`)
- **Host Requirements for Local Subprocesses**:
  - **Node.js** (for filesystem npx actions)
  - **Python 3** & **`uv`** (for git uvx actions)

---

## 🔍 Progressive MCP Tool Discovery (`McpListToolsTool` & `McpCallToolTool`)

When connected to multiple MCP servers with 50+ tools, loading every tool's schema into the LLM prompt upfront can consume 10,000+ tokens on every turn. 

Progressive Tool Discovery solves this by providing only two meta-tools:
- **`mcp_list_tools`** (`McpListToolsTool`): Lists available tools across connected servers on-demand.
- **`mcp_call_tool`** (`McpCallToolTool`): Dynamically calls any discovered tool by name with arguments.

### Quick Usage with `McpPlayground`:
```dart
McpPlayground(
  progressiveMcpDiscovery: true, // Only injects mcp_list_tools and mcp_call_tool
  customLocalTools: [
    GetCurrentWeatherTool(),
    GetHourlyForecastTool(),
  ],
)
```

### Manual / Programmatic Usage:
```dart
final mcpManager = MultiMCPManager();
await mcpManager.connectSse('https://remote.mcp.server/sse');

// Wrap connected servers with discovery meta-tools:
final listToolsTool = McpListToolsTool(mcpManager: mcpManager);
final callToolTool = McpCallToolTool(mcpManager: mcpManager);

// Pass to McpPlayground or Agent:
McpPlayground(
  customLocalTools: [listToolsTool, callToolTool],
)
```

A dedicated runnable example screen is available in [`lib/progressive_discovery_example.dart`](lib/progressive_discovery_example.dart) and can be opened directly from the AppBar icon in the example app.


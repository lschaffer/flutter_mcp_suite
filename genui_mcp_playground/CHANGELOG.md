## 0.1.0

* **Initial standalone release of `genui_mcp_playground`**:
  * Dynamic, generative UI chat interface powered by the `genui` (`A2UI`) protocol.
  * `GenuiMcpPlayground`: Top-level interactive playground shell featuring live conversation surface rendering, setup customization, tool toggling, LLM provider override, and side-by-side `AgentInspector`.
  * `McpGenuiChatController`: High-level controller connecting `mcp_playground_dart`'s `LLMService` tool calling loop with `SurfaceController` and `A2uiTransportAdapter`.
  * `GenuiChatView`: Transcript & surface renderer widget.
  * `GenuiCatalogItemDefinition` & `GenuiCatalogRegistry`: Pluggable catalog schema builder for declarative dynamic widgets.
  * Cross-platform support for Windows, macOS, Linux, Web, iOS, and Android.

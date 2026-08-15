## 0.3.0

- **Multimodal File & Attachment Support**: User attachments (code files, logs, images) are now passed to the GenUI controller and streamed into multimodal LLM providers.
- **Copy Prompts & Responses**: Added copy-to-clipboard buttons with feedback snackbars to all user prompts and assistant message bubbles.
- **New Travel Planner Primary Showcase**: Added Travel & Accommodation Planner (`example`) featuring SerpAPI Google search, interactive form widgets (`TravelSearchForm`), stay cards (`AccommodationGrid`), and exportable day-by-day itineraries (`TravelItineraryCard`) with high-res JPG export.
- Upgraded `mcp_playground_dart` to `^0.3.0` and `mcp_playground_ui` to `^0.3.0`.

## 0.1.0

* **Initial standalone release of `genui_mcp_playground`**:
  * Dynamic, generative UI chat interface powered by the `genui` (`A2UI`) protocol.
  * `GenuiMcpPlayground`: Top-level interactive playground shell featuring live conversation surface rendering, setup customization, tool toggling, LLM provider override, and side-by-side `AgentInspector`.
  * `McpGenuiChatController`: High-level controller connecting `mcp_playground_dart`'s `LLMService` tool calling loop with `SurfaceController` and `A2uiTransportAdapter`.
  * `GenuiChatView`: Transcript & surface renderer widget.
  * `GenuiCatalogItemDefinition` & `GenuiCatalogRegistry`: Pluggable catalog schema builder for declarative dynamic widgets.
  * Cross-platform support for Windows, macOS, Linux, Web, iOS, and Android.

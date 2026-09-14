## 0.3.5

- **GenUI Client-Side Functions Support**:
  - Exported `ClientFunction`, `SynchronousClientFunction`, `ClientFunctionReturnType`, `ExecutionContext`, and `BasicFunctions` from `genui` package.
  - Added optional `clientFunctions` parameter to `GenuiMcpPlayground`, `McpGenuiChatController`, and `buildGenuiCatalog`, allowing client-side functions to be registered directly into the GenUI catalog.
  - Automatically incorporates client-side functions into the GenUI Catalog schema for prompt generation and synchronous client-side execution.

## 0.3.4

- Replaced `PlatformFile.lengthSync()` with `bytes.length` in attachment handling, resolving `UNDEFINED_METHOD` failures during dependency lower-bound analysis.
- Upgraded `mcp_playground_ui` to `^0.3.4`.

## 0.3.3

- **WASM & Web Platform Support**: Eliminated direct imports of `dart:io` in favor of `defaultTargetPlatform`, and upgraded to `mcp_playground_ui: ^0.3.3` with conditional exports to ensure full WebAssembly (WASM) compatibility.
- **Dependency Lower Bounds Fix**: Fixed nullable type-promotion for `file_picker` in attachment selection, resolving `UNCHECKED_USE_OF_NULLABLE_VALUE` errors during `pub downgrade` analysis.
- **Dependency Upgrades**:
  - Upgraded `mcp_playground_ui` to `^0.3.3`.
  - Upgraded `genai_primitives` to `^0.2.4`.
  - Removed unused `universal_io` dependency.

## 0.3.2
- Upgraded dependencies:
  - `mcp_playground_dart` to `^0.3.2`
  - `mcp_playground_ui` to `^0.3.2`
  - `json_schema_builder` to `^0.1.7`
- **New Dynamic GenUI Examples**:
  - **Smart Home & Climate Studio** (`examples/genui/example_genui_smarthome`): Interactive generative UI with thermostat temperature controls, device toggle switches, and live `fl_chart` energy consumption bar charts.
  - **Financial Portfolio & Budget Planner** (`examples/genui/example_genui_finance`): Budgeting companion rendering expense category pie charts (`fl_chart`), interactive spending sliders, and compound interest projection curves.
  - **Data Visualizer & Query Studio** (`examples/genui/example_genui_data_studio`): Executive dashboard generator featuring KPI metric cards with trend indicators, horizontal scrollable data tables, and dynamic time-series charts.

## 0.3.1

- Declared supported platforms explicitly in `pubspec.yaml` (Android, iOS, Linux, macOS, Web, Windows).
- Fixed `repository` URL in `pubspec.yaml` to point to GitHub `main` branch.
- Broadened `file_picker` dependency constraint to `'>=11.0.3 <13.0.0'` to support `file_picker` 12.0.0+.

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

## 1.0.1

- Upgraded dependencies: `material_ui` to `^1.4.0`, `file_picker` to `^13.1.0`, `archive` to `^4.3.0`, `llamadart` to `^0.8.24`.
- Expanded version constraints for `anthropic_sdk_dart`, `googleai_dart`, `openai_dart`, and `ollama_dart`.
- Added standalone showcase example package in `example/`.

## 1.0.0

- **Initial stable production release** under the `flutter_mcp_suite` ecosystem.
- Rebranded and modernized from `mcp_playground_ui`.
- Shared UI controllers, inspector drawer, embedded GGUF model discoverers, and MCP server registry components.
- Depends on `dart_mcp_core: ^1.0.0`.

## 0.4.0

- **BREAKING CHANGE - Decoupled Material UI**:
  - Migrated from legacy `package:flutter/material.dart` to standalone `package:material_ui/material_ui.dart` using the official Flutter migration tool (`dart fix --apply --code=migrate_design_widgets`).
  - Added dependency on `material_ui: ^1.3.0`.
  - Re-exported `package:material_ui/material_ui.dart` in `mcp_playground_ui.dart` for backwards and downstream compatibility.
- Upgraded `file_picker` to `^13.0.0`.
- Fixed markdown style sheet text colors in dark mode to guarantee legible `onSurface` contrast for headings and body text.

## 0.3.4

- Tightened `file_picker` dependency constraint to `^12.0.0` and removed redundant null checks to ensure seamless `pub downgrade` analysis.
- Fixed dartdoc parameter references in `SkillStorageAdapter` implementations.

## 0.3.3

- Enabled WebAssembly (WASM) runtime support:
  - Replaced direct `dart:io` and `path_provider` imports with conditional exports and platform-agnostic helpers.
  - Added conditional stubs for `EmbeddedModelManager`, `LocalMCPClient`, and `FileSystemSkillStorageAdapter` for Web/WASM runtimes.
  - Decoupled HTML preview in chat bubbles via conditional launcher.
  - Removed `universal_io` dependency.
  - Replaced platform checks with `defaultTargetPlatform`.

## 0.3.2

- Upgraded AI and core dependencies:
  - `mcp_playground_dart` to `^0.3.2`
  - `anthropic_sdk_dart` to `^8.0.0`
  - `googleai_dart` to `^12.0.1`
  - `openai_dart` to `^8.1.0`
  - `ollama_dart` to `^2.6.1`
  - `llamadart` to `^0.8.23`
  - `archive` to `^4.2.0`
  - `flutter_widget_from_html` to `^0.17.4`

## 0.3.1

- Declared supported platforms explicitly in `pubspec.yaml` (Android, iOS, Linux, macOS, Web, Windows).
- Fixed `repository` URL in `pubspec.yaml` to point to GitHub `main` branch.
- Broadened `file_picker` dependency constraint to `'>=11.0.3 <13.0.0'` to support `file_picker` 12.0.0+.

## 0.3.0

- Updated `WorkflowSaveDialog` to use Flutter 3.32+ `RadioGroup<bool>` ancestor, resolving deprecated `groupValue` warnings.
- Added auto-sync to `PlaygroundController.connectServer()` for newly registered or unsynced clients.
- Added copy button and clipboard feedback for user prompts and assistant message bubbles.
- Upgraded `mcp_playground_dart` to `^0.3.0`.

## 0.1.0

* Initial release of `mcp_playground_ui` extracting common Flutter components, dialogs, drawers, and controllers into a shared library.

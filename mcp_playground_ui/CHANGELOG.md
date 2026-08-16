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

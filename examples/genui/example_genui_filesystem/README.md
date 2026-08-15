# GenUI Filesystem Explorer (`example_genui_filesystem`)

An interactive Flutter application demonstrating Google GenUI (`A2UI`) with Dart-native filesystem MCP tools, rendering dynamic directory trees, file preview surfaces, and metadata cards.

---

## ✨ Features

- **Dynamic Directory Tree Surface (`DirectoryTreeView`)**: Model-generated interactive file explorer with collapsible directories, file type badges, and size formatting.
- **File Content Viewer Surface (`FileContentCard`)**: Syntax-highlighted text and code preview surfaces with line numbers and file statistics.
- **Native Dart MCP Filesystem Tools**:
  - `list_directory_tree`: Lists entries with type and size metadata.
  - `read_file_content`: Reads text files with safety limits.
  - `get_file_metadata`: Retrieves modified dates, permissions, and file byte sizes.
- **Side-by-Side Agent Inspector**: Live inspection of system prompts, tool call executions, and JSON schema payloads.

---

## 🚀 How to Run

```bash
cd examples/genui/example_genui_filesystem
flutter pub get
flutter run -d windows # or macos / linux / chrome
```

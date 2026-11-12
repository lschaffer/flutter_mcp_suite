---
name: a2ui-filesystem-explorer
description: Explores local directories, inspects metadata, and renders interactive directory trees and syntax-highlighted file preview surfaces via A2UI.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are an expert Filesystem Navigator and Code Explorer AI Assistant.
  When the user queries directories or files:
  1. Invoke filesystem tools:
     - `list_directory` to traverse directory hierarchies.
     - `read_file_content` to inspect source files and configs.
     - `get_file_metadata` to retrieve permissions, sizes, and timestamps.
  2. Render rich, interactive A2UI components:
     - "DirectoryTreeView" for collapsible folder structures.
     - "FilePreviewSurface" with syntax highlighting.
     - "FileMetadataCard" with size and modification stats.

prompts:
  - text: Explore current project directory and render an interactive tree view with file sizes.
    tools: [list_directory]
    stop_after_tool_call: true
  - text: Inspect pubspec.yaml file metadata and display its configuration contents.
    tools: [get_file_metadata, read_file_content]
    stop_after_tool_call: true
  - text: Preview lib/main.dart and highlight imports and top-level definitions.
    tools: [read_file_content]
    stop_after_tool_call: true

tools:
  - name: list_directory
    description: List files and subdirectories for a given directory path.
    runtime: dart
    capability: directory_listing
    input_schema:
      type: object
      properties:
        path: {type: string, description: "Target directory path"}
      required: [path]

  - name: read_file_content
    description: Read the textual content of a local file.
    runtime: dart
    capability: file_reading
    input_schema:
      type: object
      properties:
        path: {type: string, description: "Target file path"}
      required: [path]

  - name: get_file_metadata
    description: Retrieve file attributes (byte size, modification date, MIME type).
    runtime: dart
    capability: file_metadata
    input_schema:
      type: object
      properties:
        path: {type: string, description: "Target file path"}
      required: [path]

mcp_playground:
  chat_mode: true
  is_multi_turn: true
---

# A2UI Cloud & Filesystem Explorer Skill

This skill provides AI agents with safe filesystem inspection and interactive visual surfaces:
1. Collapsible hierarchical directory tree (`DirectoryTreeView`)
2. Syntax-highlighted file preview surface (`FilePreviewSurface`)
3. File attribute and size summary card (`FileMetadataCard`)


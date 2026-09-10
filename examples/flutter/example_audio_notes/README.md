# Meeting Notes & Action Items Assistant (Flutter MCP Example)

Demonstrates embedding `McpPlayground` with custom tools to load meeting transcripts, analyze conversations, extract structured action items (owner, task, deadline, priority), and render interactive action item cards.

## Features
- Ingestion of meeting transcripts
- Extraction of structured action items and owner assignment
- Live interactive Action Item checklist cards rendered via `messageContentBuilder`
- Export of clean markdown meeting minutes

## 💡 Example Prompts
Try asking the assistant:
- *"Load the latest engineering sprint sync transcript and outline key discussion topics."*
- *"Extract all action items from the meeting with owners, priorities, and deadlines."*
- *"Compile executive meeting minutes and export the notes to markdown."*

## Running
```bash
cd examples/flutter/example_audio_notes
flutter pub get
flutter run -d windows # or -d chrome
```

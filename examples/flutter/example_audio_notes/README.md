# Meeting Notes & Action Items Assistant (Flutter MCP Example)

Demonstrates embedding `McpPlayground` with custom tools to load meeting transcripts, analyze conversations, extract structured action items (owner, task, deadline, priority), and render interactive action item cards.

## Features
- Ingestion of meeting transcripts
- Extraction of structured action items and owner assignment
- Live interactive Action Item checklist cards rendered via `messageContentBuilder`
- Export of clean markdown meeting minutes

## 🧠 Agent Skill (`skill.md`)
This directory contains a pre-configured [`skill.md`](skill.md) file defining the complete workflow, system prompt, and tool requirements according to the AgentSkills.io standard.

You can either:
1. **Load the Skill**: In the application, click **Skills** &rarr; **Import Skill** and select [`skill.md`](skill.md). The playground will automatically configure the system prompt, enable the meeting tools, and prepare the multi-step prompt sequence.
2. **Manual Prompts**: Or enter the example system prompt and user prompts below directly.

## ⚙️ Example System Prompt
```
You are an executive meeting secretary and agile delivery coach. You have access to meeting transcript and notes tools:
- `load_meeting_transcript`: Retrieves full meeting dialog transcripts and discussion threads.
- `extract_action_items`: Structures decisions into actionable checklists with task name, owner, priority (high/med/low), and deadline.
- `export_meeting_notes`: Saves finalized meeting minutes and executive summaries.
Always extract clear action items with assignees and deadlines from conversations.
```

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

> **Note**: After launching the application, verify that the custom tools (`load_meeting_transcript`, `extract_action_items`, `export_meeting_notes`) are checked and enabled in the **Tools** drawer / panel, then send your prompt (or load [`skill.md`](skill.md) to enable them automatically).

---
name: meeting-notes-action-items
description: Ingests meeting transcript conversations, categorizes action items with owners, priorities, and deadlines, and exports markdown meeting minutes.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are an executive meeting secretary and agile delivery coach. You have access to meeting transcript and notes tools:
  - `load_meeting_transcript`: Retrieves full meeting dialog transcripts and discussion threads.
  - `extract_action_items`: Structures decisions into actionable checklists with task name, owner, priority (high/med/low), and deadline.
  - `export_meeting_notes`: Saves finalized meeting minutes and executive summaries.
  Always extract clear action items with assignees and deadlines from conversations.

prompts:
  - text: Load the latest engineering sprint sync transcript and outline key discussion topics.
    tools: [load_meeting_transcript]
    stop_after_tool_call: true
  - text: Extract all action items from the meeting with owners, priorities, and deadlines.
    tools: [extract_action_items]
    stop_after_tool_call: true
  - text: Compile executive meeting minutes and export the notes to markdown.
    tools: [export_meeting_notes]

tools:
  - name: load_meeting_transcript
    description: Load full raw audio transcript of the latest team meeting with speaker timestamps.
    runtime: dart
    capability: transcript_reader
    input_schema:
      type: object
      properties:
        meeting_id: {type: string, description: "Optional meeting identifier or date."}

  - name: extract_action_items
    description: Parse meeting notes or transcript into structured action items with assignees, priorities, and due dates.
    runtime: dart
    capability: action_items
    input_schema:
      type: object
      properties:
        min_priority: {type: string, enum: [low, medium, high], description: "Minimum priority filter."}

  - name: export_meeting_notes
    description: Export formatted executive meeting minutes and action items to a markdown document.
    runtime: dart
    capability: file_export
    input_schema:
      type: object
      properties:
        title: {type: string, description: "Meeting title"}
        filename: {type: string, description: "Destination filename, e.g. MEETING_MINUTES.md"}
      required: [title]

mcp_playground:
  chat_mode: true
  is_multi_turn: true
---

# Meeting Notes & Action Items Assistant Skill

This skill guides the AI assistant in extracting actionable outcomes from meeting transcripts:
1. Ingest meeting discussions and speaker dialogue
2. Extract concrete tasks, assignees, priorities, and deadlines
3. Export structured markdown meeting minutes

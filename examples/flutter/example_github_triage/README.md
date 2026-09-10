# GitHub Issue Triage & PR Review Copilot (Flutter MCP Example)

Demonstrates embedding `McpPlayground` with GitHub triage and code review tools.
The assistant queries repository issues, categorizes tickets, suggests labels, and drafts structured pull request code reviews.

## Features
- Embedded `McpPlayground` with Git repo management tools
- Issue listing, priority labeling, and triage assignment
- Automated pull request code review drafting
- Custom issue card preview using `messageContentBuilder`

## 💡 Example Prompts
Try asking the assistant:
- *"Fetch and list the open GitHub issues currently awaiting triage."*
- *"Triage issue #104: evaluate impact, suggest priority tags, and recommend assignee."*
- *"Draft a structured PR review for the latest pull request with code suggestions."*

## Running
```bash
cd examples/flutter/example_github_triage
flutter pub get
flutter run -d windows # or -d chrome
```

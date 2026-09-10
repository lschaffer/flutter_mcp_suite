# GitHub Issue Triage & PR Review Copilot (Flutter MCP Example)

Demonstrates embedding `McpPlayground` with GitHub triage and code review tools.
The assistant queries repository issues, categorizes tickets, suggests labels, and drafts structured pull request code reviews.

## Features
- Embedded `McpPlayground` with Git repo management tools
- Issue listing, priority labeling, and triage assignment
- Automated pull request code review drafting
- Custom issue card preview using `messageContentBuilder`

## 🧠 Agent Skill (`skill.md`)
This directory contains a pre-configured [`skill.md`](skill.md) file defining the complete workflow, system prompt, and tool requirements according to the AgentSkills.io standard.

You can either:
1. **Load the Skill**: In the application, click **Skills** &rarr; **Import Skill** and select [`skill.md`](skill.md). The playground will automatically configure the system prompt, enable the repository triage tools, and prepare the multi-step prompt sequence.
2. **Manual Prompts**: Or enter the example system prompt and user prompts below directly.

## ⚙️ Example System Prompt
```
You are an experienced open-source maintainer and GitHub triage bot. You have access to repository tools:
- `list_repo_issues`: Retrieves open tickets, bug reports, and pull requests.
- `triage_issue`: Analyzes issue descriptions, classifies severity (P0-P3), and recommends labels and assignees.
- `draft_pr_review`: Generates structured code review comments with inline diff recommendations.
Always prioritize severe bugs and suggest concise, polite, and actionable review feedback.
```

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

> **Note**: After launching the application, verify that the custom tools (`list_repo_issues`, `triage_issue`, `draft_pr_review`) are checked and enabled in the **Tools** drawer / panel, then send your prompt (or load [`skill.md`](skill.md) to enable them automatically).

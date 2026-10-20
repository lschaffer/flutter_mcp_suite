# GenUI Autonomous Multi-Agent Mission Control

Demonstrates how AI agents orchestrate specialist autonomous subagents, stream live execution pipelines, and solicit human authorizations using `flutter_genui_mcp`, `flutter_ui_mcp_core`, and the autonomous subagent iteration loop.

Users can command complex engineering workflows and dynamically stream interactive GenUI widgets:
- **`AgentSwarmTimeline`**: Visual step-by-step pipeline displaying multi-agent progress, specialist roles, and status badges (`running`, `waiting_approval`, `completed`).
- **`SubagentCard`**: Detailed report card showing specialist subagent findings, executed turns, token metrics, and security dossiers.
- **`ApprovalGateWidget`**: Interactive human-in-the-loop decision card allowing developers to **"Approve Action"** or **"Reject / Halt"** high-risk operations directly in the chat feed.

## Features
- **Autonomous Multi-Agent Loop**: Emulates multi-turn specialist subagent loops with turn counters and tool invocation traces.
- **Human-in-the-Loop Governance**: Safe interactive decision gates for authorizing sensitive infrastructure actions.
- **Agent Inspector Integration**: Inspect real-time tokens, costs, and execution traces with the top action bar toggle.

## 🧠 Agent Skill (`skill.md`)
This directory contains a pre-configured [`skill.md`](skill.md) file adhering to the AgentSkills.io standard.

You can either:
1. **Load the Skill**: In the application, click **Skills** &rarr; **Import Skill** and select [`skill.md`](skill.md). The playground will automatically configure the mission control system prompt, enable swarm tools, and prepare sample prompt queries.
2. **Manual Prompts**: Or enter the prompts below directly.

## 💡 Example Prompts
Try asking the assistant:
- *"Query the active swarm pipeline status and render the specialist agent progress timeline."*
- *"Spawn our autonomous Security Auditor subagent to perform a full vulnerability scan on the authentication service."*
- *"The QA Test Engineer wants to run a high-volume destructive stress test on the staging database. Trigger a human decision gate."*

## Running
```bash
cd examples/genui/example_genui_agent_swarm
flutter pub get
flutter run -d windows # or -d chrome
```

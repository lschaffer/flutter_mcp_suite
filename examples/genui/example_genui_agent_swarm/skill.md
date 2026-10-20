---
name: genui-agent-swarm-mission-control
description: Orchestrates autonomous specialist subagents, monitors live pipelines, and presents human-in-the-loop approval gates via GenUI.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are the Supreme Mission Control AI Orchestrator.
  You command a swarm of autonomous specialist subagents:
  - Security Auditor (vulnerability scans, auth verification)
  - Code Architect (structural refactoring, design pattern analysis)
  - Test Engineer (load testing, QA assertion runs)

  When executing complex multi-step objectives:
  1. Invoke tools:
     - `spawn_subagent` to delegate tasks to autonomous specialist loops.
     - `query_swarm_status` to monitor live pipeline progress.
     - `request_human_approval` before executing high-risk state changes.
  2. Render rich, interactive GenUI components:
     - "AgentSwarmTimeline" to show visual pipeline progression across all specialists.
     - "SubagentCard" to detail individual subagent findings, turns, and resource usage.
     - "ApprovalGateWidget" when human authorization is needed.

prompts:
  - text: Query the active swarm pipeline status and render the specialist agent progress timeline.
    tools: [query_swarm_status]
    stop_after_tool_call: true
  - text: Spawn our autonomous Security Auditor subagent to perform a full vulnerability scan on the authentication service.
    tools: [spawn_subagent]
    stop_after_tool_call: true
  - text: The QA Test Engineer wants to run a high-volume destructive stress test on the staging database. Trigger a human decision gate.
    tools: [request_human_approval]
    stop_after_tool_call: true

tools:
  - name: spawn_subagent
    description: Spawn an autonomous multi-turn specialist subagent to perform an isolated objective and report back.
    runtime: dart
    capability: subagent_orchestration
    input_schema:
      type: object
      properties:
        agent_role: {type: string, description: "Specialist role."}
        objective: {type: string, description: "Specific task goal."}
        max_turns: {type: integer, description: "Max autonomous turn iterations."}
      required: [agent_role, objective]

  - name: query_swarm_status
    description: Query the active status, resource consumption, and deliverables across all subagents in the swarm.
    runtime: dart
    capability: swarm_status
    input_schema:
      type: object
      properties: {}

  - name: request_human_approval
    description: Halt autonomous loop and present an interactive decision gate for human approval before critical actions.
    runtime: dart
    capability: human_in_the_loop
    input_schema:
      type: object
      properties:
        action_name: {type: string, description: "Action name."}
        risk_level: {type: string, description: "Risk severity (low, medium, high, critical)."}
        description: {type: string, description: "Explanation of side effects."}
      required: [action_name, risk_level, description]

mcp_playground:
  chat_mode: true
  is_multi_turn: true
---

# GenUI Autonomous Multi-Agent Mission Control Skill

This skill empowers AI agents to command swarms of autonomous specialist subagents:
1. Live visual pipeline timeline tracking (`AgentSwarmTimeline`)
2. Detailed subagent deliverables and turn metrics (`SubagentCard`)
3. Human-in-the-loop interactive decision gates (`ApprovalGateWidget`)

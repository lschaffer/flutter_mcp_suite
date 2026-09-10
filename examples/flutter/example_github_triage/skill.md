---
name: github-issue-pr-triage
description: Inspects open repository bug reports and pull requests, categorizes severity, recommends tags, and drafts PR reviews.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are an experienced open-source maintainer and GitHub triage bot. You have access to repository tools:
  - `list_repo_issues`: Retrieves open tickets, bug reports, and pull requests.
  - `triage_issue`: Analyzes issue descriptions, classifies severity (P0-P3), and recommends labels and assignees.
  - `draft_pr_review`: Generates structured code review comments with inline diff recommendations.
  Always prioritize severe bugs and suggest concise, polite, and actionable review feedback.

prompts:
  - text: Fetch and list the open GitHub issues currently awaiting triage.
    tools: [list_repo_issues]
    stop_after_tool_call: true
  - text: Triage issue #104: evaluate impact, suggest priority tags, and recommend assignee.
    tools: [triage_issue]
    stop_after_tool_call: true
  - text: Draft a structured PR review for the latest pull request with code suggestions.
    tools: [draft_pr_review]

tools:
  - name: list_repo_issues
    description: List open issues and pull requests awaiting triage in the target GitHub repository.
    runtime: dart
    capability: github_issues
    input_schema:
      type: object
      properties:
        state: {type: string, enum: [open, closed, all], description: "Filter by issue state (default open)."}
        limit: {type: integer, description: "Maximum issues to return."}

  - name: triage_issue
    description: Categorize issue severity, suggested labels, and recommend reviewers.
    runtime: dart
    capability: issue_triage
    input_schema:
      type: object
      properties:
        issue_id: {type: integer, description: "Issue number (e.g. 104)"}
      required: [issue_id]

  - name: draft_pr_review
    description: Generate an automated structured code review draft for a pull request diff.
    runtime: dart
    capability: pr_review
    input_schema:
      type: object
      properties:
        pr_id: {type: integer, description: "Pull request number"}
      required: [pr_id]

mcp_playground:
  chat_mode: true
  is_multi_turn: true
---

# GitHub Issue Triage & PR Review Skill

This skill configures the assistant to maintain GitHub and GitLab projects:
1. List tickets awaiting team attention
2. Classify impact severity and suggest actionable labels
3. Formulate thorough, respectful Pull Request code reviews

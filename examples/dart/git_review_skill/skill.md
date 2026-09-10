---
name: git-diff-reviewer
description: Multi-step agent skill that inspects git status, reads staged diffs, runs static analysis, and produces a structured PR review and changelog.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are an expert software engineer and code reviewer.
  Your job is to inspect git modifications, check code health, and generate a clear, comprehensive Pull Request description with summary of changes, potential risks, and testing checklists.
  Always explain your reasoning and highlight breaking changes or security concerns.

prompts:
  - text: Check the current git status and retrieve the recent or staged code diff. Summarize what files were modified or added.
    tools: [git_status, git_diff]
    stop_after_tool_call: true
  - text: Run static analysis on the modified codebase, then compile a final PR review and export it to PR_REVIEW.md.
    tools: [run_analyzer, export_pr_summary]

tools:
  - name: git_status
    description: Get the current git branch name and list of modified/staged/untracked files.
    runtime: dart
    capability: git_status
    input_schema:
      type: object
      properties:
        repo_path: {type: string, description: "Optional path to git repository. Defaults to current directory."}

  - name: git_diff
    description: Get unified diff of staged or unstaged changes in the repository.
    runtime: dart
    capability: git_diff
    input_schema:
      type: object
      properties:
        staged_only: {type: boolean, description: "If true, only inspects staged changes (--cached)."}
        file_path: {type: string, description: "Optional specific file to view diff for."}

  - name: run_analyzer
    description: Run static analysis (dart analyze) on modified files to verify there are no lint or compile errors.
    runtime: dart
    capability: code_analysis
    input_schema:
      type: object
      properties:
        target_path: {type: string, description: "Target directory or file to analyze."}

  - name: export_pr_summary
    description: Export the completed pull request review, changelog, and checklist to a markdown file.
    runtime: dart
    capability: file_export
    input_schema:
      type: object
      properties:
        title: {type: string, description: "Pull request title"}
        summary: {type: string, description: "Summary of changes made"}
        breaking_changes: {type: array, items: {type: string}, description: "List of any breaking changes"}
        test_checklist: {type: array, items: {type: string}, description: "Checklist of items to verify"}
        output_filename: {type: string, description: "File path to write markdown report to, e.g. PR_REVIEW.md"}
      required: [title, summary, test_checklist]

mcp_playground:
  chat_mode: false
  is_multi_turn: true
  created_at: "2026-09-10T10:00:00Z"
---

# Git Diff Reviewer & PR Summary Skill

This skill demonstrates a multi-turn agent workflow for developer tooling:
1. Inspect git status and code diffs
2. Run static analysis to detect errors or warnings
3. Generate and export a structured GitHub/GitLab Pull Request description

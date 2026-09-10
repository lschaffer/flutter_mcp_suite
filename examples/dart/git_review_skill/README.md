# Git Review Skill Example (Pure Dart)

Demonstrates how to use `mcp_playground_dart` to load a developer skill from `skill.md`, register native Dart git tools, and execute a multi-turn agent workflow that reviews staged code diffs and writes a structured Pull Request review.

## Features
- Multi-step workflow defined in `skill.md`
- Inspects git branch status and git diffs
- Executes `dart analyze` to verify code health
- Exports a complete PR review checklist to `PR_REVIEW.md`

## Running
```bash
cd examples/dart/git_review_skill
dart pub get
dart run main.dart
```

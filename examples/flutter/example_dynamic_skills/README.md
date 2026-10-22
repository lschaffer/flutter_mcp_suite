# Dynamic Runtime Skills Dock Showcase

A Flutter application showcasing **Dynamic Skill Activation (`DynamicSkillDock`)**, runtime tool exposure, and agent-driven skill activation (`activate_skills` / `deactivate_skills`).

![Dynamic Skills Dock Showcase](https://raw.githubusercontent.com/lschaffer/flutter_mcp_suite/main/screenshots/video/flutter_ui_dynamic_skills.gif)

---

## 🔌 Where Does the Data Come From?

* **Registered Dynamic Skills (`lib/main.dart`)**:
  * In `_registerSkills()`, three `SkillDefinition`s are registered with `PlaygroundController`:
    1. `sql_optimizer`: SQL execution plans, buffer pool analysis, B-Tree index synthesis.
    2. `release_manager`: Git commit log parsing, SemVer checks, Keep a Changelog generator.
    3. `security_auditor`: HTTP response headers, CSP policies, wildcard CORS leak detection.
* **Specialized Domain Tools (`lib/tools.dart`)**:
  * `explain_sql_query`: Simulates PostgreSQL `EXPLAIN (ANALYZE, BUFFERS)` output with cost estimates (4520.8 cost) and indexes to add.
  * `generate_release_notes`: Generates formatted markdown changelogs grouped by Features and Fixes.
  * `audit_security_headers`: Inspects endpoints for missing CSP, HSTS, and dangerous `Access-Control-Allow-Origin: *` headers.
* **Dynamic Skill Dock (`DynamicSkillDock`)**:
  * Rendered directly above the chat composer. Clicking chips immediately enables or disables the skill and informs the agent's active tool registry.

---

## 💡 Example Prompts to Try

### 1. ⚡ SQL Query Optimization
```text
Activate the sql_optimizer skill and optimize this slow query:
SELECT * FROM orders WHERE customer_id = 42 ORDER BY created_at DESC;
```
> **What to look for**:
> - The agent activates `sql_optimizer` (or you can click the chip in the dock).
> - It executes `explain_sql_query` and suggests `CREATE INDEX idx_orders_created_at ON orders(created_at DESC);` with an estimated 18x speedup.

### 2. 🛡️ API Security & Header Audit
```text
Activate the security_auditor skill and audit https://api.mcp-store.internal for CORS and CSP vulnerabilities.
```
> **What to look for**:
> - The agent activates `security_auditor` and invokes `audit_security_headers`.
> - Highlights missing Content-Security-Policy and warns about wildcard CORS on authenticated routes.

### 3. 📦 Automated Release Notes
```text
Activate the release_manager skill and compile release notes for version 1.3.0.
```

---

## 🚀 Running the Example

```bash
cd examples/flutter/example_dynamic_skills
flutter pub get
flutter run -d windows
```

Configure your API key in `../../.env` or directly through the in-app settings drawer.

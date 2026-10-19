# Sub-Agent Orchestrator Showcase

A working Flutter application demonstrating **Autonomous Sub-Agent Delegation (`DelegateTaskTool`)** with real-time UI execution visualization and streaming telemetry.

---

## 🔌 Where Does the Data Come From?

* **In-Process Dart Tools (`lib/tools.dart`)**:
  * `inspect_code_module`: Simulates a codebase inspection tool returning real Dart/YAML source code files (`lib/auth/jwt_service.dart`, `lib/billing/payment_processor.dart`, and `config/db_pool.yaml`) with real architectural bugs (e.g. missing Redis token revocation, transaction deadlocks, unbounded statement timeouts).
  * `check_dependency_vulnerabilities`: Simulates a package security auditor returning real CVE records (`CVE-2025-2410`, `CVE-2025-1892`) with severity ratings and fixed version paths.
  * `query_telemetry_metrics`: Simulates a Datadog/Prometheus metrics service returning live RPS, p50/p95/p99 latency spikes (892ms), and database pool saturation (94%).
* **The AI Model**: Connects to your configured LLM (OpenAI, Claude, Gemini, Ollama, or embedded GGUF) via the credentials in `.env` or the in-app settings drawer.
* **Autonomous Execution Loop**: When the primary agent calls `delegate_task`, an independent child `McpAgentEngine` is spawned in Flutter. Its step logs stream into `SubAgentExecution` and render real-time execution cards in `ChatBubble`.

---

## 💡 Example Prompts to Try

Copy and paste any of these prompts into the chat input:

### 1. 🔍 Full Technical & Security Audit (Spawns 2 Sub-Agents)
```text
Please conduct a comprehensive review of our payment infrastructure. Delegate the security vulnerability and auth code audit to a Security Specialist, and delegate the high p99 latency investigation to a Performance Engineer. Then synthesize the findings into a clear executive summary.
```
> **What to look for**:
> - The orchestrator invokes `delegate_task` twice.
> - Two distinct **Sub-Agent Execution Cards** render live in the chat showing progress spinners, child tool logs, and results.
> - The primary agent synthesizes both reports into a final remediation plan.

### 2. ⚡ Database Pool Saturation & Deadlock Investigation
```text
Our telemetry shows 94% DB pool saturation and spiking p99 latency. Delegate code inspection of db_pool.yaml and payment_processor.dart to a Database sub-agent and explain how to eliminate potential deadlocks.
```
> **What to look for**:
> - A child agent specifically investigates the database configuration and payment transaction code, identifying deadlock conditions in `payment_processor.dart`.

### 3. 🛡️ CVE Security Sweep
```text
Delegate a full security audit to a Security Analyst sub-agent to check all installed third-party packages for CVEs and inspect our authentication module.
```

---

## 🚀 Running the Example

```bash
cd examples/flutter/example_subagents_orchestrator
flutter pub get
flutter run -d windows
```

Configure your API key in `../../.env` or directly through the in-app settings drawer (gear icon in the top right).

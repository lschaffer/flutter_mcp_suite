# Episodic Memory Archive & Retrieval Showcase

A Flutter application showcasing **Long-Term Episodic Memory (`EpisodicMemoryStore`)**, memory compression, and autonomous recall via the `retrieve_memory` tool.

---

## 🔌 Where Does the Data Come From?

* **Pre-Seeded Historical Memories (`lib/main.dart`)**:
  * In `_preseedHistoricalMemories()`, three realistic Architectural Decision Records (ADRs) are loaded into `controller.episodicMemoryStore`:
    1. **Sprint 12 (90 days ago)**: Why the team moved from stateless JWTs to Redis session tokens (instant token revocation).
    2. **Sprint 14 (60 days ago)**: Why PostgreSQL connection pool was capped at 25 (AWS RDS CPU saturation and p99 reduction).
    3. **Sprint 18 (25 days ago)**: Why on-device GGUF models were adopted via `llamadart` (offline field inspections without data roaming costs).
* **The Retrieval Tool (`retrieve_memory`)**:
  * Built into `PlaygroundController` / `dart_mcp_core`. It searches the compressed episodic memory store using semantic matching and keyword tags.
* **The Storage Tool (`record_milestone`)**:
  * Defined in `lib/tools.dart`. When invoked, it writes new milestone entries into episodic memory so the agent retains them throughout future turns.

---

## 💡 Example Prompts to Try

### 1. 🔑 Recalling Past Architectural Decisions
```text
Why did our team decide to migrate away from stateless JWTs in Sprint 12? Please query the episodic memory archive.
```
> **What to look for**:
> - The agent invokes the `retrieve_memory` tool with query terms `"JWT"`, `"auth"`, or `"Sprint 12"`.
> - A specialized Memory Retrieval card appears in the chat.
> - The agent cites the exact rationale (instant revocation for permission updates).

### 2. 🗄️ Database Sizing Investigation
```text
What connection pool size was chosen for PostgreSQL in Sprint 14, and what was the performance consequence?
```
> **What to look for**:
> - The agent retrieves the Sprint 14 ADR and explains the 25-connection limit and the 42% p99 latency improvement.

### 3. 📝 Writing a New Milestone to Memory
```text
We have finalized Sprint 22: We decided to use Protobuf over gRPC instead of REST JSON for all internal microservices to reduce bandwidth by 65%. Record this decision in our project records.
```
> **What to look for**:
> - The agent calls `record_milestone` with the title, rationale, and tags.
> - Click the **Memories (3)** button in the top AppBar — you will see the memory count increase to **4**, and your new entry appears in the `MemoryArchiveDialog`!

---

## 🚀 Running the Example

```bash
cd examples/flutter/example_episodic_memory
flutter pub get
flutter run -d windows
```

Configure your API key in `../../.env` or directly through the in-app settings drawer.

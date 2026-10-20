# GenUI Model & Prompt Benchmark Lab

Demonstrates how AI agents evaluate LLM prompt performance across multiple models, calculating latency, accuracy, token throughput, and monetary cost using `flutter_genui_mcp`, `flutter_ui_mcp_core`, and the new **`ModelPricingService`**.

Developers and AI researchers can evaluate prompts against candidate models and dynamically stream interactive GenUI widgets:
- **`BenchmarkScorecard`**: Executive scoreboard highlighting top accuracy percentage, average latency in milliseconds, Pareto-optimal winner badge, and percentage savings.
- **`RadarQualityChart`**: Visual criterion breakdown showing instruction following, conciseness, and hallucination resistance bars.
- **`LatencyCostScatter`**: Bar visual comparing end-to-end response speeds in milliseconds.

## Features
- **Multi-Model Quality Benchmarking**: Measures accuracy and instruction adherence across frontier and open-weights models.
- **Pareto Trade-Off Evaluation**: Identifies the sweet spot balancing quality, latency, and token expenditure.
- **Agent Inspector Integration**: Inspect real-time tokens, costs, and execution traces with the top action bar toggle.

## 🧠 Agent Skill (`skill.md`)
This directory contains a pre-configured [`skill.md`](skill.md) file adhering to the AgentSkills.io standard.

You can either:
1. **Load the Skill**: In the application, click **Skills** &rarr; **Import Skill** and select [`skill.md`](skill.md). The playground will automatically configure the benchmark copilot system prompt, enable evaluation tools, and prepare sample prompt queries.
2. **Manual Prompts**: Or enter the prompts below directly.

## 💡 Example Prompts
Try asking the assistant:
- *"Benchmark our JSON entity extraction prompt against Claude 3.7 Sonnet, o3-mini, DeepSeek Chat, and Gemini 3.7 Flash."*
- *"Evaluate the Pareto trade-offs focusing on cost-efficiency and recommend the winning model."*

## Running
```bash
cd examples/genui/example_genui_benchmark_lab
flutter pub get
flutter run -d windows # or -d chrome
```

# GenUI Model Cost & Architecture Optimizer

Demonstrates how AI agents design cost-effective LLM architectures, query dynamic token rates, and render interactive GenUI cost visualizers using `flutter_genui_mcp`, `flutter_ui_mcp_core`, and the new **`ModelPricingService`**.

Developers and architects can explore LLM pricing, simulate token burn rates across request volumes, and dynamically stream interactive GenUI widgets:
- **`ModelComparisonMatrix`**: Side-by-side model cards displaying prompt/completion pricing in USD & EUR, maximum context windows (e.g. 128k, 1M), and local/cloud zero-rate badges.
- **`CostProjectionChart`**: Interactive `fl_chart` multi-series curve projecting monthly expenditure at 10k, 25k, 50k, and 100k query volumes.
- **`ModelRoutingCard`**: Visual tiered architecture recommendation with traffic allocation bars and estimated monthly savings percentage vs. pure frontier models.
- **`BudgetThresholdBanner`**: Contextual budget compliance alerts indicating whether projected spend fits within allocated targets.

## Features
- **Dynamic Pricing Integration**: Leverages `ModelPricingService` for live rates and context limits without static tables.
- **Agent Inspector Integration**: Inspect live token consumption, costs, and tool call traces with the built-in top action bar toggle.
- **Multi-Model Simulation**: Simulates blended costs across OpenAI, Anthropic, Gemini, DeepSeek, and local Ollama.
- **Interactive GenUI Components**: Renders native Flutter widgets directly from structured agent responses.

## 🧠 Agent Skill (`skill.md`)
This directory contains a pre-configured [`skill.md`](skill.md) file adhering to the AgentSkills.io standard.

You can either:
1. **Load the Skill**: In the application, click **Skills** &rarr; **Import Skill** and select [`skill.md`](skill.md). The playground will automatically configure the cloud architecture system prompt, enable pricing tools, and prepare sample prompt queries.
2. **Manual Prompts**: Or enter the prompts below directly.

## 💡 Example Prompts
Try asking the assistant:
- *"Compare current pricing, context limits, and token costs for o3-mini, Claude 3.7 Sonnet, DeepSeek Chat, Gemini 3.7 Flash, and local Llama 3.3."*
- *"Simulate our monthly cost for 100,000 queries with 1,800 prompt tokens and 400 completion tokens per query, and show a cost curve chart."*
- *"We are building an enterprise customer support copilot with a $250 monthly budget. Recommend an optimal tiered multi-model routing architecture."*

## Running
```bash
cd examples/genui/example_genui_model_optimizer
flutter pub get
flutter run -d windows # or -d chrome
```

> **Note**: Verify that custom tools (`query_model_pricing`, `simulate_workload`, `recommend_model_routing`) are enabled in the **Tools** drawer / panel, or import [`skill.md`](skill.md) to activate them automatically.

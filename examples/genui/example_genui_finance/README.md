# GenUI Personal Finance & Budget Planner (Generative UI Example)

Demonstrates how AI agents render interactive financial planning widgets and invoke **GenUI Client-Side Functions** inside `GenuiMcpPlayground`.

Instead of making slow round-trips to an external MCP server or LLM tool-calling loop for deterministic math, this example utilizes **[A2UI Client-Side Functions](https://flutter.dev/blog/a2ui-client-side-functions)** running directly and synchronously in Dart on the user's device:
- **`getMonthlyExpenses`**: Fetches the deterministic monthly category spending and gross income snapshot.
- **`calculateBudgetSavings`**: Calculates instant monthly savings, annual savings, and savings rate.
- **`simulateInvestmentGrowth`**: Deterministically projects compound interest returns over 1, 3, 5, and 10 years.

The model orchestrates and generates rich interactive GenUI components:
- **ExpensePieChart**: Visual breakdown of spending by category using `fl_chart`.
- **BudgetSliders**: Interactive sliders allowing the user to tweak category spending in real-time, calculating instant projected annual savings.
- **InvestmentGrowthCard**: Multi-year compound interest milestone projections with visual indicators, progress bars, and total interest earned.

## Features
- Dynamic financial widget generation using GenUI (`A2UI`)
- Native client-side functions (`SynchronousClientFunction`) for instant deterministic calculations without server round-trips
- FlChart pie chart visualization
- Real-time interactive client-side calculation sliders

## 🚀 Client-Side Functions (`SynchronousClientFunction`)
As described in the [Flutter official blog](https://flutter.dev/blog/a2ui-client-side-functions), client-side functions enable AI agents to delegate arithmetic and deterministic operations directly to Dart code running locally on the user's device.

Benefits:
- **Zero Latency**: Executed synchronously on-device with no network round-trips.
- **100% Accuracy**: Eliminates LLM calculation hallucinations for financial math.
- **Token Efficiency**: Saves LLM tokens by keeping straightforward computations local.

## 🧠 Agent Skill (`skill.md`)
This directory contains a pre-configured [`skill.md`](skill.md) file defining the GenUI personal finance workflow and system prompt according to the AgentSkills.io standard.

You can either:
1. **Load the Skill**: In the application, click **Skills** &rarr; **Import Skill** and select [`skill.md`](skill.md). The playground will automatically configure the finance advisor system prompt and prepare the multi-step prompt sequence.
2. **Manual Prompts**: Or enter the example system prompt and user prompts below directly.

## ⚙️ Example System Prompt
```
You are an expert personal finance and investment AI advisor.
When the user asks for budget reviews, spending analysis, or investment projections:
1. Leverage client-side functions directly for instant, deterministic computations without server round-trips:
   - `getMonthlyExpenses()`: Retrieve expense records and default income.
   - `calculateBudgetSavings(monthly_income, monthly_expenses)`: Calculate live savings and annual projections.
   - `simulateInvestmentGrowth(monthly_contribution, annual_interest_rate)`: Compute multi-year compound interest.
2. Generate interactive GenUI components:
   - "ExpensePieChart" to visualize current expenses (categories with name and amount)
   - "BudgetSliders" for interactive budget planning (categories with name, amount, max_amount)
```

## 💡 Example Prompts
Try asking the assistant:
- *"Break down my monthly expenses and display an interactive category pie chart."*
- *"Provide budget adjustment sliders so I can see my projected annual savings in real time."*
- *"Simulate compounding returns if I invest $450/month at 7.5% annual return over 10 years."*

## Running
```bash
cd examples/genui/example_genui_finance
flutter pub get
flutter run -d windows # or -d chrome
```

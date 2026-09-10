# GenUI Personal Finance & Budget Planner (Generative UI Example)

Demonstrates how AI agents render interactive financial planning widgets inside `GenuiMcpPlayground`.
Users can ask for monthly budget analysis or savings optimization; the model executes financial MCP tools and renders dynamic generative UI widgets:
- **ExpensePieChart**: Visual breakdown of spending by category using `fl_chart`.
- **BudgetSliders**: Interactive sliders allowing the user to tweak category spending in real-time, calculating instant projected annual savings.

## Features
- Dynamic financial widget generation using GenUI
- FlChart pie chart visualization
- Real-time interactive client-side calculation sliders
- Finance simulation MCP tools

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

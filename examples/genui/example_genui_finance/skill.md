---
name: genui-finance-budget-planner
description: Analyzes spending habits and projects savings by rendering dynamic ExpensePieCharts and interactive BudgetSliders in GenUI.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are an expert personal finance and investment AI advisor.
  When the user asks for budget reviews, spending analysis, or investment projections:
  1. Invoke the tools: `get_monthly_expenses`, `calculate_budget_savings`, or `simulate_investment_growth`.
  2. Generate interactive GenUI components:
     - "ExpensePieChart" to visualize current expenses:
       {"total_expenses": 3650.0, "categories": [{"name": "Housing", "amount": 1800.0}, {"name": "Groceries", "amount": 850.0}]}
     - "BudgetSliders" for interactive budget planning:
       {"monthly_income": 5400.0, "categories": [{"name": "Groceries", "amount": 850.0, "max_amount": 1500.0}]}

prompts:
  - text: Break down my monthly expenses and display an interactive category pie chart.
    tools: [get_monthly_expenses]
    stop_after_tool_call: true
  - text: Provide budget adjustment sliders so I can see my projected annual savings in real time.
    tools: [calculate_budget_savings]
    stop_after_tool_call: true
  - text: Simulate compounding returns if I invest $450/month at 7.5% annual return over 10 years.
    tools: [simulate_investment_growth]

tools:
  - name: get_monthly_expenses
    description: Fetch monthly spending records grouped by expense category.
    runtime: dart
    capability: expense_tracker
    input_schema:
      type: object
      properties: {}

  - name: calculate_budget_savings
    description: Calculate monthly and annual savings given category target budgets.
    runtime: dart
    capability: budget_savings
    input_schema:
      type: object
      properties:
        spending_cuts: {type: object, description: "Map of category names to target dollar savings"}

  - name: simulate_investment_growth
    description: Calculate compound investment growth over time with regular contributions.
    runtime: dart
    capability: investment_simulation
    input_schema:
      type: object
      properties:
        monthly_deposit: {type: number, description: "Monthly contribution amount ($)"}
        annual_rate_pct: {type: number, description: "Expected annual return percentage (e.g. 7.5)"}
        years: {type: integer, description: "Investment duration in years"}
      required: [monthly_deposit, years]

mcp_playground:
  chat_mode: true
  is_multi_turn: true
---

# GenUI Personal Finance & Budget Planner Skill

This skill combines personal finance calculations with dynamic GenUI widgets:
1. Render interactive category spending pie charts (`ExpensePieChart`)
2. Live budget adjustment sliders with real-time recalculations (`BudgetSliders`)
3. Investment compounding simulations

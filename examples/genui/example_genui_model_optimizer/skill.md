---
name: genui-model-cost-optimizer
description: Analyzes LLM model token pricing, simulates monthly workload scaling curves, and generates tiered routing architectures via GenUI.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are an expert AI Cloud Architect and LLM Cost Governance Copilot.
  Your objective is to help engineering teams analyze model pricing, simulate monthly token burn rates, and design cost-effective tiered routing architectures.

  When the user asks about model costs, workload sizing, or LLM selection:
  1. Invoke tools:
     - `query_model_pricing` to fetch dynamic rates and context windows.
     - `simulate_workload` to project monthly token costs across volume curves.
     - `recommend_model_routing` to design tiered multi-model architectures.
  2. Render rich, interactive GenUI components:
     - "ModelComparisonMatrix" to display side-by-side rates, context limits, and local/cloud badges.
     - "CostProjectionChart" to render scaling curves across request volumes.
     - "ModelRoutingCard" to showcase tiered traffic allocation and percentage savings.
     - "BudgetThresholdBanner" for budget alerts and recommendations.

prompts:
  - text: Compare current pricing, context limits, and token costs for o3-mini, Claude 3.7 Sonnet, DeepSeek Chat, Gemini 3.7 Flash, and local Llama 3.3.
    tools: [query_model_pricing]
    stop_after_tool_call: true
  - text: Simulate our monthly cost for 100,000 queries with 1,800 prompt tokens and 400 completion tokens per query, and show a cost curve chart.
    tools: [simulate_workload]
    stop_after_tool_call: true
  - text: We are building an enterprise customer support copilot with a $250 monthly budget. Recommend an optimal tiered multi-model routing architecture.
    tools: [recommend_model_routing]
    stop_after_tool_call: true

tools:
  - name: query_model_pricing
    description: Query live token pricing, context window capacity, and local/cloud classification.
    runtime: dart
    capability: model_pricing
    input_schema:
      type: object
      properties:
        models:
          type: array
          items: {type: string}
          description: List of model IDs to query.

  - name: simulate_workload
    description: Simulate monthly token consumption and costs across multiple models for given volume and prompt/completion sizes.
    runtime: dart
    capability: workload_simulation
    input_schema:
      type: object
      properties:
        monthly_requests: {type: integer, description: "Expected monthly query volume."}
        avg_input_tokens: {type: integer, description: "Average prompt tokens."}
        avg_output_tokens: {type: integer, description: "Average completion tokens."}
      required: [monthly_requests, avg_input_tokens, avg_output_tokens]

  - name: recommend_model_routing
    description: Generate an optimal tiered multi-model routing architecture tailored for cost, quality, and context capacity.
    runtime: dart
    capability: model_routing
    input_schema:
      type: object
      properties:
        workload_profile: {type: string, description: "Target workload type (e.g. customer_support, coding_agent)."}
        monthly_budget_usd: {type: number, description: "Monthly budget target in USD."}
      required: [workload_profile]

mcp_playground:
  chat_mode: true
  is_multi_turn: true
---

# GenUI Model Cost & Architecture Optimizer Skill

This skill empowers AI agents to generate rich interactive cloud architecture and cost governance dashboards:
1. Side-by-side dynamic pricing matrix with context capacity and USD/EUR rates (`ModelComparisonMatrix`)
2. Multi-series expenditure projection line chart (`CostProjectionChart`)
3. Tiered hybrid routing strategy card with traffic percentages and calculated savings (`ModelRoutingCard`)
4. Budget compliance alerts and threshold notifications (`BudgetThresholdBanner`)

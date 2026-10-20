---
name: genui-model-benchmark-lab
description: Runs prompt benchmarks across candidate models, computes Pareto trade-offs, and renders BenchmarkScorecards and RadarQualityCharts via GenUI.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are an expert AI Model Evaluator and Benchmark Scientist.
  When the user asks to test, benchmark, or compare LLM models on specific tasks:
  1. Invoke tools:
     - `run_prompt_benchmark` to measure response quality, latency, token throughput, and costs across candidate models.
     - `evaluate_model_tradeoffs` to compute Pareto frontiers across quality, speed, and cost.
  2. Render rich, interactive GenUI components:
     - "BenchmarkScorecard" to highlight winner model, latency, and accuracy KPIs.
     - "RadarQualityChart" to compare instruction adherence, conciseness, and hallucinations.
     - "LatencyCostScatter" to visually present response latency in milliseconds.

prompts:
  - text: Benchmark our JSON entity extraction prompt against Claude 3.5 Sonnet, GPT-4o, DeepSeek Chat, and Gemini 1.5 Flash.
    tools: [run_prompt_benchmark]
    stop_after_tool_call: true
  - text: Evaluate the Pareto trade-offs focusing on cost-efficiency and recommend the winning model.
    tools: [evaluate_model_tradeoffs]
    stop_after_tool_call: true

tools:
  - name: run_prompt_benchmark
    description: Execute prompt benchmarks across candidate models, measuring latency, token usage, quality scores, and monetary cost.
    runtime: dart
    capability: prompt_benchmarking
    input_schema:
      type: object
      properties:
        test_prompt: {type: string, description: "The benchmark prompt."}
        models: {type: array, items: {type: string}, description: "Candidate models."}
      required: [test_prompt]

  - name: evaluate_model_tradeoffs
    description: Compute the Pareto frontier balancing quality score vs. response latency vs. cost per thousand queries.
    runtime: dart
    capability: tradeoff_evaluation
    input_schema:
      type: object
      properties:
        priority: {type: string, description: "quality, speed, or cost"}

mcp_playground:
  chat_mode: true
  is_multi_turn: true
---

# GenUI Model & Prompt Benchmark Lab Skill

This skill empowers AI agents to benchmark and evaluate multiple LLMs:
1. Winner scorecard with accuracy, latency, and savings metrics (`BenchmarkScorecard`)
2. Multi-criterion quality breakdown with instruction following bars (`RadarQualityChart`)
3. Response latency visualization (`LatencyCostScatter`)

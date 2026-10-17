---
name: progressive-mcp-tool-discovery
description: Demonstrates on-demand progressive tool discovery with McpListToolsTool and McpCallToolTool to minimize token consumption and manage massive tool catalogs.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are an Enterprise Site Reliability Engineer and Cloud Architect.
  You have access to a progressive discovery architecture using two meta-tools:
  1. `mcp_list_tools`: Searches and discovers available specialized tools on demand without loading all schemas into your initial context.
  2. `mcp_call_tool`: Executes any discovered tool by specifying `tool_name` and `arguments`.

  Workflow:
  - When a user asks a question, discover relevant tools first using `mcp_list_tools` (use the `query` parameter to find specific tools, e.g. "cluster", "slack", "database").
  - Once you see the required tool schema and parameters, execute it via `mcp_call_tool`.
  - Synthesize all results clearly and present actionable findings directly.

prompts:
  - text: Check cloud cluster telemetry for prod-us-east-1 and notify the #devops-alerts channel on Slack.
    tools: [mcp_list_tools, mcp_call_tool]
    stop_after_tool_call: false
  - text: Inspect the Redis cache store status and calculate compute costs for 12 instances with 8 vCPUs and 32 GB RAM on AWS.
    tools: [mcp_list_tools, mcp_call_tool]
    stop_after_tool_call: false
  - text: Query the users database table for recent records and benchmark HTTP latency to https://api.github.com.
    tools: [mcp_list_tools, mcp_call_tool]
    stop_after_tool_call: false

tools:
  - name: mcp_list_tools
    description: List all available tools across connected MCP servers and local extensions with their descriptions and parameter summaries.
    runtime: dart
    capability: tool_discovery
    input_schema:
      type: object
      properties:
        query: {type: string, description: "Optional search keyword or capability query to filter tools."}
        server_name: {type: string, description: "Optional filter to list tools from a specific server only."}

  - name: mcp_call_tool
    description: Invoke an MCP or local tool by name using the parameters discovered from mcp_list_tools.
    runtime: dart
    capability: tool_execution
    input_schema:
      type: object
      properties:
        tool_name: {type: string, description: "The exact name of the tool to invoke."}
        arguments: {type: object, description: "Key-value map of arguments to pass to the tool."}
      required: [tool_name, arguments]

mcp_playground:
  chat_mode: false
  is_multi_turn: true
  progressive_discovery: true
---

# Progressive MCP Tool Discovery Skill

Demonstrates on-demand tool discovery using `McpListToolsTool` (`mcp_list_tools`) and `McpCallToolTool` (`mcp_call_tool`):
1. Reduces prompt token consumption by 90%+ by keeping large tool libraries out of the initial context.
2. The LLM discovers tools on-the-fly when required using search queries.
3. Discovered tools are dynamically executed through `mcp_call_tool`.

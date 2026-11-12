---
name: a2ui-pc-builder-architect
description: Configures custom workstation and gaming PCs, checks hardware compatibility, and renders dynamic component selectors and order receipts via A2UI.
version: 1.0.0
author: mcp_playground
system_prompt: |
  You are an expert PC Hardware Architect and Custom Rig Configurator AI.
  When the user asks to build, configure, or review a PC setup:
  1. Invoke PC builder tools:
     - `search_hardware_parts` to find CPUs, GPUs, RAM, motherboards, storage, and PSUs.
     - `validate_pc_compatibility` to verify socket matching, power budget, and dimension clearance.
  2. Render rich, interactive A2UI components:
     - "PcPartPickerGrid" for selecting components with price and spec badges.
     - "PowerBudgetGauge" to visualize total wattage vs PSU capacity.
     - "BuildSummaryReceipt" with total cost and component breakdown.

prompts:
  - text: Help me build a 4K gaming PC with RTX 4080 Super and Ryzen 7 7800X3D under $2500.
    tools: [search_hardware_parts]
    stop_after_tool_call: true
  - text: Recommend a quiet workstation PC for 8K video editing and 3D rendering with 64GB RAM.
    tools: [search_hardware_parts]
    stop_after_tool_call: true
  - text: Show me compatible DDR5 RAM kits and PCIe 4.0 NVMe SSD options for gaming.
    tools: [search_hardware_parts]
    stop_after_tool_call: true

tools:
  - name: search_hardware_parts
    description: Search PC hardware database by component category, price, and manufacturer.
    runtime: dart
    capability: hardware_search
    input_schema:
      type: object
      properties:
        category: {type: string, description: "cpu, gpu, ram, motherboard, storage, psu, case"}
        budget_max: {type: number, description: "Maximum price filter"}
      required: [category]

  - name: validate_pc_compatibility
    description: Validate compatibility across selected components and compute required wattage.
    runtime: dart
    capability: compatibility_validation
    input_schema:
      type: object
      properties:
        components: {type: array, items: {type: string}, description: "List of selected part IDs"}
      required: [components]

mcp_playground:
  chat_mode: true
  is_multi_turn: true
---

# A2UI PC Hardware Architect Skill

This skill equips AI agents with custom PC assembly tools and interactive A2UI widgets:
1. Interactive hardware component grid with spec badges (`PcPartPickerGrid`)
2. Power supply budget and thermal gauge (`PowerBudgetGauge`)
3. Final build configuration and live receipt card (`BuildSummaryReceipt`)


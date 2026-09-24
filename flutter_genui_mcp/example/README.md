# GenUI Travel & Accommodation Planner Showcase

The primary example application for **`flutter_genui_mcp`**, demonstrating interactive generative UI powered by the `genui` (`A2UI`) protocol, local Dart MCP tools, and web search integration via SerpAPI.

---

## ✨ Features

- **Interactive Stay & Trip Finder (`TravelSearchForm`)**: Live destination autocomplete, interactive date range picker, accommodation type chips (hotel, apartment, camping/glamping, resort, hostel), and budget style selectors.
- **SerpAPI Travel Search Tool (`search_travel_destinations`)**: Searches the web for accommodations, verified star ratings, reviews, photos, addresses, pricing, and direct booking links. Curated fallback dataset is included when running without an API key.
- **Rich Stay Cards (`AccommodationGrid`)**: High-res photo cards with amenity badges, rating stars, pricing tags, and external link launchers.
- **Day-by-Day Itinerary Timeline (`TravelItineraryCard`)**: Curated morning, afternoon, and evening activity schedules with a direct **Export to JPG** image button.
- **Side-by-Side Agent Inspector**: Inspect live system prompts, tool call executions, JSON payloads, and multimodal attachments.

---

## 🚀 Running the Example

Make sure dependencies are resolved and your `.env` is configured (optional `SERPAPI_KEY`, `LLM_PROVIDER`, `LLM_API_KEY`):

```bash
cd genui_mcp_playground/example
flutter pub get
flutter run -d windows # or macos / linux / chrome
```

---

## 📂 Other GenUI Examples

- **[`examples/genui/example_genui_pc_builder`](../../examples/genui/example_genui_pc_builder)** – Custom PC Rig Builder & Hardware Store with platform pickers (AM5/LGA1700), product catalog grids, and order checkout.
- **[`examples/genui/example_genui_weather`](../../examples/genui/example_genui_weather)** – Dynamic weather forecast generator with `fl_chart` multi-line graphs and JPG export.
- **[`examples/genui/example_genui_finance`](../../examples/genui/example_genui_finance)** – Financial portfolio and budget planner with compound interest curves and expense pie charts.
- **[`examples/genui/example_genui_smarthome`](../../examples/genui/example_genui_smarthome)** – Smart home climate and energy studio with interactive thermostats.
- **[`examples/genui/example_genui_data_studio`](../../examples/genui/example_genui_data_studio)** – Data visualizer & query studio with KPI metric cards and tables.
- **[`examples/genui/example_genui_filesystem`](../../examples/genui/example_genui_filesystem)** – Interactive filesystem explorer with folder tree navigation and file content viewer.

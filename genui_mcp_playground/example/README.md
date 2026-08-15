# GenUI Travel & Accommodation Planner Showcase

The primary example application for **`genui_mcp_playground`**, demonstrating interactive generative UI powered by the `genui` (`A2UI`) protocol, local Dart MCP tools, and web search integration via SerpAPI.

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

- **[`examples/genui/example_genui_weather`](../../examples/genui/example_genui_weather)** – Dynamic weather forecast generator with `fl_chart` multi-line graphs and JPG export.
- **[`examples/genui/example_genui_filesystem`](../../examples/genui/example_genui_filesystem)** – Interactive filesystem explorer with folder tree navigation and file content viewer.

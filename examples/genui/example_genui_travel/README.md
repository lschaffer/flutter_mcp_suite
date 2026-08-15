# GenUI Travel & Accommodation Planner (`example_genui_travel`)

An interactive Flutter GenUI example that searches for accommodations (hotels, apartments, glamping, hostels) using **SerpAPI** and generates dynamic, responsive UI cards and exportable itineraries.

---

## Features

- **Interactive Travel Form Widget (`travel_search_form`)**:
  - Destination input with quick chips (*Kyoto, Barcelona, Zermatt, Banff, Cape Town, Maui*).
  - Date range picker (start and end dates).
  - Accommodation type selector: 🏨 Hotel, 🏢 Apartment, ⛺ Camping & Glamping, 🏖️ Resort & Spa, 🎒 Hostel.
  - Budget preference selector: *Budget Friendly*, *Moderate*, *Luxury & Premium*.
- **Live SerpAPI Search Tool (`search_travel_destinations`)**:
  - Automatically queries Google via SerpAPI using `SERPAPI_KEY` defined in `.env`.
  - Extracts real hotel/stay ratings, reviews, photos, prices, addresses, and booking URLs.
  - Fallback curated dataset if no API key is provided.
- **Dynamic GenUI Output Widgets**:
  - **`accommodation_grid`**: Multi-card stay browser with photos, ratings, amenity badges, and "View & Book" links.
  - **`travel_itinerary_card`**: Day-by-day travel timeline with activity schedules and built-in **Export to JPG** graphic feature.
- **Windows 11 Fluent Ocean Breeze Theme**:
  - Styled with Fluent Coastal Azure palette (`Color(0xFF0078D4)`).

---

## Configuration

Add your `SERPAPI_KEY` to `.env` in the root or `examples/genui/`:

```env
SERPAPI_KEY=your_serpapi_key_here
LLM_PROVIDER=mistral
LLM_MODEL=mistral-medium-latest
LLM_API_KEY=your_mistral_api_key
```

---

## Running the Example

```bash
cd examples/genui/example_genui_travel
flutter run -d windows
```

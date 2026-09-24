# AI Custom PC Rig Builder & Hardware Store Example

A production-ready **GenUI & Agentic MCP** showcase demonstrating an interactive custom PC builder, hardware component catalog, compatibility checker, and order checkout flow.

---

## ✨ Features

- **Interactive PC Builder Configurator (`PcBuildForm`)**: Material 3 segmented platform selectors (`AMD AM5` vs `Intel LGA1700`), budget sliders (\$800 – \$4,000), and use-case chips.
- **Product Catalog Surfaces (`ProductCatalogGrid`)**: Rich responsive cards with real hardware specs, ratings, product photos, prices, and one-click selection.
- **Order Cart & Invoicing (`PcOrderSummaryCard`)**: Itemized part lists, dynamic tax and shipping calculations, and integrated customer checkout form.
- **Order Verification & Tracking (`OrderReceiptCard`)**: Verified order confirmation cards with unique order IDs and shipment tracking details.
- **Dart-Native MCP Tools**:
  - `search_pc_hardware(category, query, maxPrice)`
  - `submit_pc_order(customerName, email, shippingAddress, itemIds)`

---

## 🚀 Running the Example

```bash
flutter pub get
flutter run -d windows # Or macos, linux, chrome
```

---

## 💡 Example Prompts

- *"I want to build a high-performance 1440p gaming PC with AMD AM5 under $2000. Recommend parts from the store."*
- *"Show me all available graphics cards in the inventory."*
- *"Assemble a complete Intel workstation build for 3D rendering and prepare the checkout order."*

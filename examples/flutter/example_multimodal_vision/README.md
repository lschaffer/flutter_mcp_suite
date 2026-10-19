# Multimodal Media Studio Showcase

A Flutter application showcasing **Multimodal Media Analysis (`ChatContentPart`)**, inline attachment previews, full-resolution image lightboxes, and document/audio inspection.

---

## 🔌 Where Does the Data Come From?

* **Sample Checkout Wireframe Image (`assets/sample_checkout_ui.jpg`)**:
  * Realistic mobile checkout UI screenshot showing a payment summary card, credit card selector, and checkout button.
  * You can stage it directly via **+ UI Screenshot**, or click **Copy Image for Ctrl+V** and paste it into the prompt!
* **Clipboard Pasting (`Ctrl+V`)**:
  * Press **Ctrl+V** inside the prompt field or click the paste icon next to the attachment clip.
  * The prompt automatically extracts images (from Snipping Tool, PrtScn, browser copies) or copied documents/files from the Windows clipboard, downscales them to optimal inference sizes, and displays them as chips in the staged attachments bar.
* **Embedded Sample Data (`lib/main.dart`)**:
  * **ImagePart**: Includes high-resolution checkout UI wireframe image.
  * **DocumentPart**: Includes embedded markdown specification (`checkout_spec_v2.md`) defining button sizes, layout rows, and constraints.
  * **AudioPart**: Includes a valid base64 WAV sound clip representing a voice memo.
* **Diagnostics Tool (`lib/tools.dart`)**:
  * `analyze_ui_wireframe`: Simulates an automated UI accessibility & layout engine, returning `RenderFlex` overflow warnings, touch target heights (38dp vs recommended 48dp), and WCAG contrast ratings.
* **Interactive Lightbox**:
  * Clicking any image thumbnail inside a chat bubble opens a full-screen high-resolution lightbox modal.

---

## 💡 Example Prompts to Try

1. **Option A (Clipboard Paste)**: Copy an image to your clipboard (using Snipping Tool, PrtScn, or clicking **Copy Image for Ctrl+V**), then press **`Ctrl+V`** in the prompt box.
2. **Option B (Toolbar Quick Stage)**: Click the top **+ UI Screenshot** and **+ Spec Doc** buttons to stage sample media.

Then try:

### 1. 🖼️ Inspecting UI Layout & Overflow Defect
```text
Please analyze the staged UI screenshot and specification document. Check for RenderFlex overflow issues and execute analyze_ui_wireframe to report defect severity.
```
> **What to look for**:
> - The message renders with an inline image thumbnail and a file chip for `checkout_spec_v2.md`.
> - Tapping the image thumbnail opens the interactive fullscreen lightbox.
> - The agent executes `analyze_ui_wireframe` and reports the fix (wrapping in `Expanded` with `TextOverflow.ellipsis`).

### 2. ♿ Accessibility & Touch Target Audit
```text
Inspect our checkout UI button sizes and contrast against WCAG AA standards.
```

---

## 🚀 Running the Example

```bash
cd examples/flutter/example_multimodal_vision
flutter pub get
flutter run -d windows
```

Configure your API key in `../../.env` or directly through the in-app settings drawer.

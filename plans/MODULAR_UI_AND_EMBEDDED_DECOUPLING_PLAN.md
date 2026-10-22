# Modular UI & Embedded LLM Decoupling Implementation Plan

This plan outlines the architecture and execution steps to:
1. **Decouple `llamadart`** from `flutter_ui_mcp_core` and `flutter_ui_mcp` into an opt-in companion package (`flutter_ui_mcp_embedded`), removing heavy C++/WebGPU/FFI baggage for cloud-only users.
2. **Modularize the UI components** for external apps like `ai_grid` and `tealkit` (`mobile_ai_agent`):
   - Standalone chat prompt bar (`McpChatInputBar`) with attachment and clipboard support.
   - Standalone chat stream (`McpChatView`) without compulsory inspectors or AppBars.
   - Customizable TopBar builder (`topBarBuilder` / `appBarBuilder`).
   - Customizable Settings Dialog builder (`settingsDialogBuilder`).
   - First-class public helper functions to programmatically open settings, inspector, and tool dialogs.
3. **Upgrade examples** (e.g., `examples/flutter/example_embedded`), bump package versions to **`1.4.0`**, and update documentation and changelogs.

---

## 🗺️ Architectural Overview

```
                      ┌────────────────────────────────────────────────────────┐
                      │                       ai_grid                          │
                      │       (Uses ONLY McpChatInputBar & PlaygroundController)│
                      └───────────────────────────┬────────────────────────────┘
                                                  │
                      ┌───────────────────────────▼────────────────────────────┐
                      │                 mobile_ai_agent (tealkit)              │
                      │   (Uses McpPlayground with custom topBar & settings)   │
                      └───────────────────────────┬────────────────────────────┘
                                                  │
┌─────────────────────────────────────────────────┴────────────────────────────┐
│                              flutter_ui_mcp                                  │
│  - Full Playground widget with topBarBuilder & settingsDialogBuilder         │
│  - McpChatView (standalone chat list + input bar)                            │
│  - ZERO llamadart / C++ native build dependencies                            │
└─────────────────────────────────┬────────────────────────────────────────────┘
                                  │ depends on
┌─────────────────────────────────▼────────────────────────────────────────────┐
│                            flutter_ui_mcp_core                               │
│  - McpChatInputBar (modular prompt textfield, attachments, send, clipboard)  │
│  - SettingsPanel & AgentInspector widgets                                    │
│  - EmbeddedLlmDriver (abstract interface) & EmbeddedLlmRegistry              │
│  - Public helpers: showMcpSettingsDialog(), showMcpInspectorDialog()         │
│  - ZERO llamadart / C++ native build dependencies                            │
└─────────────────────────────────▲────────────────────────────────────────────┘
                                  │ implements EmbeddedLlmDriver
┌─────────────────────────────────┴────────────────────────────────────────────┐
│                          flutter_ui_mcp_embedded                             │
│                    (New Companion Package - Opt-In)                          │
│  - llamadart: ^0.11.1 (llama.cpp, WebGPU, WASM, FFI)                         │
│  - EmbeddedLlmAdapter implementing EmbeddedLlmDriver                         │
│  - FlutterUiMcpEmbedded.register()                                           │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Phase 1: Decouple Embedded LLM (`flutter_ui_mcp_core`)

### 1.1 Abstract Driver Interface & Registry
Define `EmbeddedLlmDriver` in `flutter_ui_mcp_core/lib/src/services/embedded_llm/embedded_llm_driver.dart`:
```dart
abstract class EmbeddedLlmDriver {
  bool get isLoaded;
  String? get loadedModelPath;

  Future<void> initialize(
    String modelPath, {
    int gpuLayers = 0,
    int contextSize = 4096,
    void Function(double progress)? onProgress,
  });

  Future<LLMResponse> generateResponse({
    required List<ChatMessage> messages,
    List<MCPTool> availableTools = const [],
    double? temperature,
    int? maxTokens,
    int? topK,
    double? topP,
    double? penalty,
    void Function(String chunk)? onStreamChunk,
  });

  Future<void> dispose();
}

class EmbeddedLlmRegistry {
  static EmbeddedLlmDriver? _driver;
  
  static EmbeddedLlmDriver? get driver => _driver;
  static bool get isAvailable => _driver != null;
  
  static void register(EmbeddedLlmDriver driver) {
    _driver = driver;
  }

  static void unregister() {
    _driver = null;
  }
}
```

### 1.2 Update Core Consumers
1. **`PlaygroundController`**:
   - In `LLMService.embeddedHandler` and `LLMService.embeddedStreamHandler`:
     - If `EmbeddedLlmRegistry.isAvailable`: delegate to `EmbeddedLlmRegistry.driver!.generateResponse(...)`.
     - Else: return descriptive error indicating `flutter_ui_mcp_embedded` is not registered.
2. **`EmbeddedModelPickerWidget`**:
   - Check `EmbeddedLlmRegistry.isAvailable`.
   - If driver is registered, display normal model selector, download bar, and GGUF runner.
   - If driver is NOT registered, display an informative fallback widget with an install banner:
     > *"Embedded GGUF models require `flutter_ui_mcp_embedded`. Add it to your pubspec.yaml and call `FlutterUiMcpEmbedded.register()`."*
3. **Remove `llamadart` from `flutter_ui_mcp_core/pubspec.yaml`**:
   - Remove `llamadart: ^0.11.1`.
   - Delete `flutter_ui_mcp_core/lib/src/services/embedded_llm/embedded_llm_adapter.dart` (moved to the new package).

---

## 🚀 Phase 2: Create Companion Package `flutter_ui_mcp_embedded`

### 2.1 Package Setup
Create `flutter_ui_mcp_embedded/` at repository root:
- `pubspec.yaml`:
  - `name: flutter_ui_mcp_embedded`
  - `version: 1.4.0`
  - Dependencies:
    - `flutter`
    - `dart_mcp_core: ^1.4.0`
    - `flutter_ui_mcp_core: ^1.4.0`
    - `llamadart: ^0.11.1`
- `lib/flutter_ui_mcp_embedded.dart`:
  - Exports `EmbeddedLlmAdapter`.
  - Static helper:
    ```dart
    class FlutterUiMcpEmbedded {
      static void register() {
        EmbeddedLlmRegistry.register(EmbeddedLlmAdapter.instance);
      }
    }
    ```
- `lib/src/embedded_llm_adapter.dart`:
  - Implements `EmbeddedLlmDriver`. Contains the proven GGUF/WebGPU/llama.cpp inference engine.

---

## 🎨 Phase 3: Modular UI Components & Input Line Extraction

Targeting use-cases like `ai_grid` and `tealkit`:

### 3.1 Standalone `McpChatInputBar` Widget
Extract the prompt textfield and action buttons into an independent widget in `flutter_ui_mcp_core`:
```dart
// flutter_ui_mcp_core/lib/src/widgets/mcp_chat_input_bar.dart
class McpChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isGenerating;
  final bool chatMode;
  final List<MessageAttachment> attachments;
  final VoidCallback onSend;
  final VoidCallback? onAttach;
  final VoidCallback? onPaste;
  final ValueChanged<List<MessageAttachment>>? onAttachmentsChanged;
  final String? hintText;
  final Widget? leading;
  final Widget? trailing;
  final List<ToolGroup>? availableToolGroups;
  final bool showSkillDock;
  final PlaygroundController? playgroundController;

  const McpChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.isGenerating = false,
    this.chatMode = false,
    this.attachments = const [],
    this.onAttach,
    this.onPaste,
    this.onAttachmentsChanged,
    this.hintText,
    this.leading,
    this.trailing,
    this.availableToolGroups,
    this.showSkillDock = false,
    this.playgroundController,
  });
  ...
}
```
*Benefits for `ai_grid`*: Can embed **just** `<McpChatInputBar controller={...} onSend={...} onAttach={...} />` into custom grid layouts with zero scaffolding.

### 3.2 Standalone `McpChatView`
Provide a clean chat view in `flutter_ui_mcp` combining message bubbles + input bar without requiring the two-pane inspector or scaffold AppBar:
```dart
class McpChatView extends StatelessWidget {
  final PlaygroundController controller;
  final MessageContentBuilder? messageContentBuilder;
  final Widget? customInputBar;
  final bool showInputBar;
  final ScrollController? scrollController;
  
  const McpChatView({
    super.key,
    required this.controller,
    this.messageContentBuilder,
    this.customInputBar,
    this.showInputBar = true,
    this.scrollController,
  });
}
```

---

## 🛠️ Phase 4: TopBar & Settings Dialog Builders

### 4.1 Custom TopBar / AppBar Builder in `McpPlayground`
Add `topBarBuilder` to `McpPlayground`:
```dart
typedef McpTopBarBuilder = PreferredSizeWidget Function(
  BuildContext context,
  PlaygroundController controller,
  McpTopBarActions defaultActions,
);

class McpTopBarActions {
  final VoidCallback openSettings;
  final VoidCallback openInspector;
  final VoidCallback openToolsCatalog;
  final VoidCallback newChat;
  final VoidCallback clearSession;
  final List<Widget> defaultActionWidgets;
}
```
If `topBarBuilder != null`, `McpPlayground` invokes this builder instead of the default `AppBar`, giving full control over titles, breadcrumbs, search bars, and menus for `tealkit`.

### 4.2 Custom Settings Dialog / Drawer Builder
Add `settingsDialogBuilder` to `McpPlayground` and `PlaygroundController`:
```dart
typedef McpSettingsBuilder = Widget Function(
  BuildContext context,
  PlaygroundController controller,
  int initialTabIndex,
  VoidCallback onClose,
);
```

### 4.3 Public Dialog Helper Functions & Controller Extensions
Expose standalone top-level and controller methods:
```dart
// Programmatically open settings dialog from anywhere
Future<void> showMcpSettingsDialog(
  BuildContext context,
  PlaygroundController controller, {
  int initialTab = 0,
  McpSettingsBuilder? customBuilder,
});

// Programmatically open inspector dialog from anywhere
Future<void> showMcpInspectorDialog(
  BuildContext context,
  PlaygroundController controller,
);

// On PlaygroundController:
extension McpDialogExtensions on PlaygroundController {
  void openSettings(BuildContext context, {int initialTab = 0}) =>
      showMcpSettingsDialog(context, this, initialTab: initialTab);

  void openInspector(BuildContext context) =>
      showMcpInspectorDialog(context, this);
}
```

---

## 📱 Phase 5: Upgrade Examples & Applications

1. **`examples/flutter/example_embedded`**:
   - Add `flutter_ui_mcp_embedded` to `pubspec.yaml`.
   - Call `FlutterUiMcpEmbedded.register();` in `main()`.
2. **`flutter_ui_mcp` Examples**:
   - Remove `llamadart` from `flutter_ui_mcp/pubspec.yaml`.
   - Ensure all examples (chat, dynamic skills, eval, vision) compile and run cleanly with standard lightweight dependencies.
3. **Validate Native Build Sizes**:
   - Measure APK / IPA / desktop binary build impact to verify that C++ native bloat is eliminated for standard projects.

---

## 📝 Phase 6: Version Bumping, Changelogs & Documentation

1. **Version Synchronized Bump to `1.4.0`**:
   - `dart_mcp_core`: `1.4.0`
   - `flutter_ui_mcp_core`: `1.4.0`
   - `flutter_ui_mcp`: `1.4.0`
   - `flutter_genui_mcp`: `1.4.0`
   - `flutter_ui_mcp_embedded`: `1.4.0` (new package)
2. **Update `CHANGELOG.md`** across all packages:
   - Highlight decoupling of embedded models and the new companion package.
   - Document `McpChatInputBar`, `McpChatView`, `topBarBuilder`, and `settingsDialogBuilder`.
   - Document programmatic dialog helpers (`showMcpSettingsDialog`, `showMcpInspectorDialog`).
3. **Update `README.md` & `llms.txt`**:
   - Add setup instructions for `flutter_ui_mcp_embedded` for users who want on-device GGUF.
   - Provide snippets for custom builders and embedding in apps like `tealkit` and `ai_grid`.

---

## 🧪 Verification & Acceptance Criteria

1. **Analyzer & Linter**: Run `flutter analyze` across `dart_mcp_core`, `flutter_ui_mcp_core`, `flutter_ui_mcp`, and `flutter_ui_mcp_embedded` with zero warnings.
2. **Unit & Widget Tests**:
   - Test `McpChatInputBar` isolated rendering and event dispatching.
   - Test `topBarBuilder` custom widget rendering.
   - Test `EmbeddedLlmRegistry` driver registration and fallback banner.
   - Run existing suite tests in `flutter_ui_mcp_core` and `flutter_ui_mcp`.
3. **Embedded Execution**: Verify `examples/flutter/example_embedded` functions properly with `flutter_ui_mcp_embedded`.

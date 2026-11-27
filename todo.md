# TODO — `mcp_playground` (`dart_mcp_core` & `flutter_ui_mcp_core`)

## 1. `dart_mcp_core` — Fix Infinite Context Compression Thrashing Loop (`ContextCompressor`)

**File:** `dart_mcp_core/lib/src/context/context_compressor.dart` (lines 243–275 & 357–376)

### Root Cause
After the first compression pass, `compressedList` is:
- `messages[0]` = `[Prior Conversation Summary]` (`ChatRole.system`)
- `messages[1]` = current `ChatRole.user` prompt (`lastUserIdx == 1`)
- `messages[2..N]` = large in-flight tool calls/results (e.g., 68k tokens)

On the next tool call, `shouldCompress()` sees `tokens >= tokenThreshold` and calls `compress()`. Because `lastUserIdx == 1 > 0`, it enters `if (lastUserIdx > 0)` and sets:
- `oldMessages = messages.sublist(0, 1)` — **only the 1 existing summary message**
- `recentMessages = messages.sublist(1)` — **the entire 68k-token current turn untouched**

It then asks the LLM to re-summarize the 1 existing summary (`1 turns archived into Episodic Memory`), wraps it in a new header (+20–30 tokens larger, e.g. `68278 → 68301`), stays above threshold, and fires on **every single tool call forever** (burning millions of tokens).

### Required Fixes
- [x] **Fix split condition**: When `lastUserIdx > 0`, check whether `messages.sublist(0, lastUserIdx)` contains only `ChatRole.system` summary message(s) (e.g., `lastUserIdx == 1 && messages[0].role == ChatRole.system`). If so, **do not** split at `lastUserIdx` — instead fall through to the in-flight single-turn tool-compression branch:
  - Preserve `messages[lastUserIdx]` (the active user prompt) and the last `preserveRecentCount` messages (`splitIndex = totalMessages - preserveRecentCount`, backing up past trailing `tool` / `toolCall` boundaries).
  - Compress the prior summary (`messages[0..lastUserIdx-1]`) **together with** the older tool calls/results of the current turn (`messages[lastUserIdx+1..splitIndex]`).
- [x] **No-op / anti-inflation guard**:
  - Skip compression (return `compressedTurnCount: 0` without calling the LLM) if `oldMessages` contains only prior `ChatRole.system` summary messages or fewer than 2 non-system messages.
  - After generating the summary, if `compressedTokens >= originalTokens`, abort replacing `messages` and return `compressedTurnCount: 0` so compression never inflates context or loops.
- [x] **Unit test**: Add a test in `dart_mcp_core/test/` simulating a single user turn with 20+ large tool calls/results after an initial summary at `messages[0]`, asserting that:
  1. `compress()` compresses actual tool turns (`compressedTurnCount > 1`),
  2. `compressedTokens < originalTokens`, and
  3. calling `compress()` again does not re-summarize `messages[0]` alone.

---

## 2. `flutter_ui_mcp_core` — Fix Mobile Export to PDF, Default Folder & Dialog Overflow

**File:** `flutter_ui_mcp_core/lib/src/services/document_export_service.dart`

### Root Causes
1. **Corrupt `.pdf` on Android / iOS / macOS / Linux** (lines 453–495): `generatePdfBytes()` only attempts to spawn Windows `msedge.exe` / `chrome.exe --headless --print-to-pdf=...` and falls back to `utf8.encode(html)` — writing raw HTML text into a `.pdf` file on non-Windows platforms.
2. **Invalid `"/"` default folder on Mobile** (lines 102–117): `_resolveDefaultDirectory()` checks Windows `USERPROFILE` and otherwise returns `Directory.current.path` (`"/"` on Android & iOS, which is read-only).
3. **Mobile overflow in `ExportDocumentDialog`** (lines 861–922): The Destination Folder `TextField` and `Browse...` button sit side-by-side in a `Row`, overflowing/cramping on mobile screens, and the 3 format pills truncate to `PDF (...`, `Word ...`, `Mark...`.
4. **Cannot open exported file on Mobile** (lines 119–129): `_openExportedFile()` only calls desktop `Process.run` (`cmd.exe` / `open` / `xdg-open`).

### Required Fixes
- [x] **Cross-platform pure-Dart PDF generation**: Replace the `msedge.exe` shell-out + HTML fallback in `generatePdfBytes()` with the pure-Dart `pdf` package (`package:pdf/widgets.dart`) rendering headings, paragraphs, bullet/numbered lists, inline bold/code, and fenced code blocks cleanly on Android, iOS, macOS, Linux, and Windows.
- [x] **Writable default directory per platform** (`path_provider`):
  - **Android**: writable Documents folder (e.g. `/storage/emulated/0/Documents` if writable, else `getExternalStorageDirectory()` / `getApplicationDocumentsDirectory()`, or `FilePicker.saveFile(bytes: ...)` for Scoped Storage).
  - **iOS**: `getApplicationDocumentsDirectory()`.
  - **macOS / Linux**: `$HOME/Documents` (fallback `getApplicationDocumentsDirectory()`).
  - **Windows**: `%USERPROFILE%\Documents`.
- [x] **Responsive mobile dialog layout**: Stack the **Browse...** button **below** the Destination Folder `TextField` (e.g. `Column`), and use compact format pill labels (`PDF`, `Word`, `MD`) on narrow screens.
- [x] **Mobile file open / share**: Use `open_file` or `share_plus` in `_openExportedFile()` on Android/iOS instead of `Process.run`.

---

## 3. Release & Version Bump
- [x] Run `dart test` / `dart analyze` across `dart_mcp_core` and `flutter_ui_mcp_core`.
- [x] Bump versions (e.g. `1.5.14` / `1.5.16`) and publish/update changelogs so `mobile_ai_agent` (`cli`, `cli.vscode`, Flutter app) can pick them up.

---

## 4. `flutter_ui_mcp_core` — Fix Flutter Web / WASM (`dart2wasm`) `Unsupported operation: _Namespace` Startup & Export Crashes

### 4a. Startup Crash in `ToolPermissionSettings` (CRITICAL — blocks Web / WASM app load)

**Files:**
- `flutter_ui_mcp_core/lib/playground_controller.dart` (line 577: `ToolPermissionSettings _permissions = ToolPermissionSettings.load();`)
- `flutter_ui_mcp_core/lib/src/services/tool_permission_service.dart` (lines 102–163)

#### Root Cause
`PlaygroundController` unconditionally calls `ToolPermissionSettings.load()` in its field initializer. On Flutter Web / WASM (`dart2wasm`), `universal_io` stubs `Platform.environment` to `{}` (so `USERPROFILE` and `HOME` are `null`), **but does not stub `Directory` or `File`** — they still forward straight to `dart:io`.
- `defaultStoragePath` falls through to `Directory.current.path`, which invokes `dart:io`'s `_Namespace._namespace` and throws `UnsupportedError: Unsupported operation: _Namespace`.
- `File(path).existsSync()` (line 114) and `save()` (lines 152–153) also execute outside `try/catch` without a `kIsWeb` guard.
- Throwing inside `PlaygroundController`'s constructor aborts `initState()` in host apps (e.g. `ThiesA2uiScreen`), leaving `late final PlaygroundController` uninitialized and sticking the Web/WASM app on a grey loading screen.

#### Required Fixes
- [x] **`defaultStoragePath` (lines 103–108)**: Guard with `if (kIsWeb) return '';` before reading `Platform.environment` or `Directory.current.path`.
- [x] **`load([String? customPath])` (lines 111–148)**: Early-return `ToolPermissionSettings()` when `kIsWeb`, and move `defaultStoragePath`, empty-path check, `File(path)`, and `file.existsSync()` inside the `try { ... } catch (_) { return ToolPermissionSettings(); }` block.
- [x] **`save([String? customPath])` (lines 151–163)**: Early-return when `kIsWeb`, and wrap `defaultStoragePath`, empty-path check, and `File(path)` inside `try { ... } catch (_) {}`.

---

### 4b. Web / WASM Export Crash in `DocumentExportService`

**File:** `flutter_ui_mcp_core/lib/src/services/document_export_service.dart` (lines 83–112, 914–986, 1060)

#### Root Cause
In `ExportDocumentDialog`, `_isMobile` is `!kIsWeb && (Platform.isAndroid || Platform.isIOS)`, so on Web (`kIsWeb == true`):
- Line 1060 shows the desktop **Destination Folder** field even though `_resolveDefaultDirectory()` returns `''` on Web.
- Line 919 evaluates `if (!isMobile && (dir.isEmpty || !Directory(dir).existsSync()))`, which either blocks export or throws `Unsupported operation: _Namespace` if `dir` is non-empty, instead of triggering a browser download via `FilePicker.saveFile(bytes: bytes)`.
- Lines 101–109 show an `Open` snackbar button that calls `_openExportedFile()` (which uses native `Process.run`).

#### Required Fixes
- [x] **Treat Web like mobile for saving**: Replace `_isMobile` in `ExportDocumentDialog` with `bool get _useSaveDialog => kIsWeb || Platform.isAndroid || Platform.isIOS;` (lines 914, 917, 919, 955, 1060) so Web hides the Destination Folder picker and exports PDF / DOCX / Markdown via `FilePicker.saveFile(bytes: bytes)` browser download.
- [x] **Skip native `Open` snackbar action on Web** (line 101): Change `action: isContentUri ? null : ...` to `action: (kIsWeb || isContentUri) ? null : ...`.

---

## 5. Verification & Release (Web / WASM Fix)
- [x] Run `dart analyze` and `flutter test` in `flutter_ui_mcp_core`.
- [x] Verify Web/WASM build (`flutter build web --wasm`) boots cleanly with zero `Unsupported operation: _Namespace` errors in the browser console.
- [x] Bump `flutter_ui_mcp_core` version & changelog once verified.

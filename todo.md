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

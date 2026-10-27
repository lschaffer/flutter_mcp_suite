import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';
import '../services/clipboard_content_service.dart';

class ToolGroup {
  final String name;
  final List<String> toolNames;
  const ToolGroup({required this.name, required this.toolNames});

  @override
  bool operator ==(Object other) =>
      other is ToolGroup &&
      other.name == name &&
      listEquals(other.toolNames, toolNames);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(toolNames));
}

class SubPromptEntry {
  final TextEditingController controller;
  List<String>? enabledToolNames;
  bool stopAfterToolCall;

  SubPromptEntry({
    String text = '',
    this.enabledToolNames,
    this.stopAfterToolCall = false,
  }) : controller = TextEditingController(text: text);

  factory SubPromptEntry.fromStep(SubPromptStep s) => SubPromptEntry(
        text: s.text,
        enabledToolNames: s.enabledToolNames != null
            ? List<String>.from(s.enabledToolNames!)
            : null,
        stopAfterToolCall: s.stopAfterToolCall,
      );

  SubPromptStep toStep() => SubPromptStep(
        text: controller.text,
        enabledToolNames: enabledToolNames != null
            ? List<String>.unmodifiable(enabledToolNames!)
            : null,
        stopAfterToolCall: stopAfterToolCall,
      );

  void dispose() => controller.dispose();
}

class SubPromptListEditor extends StatefulWidget {
  const SubPromptListEditor({
    super.key,
    required this.controller,
    this.chatMode = false,
    this.availableToolGroups = const [],
    this.minLines = 2,
    this.maxLines = 8,
    this.hintText,
    this.validator,
    this.onToolSelectionChanged,
    this.onClipboardMedia,
    this.onClipboardMediaBatch,
    this.leading,
    this.trailing,
  });

  final TextEditingController controller;
  final bool chatMode;
  final List<ToolGroup> availableToolGroups;
  final int minLines;
  final int maxLines;
  final String? hintText;
  final String? Function(String?)? validator;
  final VoidCallback? onToolSelectionChanged;
  final ValueChanged<ClipboardPayload>? onClipboardMedia;
  final ValueChanged<List<ClipboardPayload>>? onClipboardMediaBatch;
  final Widget? leading;
  final Widget? trailing;

  @override
  State<SubPromptListEditor> createState() => _SubPromptListEditorState();
}

class _SubPromptListEditorState extends State<SubPromptListEditor> {
  late List<SubPromptEntry> _entries;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _entries = _parse(widget.controller.text);
    widget.controller.addListener(_onExternalWrite);
    for (final e in _entries) {
      e.controller.addListener(_onEntryChanged);
    }
  }

  @override
  void didUpdateWidget(SubPromptListEditor old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onExternalWrite);
      widget.controller.addListener(_onExternalWrite);
      _rebuildFromController();
    }
    if (old.chatMode != widget.chatMode && widget.chatMode) {
      if (_entries.length > 1) {
        while (_entries.length > 1) {
          final last = _entries.removeLast();
          last.controller.removeListener(_onEntryChanged);
          last.dispose();
        }
        _activeTabIndex = 0;
        _onEntryChanged();
      }
    }
    if (!listEquals(old.availableToolGroups, widget.availableToolGroups)) {
      if (widget.controller.text != _serialize()) {
        _rebuildFromController();
      } else {
        _syncToolGroupsToNewList(widget.availableToolGroups);
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onExternalWrite);
    for (final e in _entries) {
      e.controller.removeListener(_onEntryChanged);
      e.dispose();
    }
    super.dispose();
  }

  List<SubPromptEntry> _parse(String text) {
    final steps = parseSubPromptSteps(text);
    if (widget.chatMode && steps.length > 1) {
      return [SubPromptEntry.fromStep(steps.first)];
    }
    return steps.map(SubPromptEntry.fromStep).toList();
  }

  String _serialize() =>
      serializeSubPromptSteps(_entries.map((e) => e.toStep()).toList());

  void _syncToolGroupsToNewList(List<ToolGroup> newGroups) {
    final newAllNames = {for (final g in newGroups) ...g.toolNames};
    bool changed = false;
    for (final entry in _entries) {
      if (entry.enabledToolNames == null) continue;
      final before = entry.enabledToolNames!.length;
      entry.enabledToolNames!.removeWhere((t) => !newAllNames.contains(t));
      if (entry.enabledToolNames!.length != before) changed = true;
    }
    if (changed) {
      setState(() {});
      _onEntryChanged();
    }
  }

  bool _suppressExternalWrite = false;

  void _onEntryChanged() {
    _suppressExternalWrite = true;
    widget.controller.text = _serialize();
    _suppressExternalWrite = false;
  }

  void _onExternalWrite() {
    if (_suppressExternalWrite) return;
    _rebuildFromController();
  }

  void _rebuildFromController() {
    final newText = widget.controller.text;
    if (newText == _serialize()) return;
    setState(() {
      for (final e in _entries) {
        e.controller.removeListener(_onEntryChanged);
        e.dispose();
      }
      _entries = _parse(newText);
      for (final e in _entries) {
        e.controller.addListener(_onEntryChanged);
      }
      if (_activeTabIndex >= _entries.length) {
        _activeTabIndex = _entries.isEmpty ? 0 : _entries.length - 1;
      }
    });
  }

  void _addEntryAfter(int index) {
    setState(() {
      final e = SubPromptEntry(
        enabledToolNames: null,
        stopAfterToolCall: false,
      );
      e.controller.addListener(_onEntryChanged);
      final insertAt = (index + 1).clamp(0, _entries.length);
      _entries.insert(insertAt, e);
      _activeTabIndex = insertAt;
      _onEntryChanged();
    });
  }

  void _removeEntry(int index) {
    if (_entries.length <= 1) return;
    setState(() {
      _entries[index].controller.removeListener(_onEntryChanged);
      _entries[index].dispose();
      _entries.removeAt(index);
      if (_activeTabIndex >= _entries.length) {
        _activeTabIndex = _entries.length - 1;
      }
      _onEntryChanged();
    });
  }

  void _setEnabledTools(int index, List<String>? names) {
    setState(() {
      _entries[index].enabledToolNames = names;
      _onEntryChanged();
    });
    widget.onToolSelectionChanged?.call();
  }

  void _setStopAfterToolCall(int index, bool value) {
    setState(() {
      _entries[index].stopAfterToolCall = value;
      _onEntryChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final activeIdx = _activeTabIndex.clamp(0, _entries.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.chatMode)
          _buildTopTabBarWithActions(context, theme, activeIdx),
        _buildActiveStep(context, activeIdx),
      ],
    );
  }

  Widget _buildTopTabBarWithActions(
    BuildContext context,
    ThemeData theme,
    int activeIdx,
  ) {
    final entry = _entries[activeIdx];
    final isMobile = MediaQuery.of(context).size.width < 600;
    final hasTools = widget.availableToolGroups.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Horizontally scrollable tabs on the left
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < _entries.length; i++) ...[
                    _buildTabHeader(theme, i),
                    const SizedBox(width: 6),
                  ],
                  Tooltip(
                    message: 'Add step',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _addEntryAfter(_entries.length - 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Step',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Fixed width action controls aligned to the right on the same line
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.chatMode && hasTools) ...[
                _ToolsChecklistButton(
                  entry: entry,
                  stepIndex: activeIdx,
                  availableToolGroups: widget.availableToolGroups,
                  isMobile: isMobile,
                  onChanged: (names) => _setEnabledTools(activeIdx, names),
                ),
                const SizedBox(width: 4),
              ],
              if (!widget.chatMode) ...[
                _StopAfterToolCallBtn(
                  active: entry.stopAfterToolCall,
                  onToggle: () => _setStopAfterToolCall(
                    activeIdx,
                    !entry.stopAfterToolCall,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              _IconBtn(
                icon: Icons.add_circle_outline,
                color: const Color(0xFF00ACC1),
                tooltip: 'Add step after this one',
                onPressed: () => _addEntryAfter(activeIdx),
              ),
              if (_entries.length > 1) ...[
                const SizedBox(width: 4),
                _IconBtn(
                  icon: Icons.remove_circle_outline,
                  color: theme.colorScheme.error,
                  tooltip: 'Remove this step',
                  onPressed: () => _removeEntry(activeIdx),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabHeader(ThemeData theme, int index) {
    final isSelected = index == _activeTabIndex;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _activeTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(
          left: 10,
          right: _entries.length > 1 ? 4 : 10,
          top: 4,
          bottom: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Step ${index + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_entries.length > 1) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: 'Delete Step ${index + 1}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _removeEntry(index),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveStep(BuildContext context, int index) {
    final entry = _entries[index];

    final textField = TextField(
      controller: entry.controller,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      decoration: InputDecoration(
        hintText: index == 0
            ? (widget.hintText ?? 'Message AI...')
            : 'Continue...  use \${tool_result} to inject prior step output',
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );

    final wrappedField = (widget.onClipboardMedia != null ||
            widget.onClipboardMediaBatch != null)
        ? Actions(
            actions: <Type, Action<Intent>>{
              PasteTextIntent: CallbackAction<PasteTextIntent>(
                onInvoke: (intent) async {
                  final payloads = await ClipboardContentService.readClipboard();
                  final media = payloads.where((p) => p.isMedia).toList();
                  if (media.isNotEmpty) {
                    if (widget.onClipboardMediaBatch != null) {
                      widget.onClipboardMediaBatch!(media);
                    } else if (widget.onClipboardMedia != null) {
                      for (final m in media) {
                        widget.onClipboardMedia!(m);
                      }
                    }
                    return null;
                  }
                  // Fallback: standard paste into text field
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    final current = entry.controller.text;
                    final sel = entry.controller.selection;
                    if (sel.isValid) {
                      final before = current.substring(0, sel.start);
                      final after = current.substring(sel.end);
                      final newText = '$before${data!.text}$after';
                      entry.controller.value = TextEditingValue(
                        text: newText,
                        selection: TextSelection.collapsed(
                          offset: sel.start + data.text!.length,
                        ),
                      );
                    } else {
                      entry.controller.text = '$current${data!.text}';
                    }
                  }
                  return null;
                },
              ),
            },
            child: textField,
          )
        : textField;

    if (widget.leading == null && widget.trailing == null) {
      return wrappedField;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: 4),
        ],
        Expanded(child: wrappedField),
        if (widget.trailing != null) ...[
          const SizedBox(width: 4),
          widget.trailing!,
        ],
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      );
}

class _StopAfterToolCallBtn extends StatelessWidget {
  const _StopAfterToolCallBtn({required this.active, required this.onToggle});

  final bool active;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: active
          ? 'Stop after tool call: ON\nResult not sent to LLM — next step starts immediately'
          : 'Stop after tool call: OFF for this step\nTap to stop LLM loop after first tool call',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            active ? Icons.flag : Icons.flag_outlined,
            size: 18,
            color: active ? Colors.orange : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _ToolsChecklistButton extends StatelessWidget {
  const _ToolsChecklistButton({
    required this.entry,
    required this.stepIndex,
    required this.availableToolGroups,
    required this.isMobile,
    required this.onChanged,
  });

  final SubPromptEntry entry;
  final int stepIndex;
  final List<ToolGroup> availableToolGroups;
  final bool isMobile;
  final ValueChanged<List<String>?> onChanged;

  Set<String> _enabledToolNamesSet() {
    if (entry.enabledToolNames == null) {
      return {for (final g in availableToolGroups) ...g.toolNames};
    }
    return entry.enabledToolNames!.toSet();
  }

  int get _totalToolCount =>
      availableToolGroups.fold(0, (s, g) => s + g.toolNames.length);

  (IconData, Color) _iconState(ThemeData theme) {
    if (entry.enabledToolNames == null) {
      return (Icons.build_rounded, theme.colorScheme.primary);
    }
    if (entry.enabledToolNames!.isEmpty) return (Icons.block_outlined, Colors.grey);
    if (entry.enabledToolNames!.length == _totalToolCount) {
      return (Icons.build_rounded, theme.colorScheme.primary);
    }
    return (Icons.rule, Colors.orange);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = _iconState(theme);
    final enabledCount = entry.enabledToolNames?.length ?? _totalToolCount;
    final tooltip = 'Tools: $enabledCount/$_totalToolCount';
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showSelectionDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Future<void> _showSelectionDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final isMobileView = MediaQuery.of(context).size.width < 600;
    var current = _enabledToolNamesSet();
    final allToolNames = {for (final g in availableToolGroups) ...g.toolNames};

    Widget buildContent(BuildContext ctx, StateSetter setDialogState) {
      final allSelectedGlobally = current.length == allToolNames.length;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: availableToolGroups.length,
              itemBuilder: (context, groupIdx) {
                final group = availableToolGroups[groupIdx];
                final groupSet = group.toolNames.toSet();
                final allSelectedInGroup = groupSet.every(current.contains);
                final sortedTools = List<String>.from(group.toolNames)
                  ..sort((a, b) => a.compareTo(b));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.outline,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setDialogState(() {
                              if (allSelectedInGroup) {
                                current = current.difference(groupSet);
                              } else {
                                current = current.union(groupSet);
                              }
                            }),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(40, 28),
                            ),
                            child: Text(allSelectedInGroup ? 'None' : 'All'),
                          ),
                        ],
                      ),
                    ),
                    if (group.toolNames.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Text(
                          '(no tools found)',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ...sortedTools.map((toolName) {
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          title: Text(toolName, style: const TextStyle(fontSize: 13)),
                          value: current.contains(toolName),
                          activeColor: theme.colorScheme.primary,
                          onChanged: (v) => setDialogState(() {
                            if (v == true) {
                              current = {...current, toolName};
                            } else {
                              current = current.difference({toolName});
                            }
                          }),
                        );
                      }),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => setDialogState(() => current = Set.from(allToolNames)),
                  child: Text(allSelectedGlobally ? 'All selected' : 'Select all'),
                ),
                TextButton(
                  onPressed: () => setDialogState(() => current = {}),
                  child: const Text('None'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _commit(current);
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (isMobileView) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text('Tools - Step ${stepIndex + 1}'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            body: StatefulBuilder(
              builder: (ctx2, setState) => buildContent(ctx, setState),
            ),
          ),
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Tools - Step ${stepIndex + 1}'),
          contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
          content: SizedBox(
            width: 380,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500),
              child: StatefulBuilder(
                builder: (ctx2, setState) => buildContent(ctx, setState),
              ),
            ),
          ),
        ),
      );
    }
  }

  void _commit(Set<String> selectedToolNames) {
    final allCount = _totalToolCount;
    if (selectedToolNames.length == allCount) {
      onChanged(null);
    } else if (selectedToolNames.isEmpty) {
      onChanged([]);
    } else {
      onChanged(selectedToolNames.toList());
    }
  }
}

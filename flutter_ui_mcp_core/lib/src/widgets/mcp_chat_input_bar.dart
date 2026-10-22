import 'package:material_ui/material_ui.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';
import '../../playground_controller.dart';
import 'active_skill_banner.dart';
import 'dynamic_skill_dock.dart';
import 'sub_prompt_list_editor.dart';

/// A standalone, reusable chat prompt input bar with attachment previews,
/// clipboard paste, and send triggers.
///
/// Designed for modular use in host applications
/// that only need the chat composer without requiring the full playground scaffold.
class McpChatInputBar extends StatelessWidget {
  /// The text editing controller for the prompt input.
  final TextEditingController controller;

  /// Triggered when the user submits or clicks the send button.
  final VoidCallback onSend;

  /// Whether the AI agent is currently generating tokens.
  final bool isGenerating;

  /// Whether direct chat mode is enabled (disables multi-turn tool calling UI hints).
  final bool chatMode;

  /// Current list of attached files or media.
  final List<MessageAttachment> attachments;

  /// Callback when user clicks the attach button.
  final VoidCallback? onAttach;

  /// Callback when user triggers clipboard paste.
  final VoidCallback? onPaste;

  /// Callback when attachments are removed or cleared.
  final ValueChanged<List<MessageAttachment>>? onAttachmentsChanged;

  /// Callback to clear all attachments.
  final VoidCallback? onClearAttachments;

  /// Optional hint text for the input text field.
  final String? hintText;

  /// Optional custom leading widget in the composer toolbar.
  final Widget? leading;

  /// Optional custom trailing widget (replaces send button if provided).
  final Widget? trailing;

  /// Available MCP tool groups for `/` slash command autocompletion.
  final List<ToolGroup>? availableToolGroups;

  /// Optional [PlaygroundController] to enable dynamic skills banner and docking.
  final PlaygroundController? playgroundController;

  /// Whether to show the dynamic skills dock when [playgroundController] is provided.
  final bool showSkillsDock;

  /// Custom padding for the input bar.
  final EdgeInsetsGeometry? padding;

  /// Optional custom background decoration.
  final Decoration? decoration;

  /// Callback when user clicks the stop/cancel button while generating.
  /// If null and [playgroundController] is provided, falls back to `playgroundController.cancelGeneration()`.
  final VoidCallback? onCancel;

  const McpChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onCancel,
    this.isGenerating = false,
    this.chatMode = false,
    this.attachments = const [],
    this.onAttach,
    this.onPaste,
    this.onAttachmentsChanged,
    this.onClearAttachments,
    this.hintText,
    this.leading,
    this.trailing,
    this.availableToolGroups,
    this.playgroundController,
    this.showSkillsDock = true,
    this.padding,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Container(
      decoration: decoration ??
          BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: isMobile ? 6.0 : 12.0,
                vertical: isMobile ? 4.0 : 8.0,
              ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (playgroundController != null) ...[
                ActiveSkillBanner(
                  controller: playgroundController!,
                  padding: const EdgeInsets.only(bottom: 4.0),
                ),
                if (showSkillsDock)
                  DynamicSkillDock(
                    controller: playgroundController!,
                    padding: const EdgeInsets.only(bottom: 4.0),
                  ),
              ],
              _buildAttachmentPreviews(context, theme),
              SubPromptListEditor(
                controller: controller,
                chatMode: chatMode,
                availableToolGroups: availableToolGroups ?? const [],
                minLines: 1,
                maxLines: 6,
                hintText: hintText ??
                    (isGenerating
                        ? 'Agent is working...'
                        : 'Type a message, paste image/doc (Ctrl+V), or ask a tool...'),
                leading: leading ??
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onAttach != null)
                          IconButton(
                            icon: const Icon(Icons.attach_file_outlined),
                            tooltip: 'Attach Files / Images',
                            onPressed: isGenerating ? null : onAttach,
                          ),
                        if (onPaste != null)
                          IconButton(
                            icon: const Icon(Icons.content_paste_go_outlined),
                            tooltip: 'Paste from Clipboard (Ctrl+V)',
                            onPressed: isGenerating ? null : onPaste,
                          ),
                      ],
                    ),
                trailing: trailing ??
                    (isGenerating
                        ? IconButton(
                            icon: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.stop_rounded,
                                size: 16,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                            tooltip: 'Stop generation',
                            onPressed: onCancel ??
                                () => playgroundController?.cancelGeneration(),
                          )
                        : IconButton(
                            icon: Icon(
                              Icons.send_rounded,
                              color: controller.text.trim().isNotEmpty ||
                                      attachments.isNotEmpty
                                  ? theme.colorScheme.primary
                                  : theme.disabledColor,
                            ),
                            tooltip: 'Send',
                            onPressed: onSend,
                          )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentPreviews(BuildContext context, ThemeData theme) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Attachments (${attachments.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (onClearAttachments != null || onAttachmentsChanged != null)
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    if (onClearAttachments != null) {
                      onClearAttachments!();
                    } else if (onAttachmentsChanged != null) {
                      onAttachmentsChanged!(const []);
                    }
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Clear all',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: attachments.map((att) {
              final isImg = att.mimeType.toLowerCase().startsWith('image/');
              return Chip(
                avatar: Icon(
                  isImg ? Icons.image : Icons.insert_drive_file,
                  size: 14,
                ),
                label: Text(
                  att.name,
                  style: const TextStyle(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: onAttachmentsChanged != null
                    ? () {
                        final updated = List<MessageAttachment>.from(attachments)
                          ..remove(att);
                        onAttachmentsChanged!(updated);
                      }
                    : null,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../playground_controller.dart';
import '../services/clipboard_content_service.dart';
import '../utils/image_optimizer.dart';
import '../utils/mime_utils.dart';
import 'chat_bubble.dart';
import 'mcp_chat_input_bar.dart';
import 'pending_tool_approval_card.dart';

/// Standalone, lightweight chat message view + input bar.
///
/// Designed to be embedded directly into custom scaffolds, split-views,
/// or multi-pane grid layouts without compulsory AppBars, drawers,
/// or the two-pane inspector.
class McpChatView extends StatefulWidget {
  /// The playground controller orchestrating messages, tools, and LLM calls.
  final PlaygroundController controller;

  /// Custom builder for chat message bubble contents.
  final Widget? Function(BuildContext context, ChatMessage? message)?
      messageContentBuilder;

  /// Optional custom input bar widget (replaces default [McpChatInputBar]).
  final Widget? customInputBar;

  /// Whether to display the bottom input bar.
  final bool showInputBar;

  /// Optional scroll controller for the chat message list.
  final ScrollController? scrollController;

  /// Padding for the chat message list.
  final EdgeInsetsGeometry? listPadding;

  /// Optional custom background decoration (e.g. background image or color).
  /// Falls back to [PlaygroundController.chatBackgroundDecoration] if null.
  final Decoration? backgroundDecoration;

  /// Whether to show the empty/welcome state text and icon when there are no messages.
  /// Defaults to true. Set to false to show only the background image/color without text.
  final bool showEmptyState;

  /// Optional custom builder for the empty chat state when there are no messages.
  /// Falls back to [PlaygroundController.emptyChatBuilder] if null.
  final WidgetBuilder? emptyChatBuilder;

  const McpChatView({
    super.key,
    required this.controller,
    this.messageContentBuilder,
    this.customInputBar,
    this.showInputBar = true,
    this.scrollController,
    this.listPadding,
    this.backgroundDecoration,
    this.showEmptyState = true,
    this.emptyChatBuilder,
  });

  @override
  State<McpChatView> createState() => _McpChatViewState();
}

class _McpChatViewState extends State<McpChatView> {
  late final ScrollController _scrollController;
  final TextEditingController _inputController = TextEditingController();
  final List<MessageAttachment> _attachments = [];
  bool _internalScroll = false;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _internalScroll = true;
    }
    if (widget.messageContentBuilder != null) {
      widget.controller.messageContentBuilder = widget.messageContentBuilder;
    }
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(McpChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerUpdate);
      widget.controller.addListener(_onControllerUpdate);
    }
    if (widget.messageContentBuilder != null) {
      widget.controller.messageContentBuilder = widget.messageContentBuilder;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    if (_internalScroll) {
      _scrollController.dispose();
    }
    _inputController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;

    final attachmentsToSend = List<MessageAttachment>.from(_attachments);
    _inputController.clear();
    setState(() => _attachments.clear());

    await widget.controller.sendMessage(
      text,
      attachments: attachmentsToSend.isNotEmpty ? attachmentsToSend : null,
    );
  }

  Future<void> _pickAttachments() async {
    try {
      final files = await FilePicker.pickFiles();
      if (files.isNotEmpty) {
        for (final file in files) {
          final rawBytes = await file.readAsBytes();
          final name = file.name;
          final mime = mimeFromExtension(name);
          Uint8List finalBytes = rawBytes;

          if (ImageOptimizer.isImageMime(mime)) {
            finalBytes = await ImageOptimizer.shrinkToOptimalSize(
              rawBytes,
              maxDimension: 1024,
            );
          }

          setState(() {
            _attachments.add(
              MessageAttachment(
                id: const Uuid().v4(),
                name: name,
                path: file.path ?? name,
                mimeType: mime,
                bytes: finalBytes,
                size: finalBytes.length,
              ),
            );
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _handlePaste() async {
    try {
      final items = await ClipboardContentService.readClipboard();
      if (items.isNotEmpty) {
        setState(() {
          for (final item in items) {
            if (item.bytes != null) {
              _attachments.add(
                MessageAttachment(
                  id: const Uuid().v4(),
                  name: item.name.isNotEmpty ? item.name : 'clipboard_media',
                  path: '',
                  mimeType: item.mimeType,
                  bytes: item.bytes,
                  size: item.bytes?.length,
                ),
              );
            } else if (item.text != null && item.text!.isNotEmpty) {
              final cur = _inputController.text;
              _inputController.text =
                  cur.isEmpty ? item.text! : '$cur\n${item.text}';
            }
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.controller.messages;
    final bgDecoration = widget.backgroundDecoration ??
        widget.controller.chatBackgroundDecoration;
    final showEmpty = widget.showEmptyState &&
        widget.controller.showEmptyChatState;
    final emptyBuilder = widget.emptyChatBuilder ??
        widget.controller.emptyChatBuilder;

    final pendingApproval = widget.controller.pendingToolApproval;
    Widget body;
    if (messages.isEmpty && pendingApproval == null) {
      if (emptyBuilder != null) {
        body = emptyBuilder(context);
      } else if (!showEmpty) {
        body = const SizedBox.expand();
      } else {
        body = _buildEmptyState(context);
      }
    } else {
      final totalCount = messages.length + (pendingApproval != null ? 1 : 0);
      body = ListView.builder(
        controller: _scrollController,
        padding: widget.listPadding ??
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        itemCount: totalCount,
        itemBuilder: (context, index) {
          if (index < messages.length) {
            final msg = messages[index];
            return ChatBubble(
              message: msg,
              controller: widget.controller,
            );
          } else {
            return PendingToolApprovalCard(
              approval: pendingApproval!,
              onDecision: widget.controller.respondToToolApproval,
            );
          }
        },
      );
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: bgDecoration,
            child: body,
          ),
        ),
        if (widget.showInputBar)
          widget.customInputBar ??
              McpChatInputBar(
                controller: _inputController,
                isGenerating: widget.controller.isGenerating,
                chatMode: widget.controller.chatMode,
                attachments: _attachments,
                onSend: _handleSend,
                onCancel: () => widget.controller.cancelGeneration(),
                onAttach: _pickAttachments,
                onPaste: _handlePaste,
                onAttachmentsChanged: (updated) => setState(() {
                  _attachments
                    ..clear()
                    ..addAll(updated);
                }),
                onClearAttachments: () => setState(() => _attachments.clear()),
                playgroundController: widget.controller,
              ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Ready to assist',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Send a message to start the conversation.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}


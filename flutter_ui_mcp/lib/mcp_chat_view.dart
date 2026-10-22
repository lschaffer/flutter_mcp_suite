import 'dart:typed_data';

import 'package:flutter_ui_mcp_core/flutter_ui_mcp_core.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

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

  const McpChatView({
    super.key,
    required this.controller,
    this.messageContentBuilder,
    this.customInputBar,
    this.showInputBar = true,
    this.scrollController,
    this.listPadding,
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

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  controller: _scrollController,
                  padding: widget.listPadding ??
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return ChatBubble(
                      message: msg,
                      controller: widget.controller,
                    );
                  },
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

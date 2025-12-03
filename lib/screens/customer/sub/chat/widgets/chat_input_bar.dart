// screens/customer/sub/chat/widgets/chat_input_bar.dart
import 'package:flutter/material.dart';
import 'package:offline_chat_app/models/chat_message.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final ChatMessage? replyingTo;
  final VoidCallback? onCancelReply;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.enabled,
    this.replyingTo,
    this.onCancelReply,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview bar
          if (widget.replyingTo != null)
            _buildReplyPreview(context, widget.replyingTo!, cs),

          // Input field
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: widget.controller,
                        decoration: InputDecoration(
                          hintText: widget.replyingTo != null
                              ? 'Reply to ${widget.replyingTo!.senderName}...'
                              : 'Type a message...',
                          hintStyle: TextStyle(
                            color: cs.onSurfaceVariant.withOpacity(0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        enabled: widget.enabled,
                        style: TextStyle(
                          fontSize: 15,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Material(
                      color: widget.enabled && widget.controller.text.trim().isNotEmpty
                          ? cs.primary
                          : cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: widget.enabled && widget.controller.text.trim().isNotEmpty
                            ? widget.onSend
                            : null,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.send_rounded,
                            color: widget.enabled &&
                                    widget.controller.text.trim().isNotEmpty
                                ? cs.onPrimary
                                : cs.onSurfaceVariant.withOpacity(0.5),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(
    BuildContext context,
    ChatMessage replyTo,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: cs.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      size: 16,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Replying to ${replyTo.senderName}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  replyTo.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancelReply,
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
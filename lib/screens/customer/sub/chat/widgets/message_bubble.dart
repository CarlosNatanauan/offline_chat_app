// screens/customer/sub/chat/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:offline_chat_app/models/chat_message.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final String currentUserId;
  final VoidCallback? onReply;
  final Function(String emoji)? onReaction;
  final Function(Offset position)? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    this.onReply,
    this.onReaction,
    this.onLongPress,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  double _swipeProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(widget.message.isSent ? -0.15 : 0.15, 0),
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSent = widget.message.isSent;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        // Received messages: swipe right (positive delta)
        // Sent messages: swipe left (negative delta)
        if (!isSent && details.delta.dx > 0) {
          setState(() {
            _swipeProgress = (_swipeProgress + details.delta.dx / 100).clamp(
              0.0,
              1.0,
            );
          });
          _swipeController.value = _swipeProgress;
        } else if (isSent && details.delta.dx < 0) {
          setState(() {
            _swipeProgress = (_swipeProgress - details.delta.dx / 100).clamp(
              0.0,
              1.0,
            );
          });
          _swipeController.value = _swipeProgress;
        }
      },
      onHorizontalDragEnd: (details) {
        if (_swipeProgress > 0.3) {
          // Trigger reply
          widget.onReply?.call();
          _swipeController.reverse();
        } else {
          _swipeController.reverse();
        }
        setState(() {
          _swipeProgress = 0.0;
        });
      },
      onLongPress: widget.onLongPress != null
          ? () {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final position = box.localToGlobal(Offset.zero);
              final center = Offset(
                position.dx + box.size.width / 2,
                position.dy + box.size.height / 2,
              );
              widget.onLongPress?.call(center);
            }
          : null,
      child: Stack(
        children: [
          // Reply icon that appears during swipe
          if (_swipeProgress > 0)
            Positioned(
              top: 0,
              bottom: 0,
              right: isSent ? null : 12,
              left: isSent ? 12 : null,
              child: Opacity(
                opacity: _swipeProgress,
                child: Icon(
                  Icons.reply_rounded,
                  color: cs.primary.withOpacity(0.6),
                  size: 28,
                ),
              ),
            ),

          // Main message bubble
          SlideTransition(
            position: _swipeAnimation,
            child: Align(
              alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Column(
                  crossAxisAlignment: isSent
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Reply preview (if this message is a reply)
                    if (widget.message.replyToMessage != null)
                      _buildReplyPreview(
                        context,
                        widget.message.replyToMessage!,
                        cs,
                        isSent,
                      ),

                    // Main message bubble
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSent ? cs.primary : cs.surfaceVariant,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isSent ? 18 : 4),
                          bottomRight: Radius.circular(isSent ? 4 : 18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sender name (only for received messages)
                          if (!isSent)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                widget.message.senderName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary,
                                ),
                              ),
                            ),

                          // Message text
                          Text(
                            widget.message.text,
                            style: TextStyle(
                              fontSize: 15,
                              color: isSent
                                  ? cs.onPrimary
                                  : cs.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Timestamp
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(widget.message.timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSent
                                      ? cs.onPrimary.withOpacity(0.7)
                                      : cs.onSurfaceVariant.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Reactions bar - positioned overlapping the message bubble
                    if (widget.message.reactions.isNotEmpty)
                      Transform.translate(
                        offset: const Offset(
                          0,
                          -8,
                        ), // Move up to overlap with bubble
                        child: _buildReactionsBar(context, cs),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionsBar(BuildContext context, ColorScheme cs) {
    final reactionCounts = widget.message.getReactionCounts();
    final entries = reactionCounts.entries.toList();
    final isSent = widget.message.isSent;

    return Container(
      margin: EdgeInsets.only(
        top: 0,
        left: isSent ? 0 : 8,
        right: isSent ? 8 : 0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: entries.map((entry) {
          final hasReacted = widget.message.hasUserReacted(
            widget.currentUserId,
            entry.key,
          );

          return GestureDetector(
            onTap: () {
              // Toggle reaction: if user already reacted with this emoji, remove it
              final hasReacted = widget.message.hasUserReacted(
                widget.currentUserId,
                entry.key,
              );

              if (hasReacted) {
                // User already reacted, so this is an "undo" - we need to handle removal
                // We'll still call onReaction, but the parent needs to handle removal
                widget.onReaction?.call(entry.key);
              } else {
                // User hasn't reacted yet, so add the reaction
                widget.onReaction?.call(entry.key);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: hasReacted
                    ? cs.primaryContainer.withOpacity(0.6)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 15)),
                  if (entry.value > 1) ...[
                    const SizedBox(width: 3),
                    Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasReacted ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReplyPreview(
    BuildContext context,
    ChatMessage replyTo,
    ColorScheme cs,
    bool isSent,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSent
            ? cs.primary.withOpacity(0.2)
            : cs.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSent
              ? cs.primary.withOpacity(0.5)
              : cs.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: isSent ? cs.primary : cs.primary.withOpacity(0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  replyTo.senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSent ? cs.primary : cs.primary.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  replyTo.text,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSent
                        ? cs.onSurfaceVariant.withOpacity(0.8)
                        : cs.onSurfaceVariant.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[time.weekday - 1];
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

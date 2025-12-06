// screens/customer/sub/chat/widgets/emoji_reaction_picker.dart
import 'package:flutter/material.dart';

class EmojiReactionPicker {
  // Quick reactions (most common emojis)
  static const List<String> quickReactions = [
    '❤️',
    '👍',
    '😂',
    '😮',
    '😢',
    '🔥',
  ];

  // Extended emoji categories
  static const Map<String, List<String>> emojiCategories = {
    'Smileys': [
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '🤣',
      '😂',
      '🙂',
      '🙃',
      '😉',
      '😊',
      '😇',
      '🥰',
      '😍',
      '🤩',
      '😘',
      '😗',
      '😚',
      '😙',
      '🥲',
      '😋',
      '😛',
      '😜',
      '🤪',
      '😝',
      '🤑',
      '🤗',
      '🤭',
      '🤫',
      '🤔',
      '🤐',
    ],
    'Gestures': [
      '👍',
      '👎',
      '👊',
      '✊',
      '🤛',
      '🤜',
      '🤞',
      '✌️',
      '🤟',
      '🤘',
      '👌',
      '🤌',
      '🤏',
      '👈',
      '👉',
      '👆',
      '👇',
      '☝️',
      '👋',
      '🤚',
      '🖐',
      '✋',
      '🖖',
      '👏',
    ],
    'Hearts': [
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '🤎',
      '💔',
      '❤️‍🔥',
      '❤️‍🩹',
      '💕',
      '💞',
      '💓',
      '💗',
      '💖',
      '💘',
      '💝',
      '💟',
      '♥️',
      '💌',
      '💋',
      '😻',
    ],
    'Objects': [
      '🎉',
      '🎊',
      '🎈',
      '🎁',
      '🏆',
      '🥇',
      '🥈',
      '🥉',
      '⚽',
      '🏀',
      '🏈',
      '⚾',
      '🎾',
      '🏐',
      '🏉',
      '🎱',
      '🔥',
      '⭐',
      '✨',
      '💫',
      '💥',
      '💯',
      '✅',
      '❌',
    ],
  };

  /// Show emoji picker bottom sheet
  static Future<String?> show(BuildContext context) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EmojiPickerSheet(),
    );
  }

  /// Show quick reaction overlay above message
  static void showQuickReactions(
    BuildContext context,
    Offset tapPosition,
    Function(String) onReaction,
  ) {
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _QuickReactionOverlay(
        tapPosition: tapPosition,
        onReaction: (emoji) {
          overlayEntry?.remove();
          onReaction(emoji);
        },
        onMore: () {
          overlayEntry?.remove();
          show(context).then((emoji) {
            if (emoji != null) {
              onReaction(emoji);
            }
          });
        },
        onDismiss: () {
          overlayEntry?.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

/// Quick reaction overlay that appears above the message
class _QuickReactionOverlay extends StatefulWidget {
  final Offset tapPosition;
  final Function(String) onReaction;
  final VoidCallback onMore;
  final VoidCallback onDismiss;

  const _QuickReactionOverlay({
    required this.tapPosition,
    required this.onReaction,
    required this.onMore,
    required this.onDismiss,
  });

  @override
  State<_QuickReactionOverlay> createState() => _QuickReactionOverlayState();
}

class _QuickReactionOverlayState extends State<_QuickReactionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    // Calculate position - center horizontally, place above tap position
    const padding = 16.0;
    const minWidth = 280.0;
    const maxWidth = 380.0;

    // Calculate picker width: 90% of screen width, but within min/max bounds
    final pickerWidth = (screenWidth * 0.9).clamp(minWidth, maxWidth);

    // Calculate emoji button size based on available space
    final totalHorizontalPadding = 24.0;
    final dividerSpace = 20.0;
    final availableWidth = pickerWidth - totalHorizontalPadding - dividerSpace;
    final emojiButtonSize = (availableWidth / 7).clamp(
      36.0,
      48.0,
    ); // 6 emojis + more button = 7 items

    const pickerHeight = 60.0;

    double left = (screenWidth - pickerWidth) / 2;
    left = left.clamp(padding, screenWidth - pickerWidth - padding);

    double top = widget.tapPosition.dy - pickerHeight - 20;

    if (top < 100) {
      top = widget.tapPosition.dy + 20;
    }

    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // Semi-transparent background
          FadeTransition(
            opacity: _opacityAnimation,
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),

          // Reaction picker
          Positioned(
            left: left,
            top: top,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: pickerWidth,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ...EmojiReactionPicker.quickReactions.map((emoji) {
                          return _EmojiButton(
                            emoji: emoji,
                            size: emojiButtonSize,
                            onTap: () => widget.onReaction(emoji),
                          );
                        }),
                        SizedBox(width: emojiButtonSize * 0.1),
                        Container(
                          width: 1,
                          height: 30,
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.2),
                        ),
                        SizedBox(width: emojiButtonSize * 0.1),
                        _MoreButton(
                          size: emojiButtonSize,
                          onTap: widget.onMore,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiButton extends StatefulWidget {
  final String emoji;
  final double size;
  final VoidCallback onTap;

  const _EmojiButton({
    required this.emoji,
    required this.size,
    required this.onTap,
  });

  @override
  State<_EmojiButton> createState() => _EmojiButtonState();
}

class _EmojiButtonState extends State<_EmojiButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(widget.size / 2),
          ),
          child: Text(
            widget.emoji,
            style: TextStyle(fontSize: widget.size * 0.6),
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const _MoreButton({required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Icon(
          Icons.add_rounded,
          size: size * 0.55,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _EmojiPickerSheet extends StatefulWidget {
  @override
  State<_EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<_EmojiPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = EmojiReactionPicker.emojiCategories.keys
      .toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final bottomSafe = mq.viewPadding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        height: mq.size.height * 0.5 + bottomSafe,
        padding: EdgeInsets.only(bottom: bottomSafe),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'React with an emoji',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            // Quick reactions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: EmojiReactionPicker.quickReactions.map((emoji) {
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, emoji),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const Divider(height: 1),

            // Category tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurfaceVariant,
              indicatorColor: cs.primary,
              tabs: _categories.map((cat) => Tab(text: cat)).toList(),
            ),

            // Emoji grid
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _categories.map((category) {
                  final emojis = EmojiReactionPicker.emojiCategories[category]!;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: emojis.length,
                    itemBuilder: (context, index) {
                      final emoji = emojis[index];
                      return GestureDetector(
                        onTap: () => Navigator.pop(context, emoji),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

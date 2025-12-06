// screens/customer/sub/chat/chat_screen_wifi.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:offline_chat_app/models/caflow_models.dart' show CaflowDevice;
import 'package:offline_chat_app/models/chat_message.dart';
import 'package:offline_chat_app/services/wifi_direct_service.dart';
import 'package:offline_chat_app/screens/customer/sub/chat/widgets/message_bubble.dart';
import 'package:offline_chat_app/screens/customer/sub/chat/widgets/chat_input_bar.dart';
import 'package:offline_chat_app/screens/customer/sub/chat/widgets/connection_banner.dart';
import 'package:offline_chat_app/screens/customer/sub/chat/widgets/emoji_reaction_picker.dart';

class ChatScreenWiFi extends StatefulWidget {
  final CaflowDevice device;
  final String userName;

  const ChatScreenWiFi({
    super.key,
    required this.device,
    required this.userName,
  });

  @override
  State<ChatScreenWiFi> createState() => _ChatScreenWiFiState();
}

class _ChatScreenWiFiState extends State<ChatScreenWiFi> {
  final WiFiDirectService _wifiService = WiFiDirectService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  final Map<String, ChatMessage> _messageMap = {};

  StreamSubscription<String>? _messageSub;
  StreamSubscription<ConnectionStatus>? _statusSub;

  ConnectionStatus _status = ConnectionStatus.connected;
  ChatMessage? _replyingTo;

  bool _disconnectDialogOpen = false;
  bool _isLocallyClosing = false;
  bool _hasClosed = false;

  @override
  void initState() {
    super.initState();
    _listenToMessages();
    _listenToStatus();
    _messageController.addListener(_onMessageChanged);
  }

  void _onMessageChanged() {
    setState(() {});
  }

  void _listenToMessages() {
    _messageSub = _wifiService.messagesStream.listen((rawMessage) {
      // Check if it's a reaction update
      if (rawMessage.startsWith('__REACTION__:')) {
        _handleReactionUpdate(rawMessage);
        return;
      }

      // Check if it's a reaction removal
      if (rawMessage.startsWith('__REACTION_REMOVE__:')) {
        _handleReactionRemoval(rawMessage);
        return;
      }

      final message = ChatMessage.decode(rawMessage);
      if (message == null) return;

      ChatMessage? replyToMessage;
      if (message.replyToId != null) {
        replyToMessage = _messageMap[message.replyToId];
      }

      final messageWithReply = message.copyWith(replyToMessage: replyToMessage);

      setState(() {
        _messages.add(messageWithReply);
        _messageMap[messageWithReply.id] = messageWithReply;
      });

      _scrollToBottom();
    });
  }

  void _handleReactionUpdate(String raw) {
    // Format: "__REACTION__:messageId:emoji:userId:timestamp"
    final parts = raw.split(':');
    if (parts.length < 5) return;

    final messageId = parts[1];
    final emoji = parts[2];
    final userId = parts[3];
    final timestamp = DateTime.parse(parts[4]);

    final message = _messageMap[messageId];
    if (message == null) return;

    final reaction = MessageReaction(
      emoji: emoji,
      userId: userId,
      timestamp: timestamp,
    );

    setState(() {
      final updatedMessage = message.addReaction(reaction);
      _messageMap[messageId] = updatedMessage;

      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = updatedMessage;
      }
    });
  }

  void _handleReactionRemoval(String raw) {
    // Format: "__REACTION_REMOVE__:messageId:emoji:userId:timestamp"
    final parts = raw.split(':');
    if (parts.length < 5) return;

    final messageId = parts[1];
    final emoji = parts[2];
    final userId = parts[3];

    final message = _messageMap[messageId];
    if (message == null) return;

    setState(() {
      final updatedMessage = message.removeReaction(userId, emoji);
      _messageMap[messageId] = updatedMessage;

      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = updatedMessage;
      }
    });
  }

  void _listenToStatus() {
    _statusSub = _wifiService.statusStream.listen((status) async {
      if (!mounted) return;

      // derive an "effective" status for the UI
      ConnectionStatus effectiveStatus = status;

      // If the underlying service still reports a live connection,
      // keep the chat UI in "connected" state for any non-fatal status.
      if (_wifiService.isConnected &&
          status != ConnectionStatus.disconnected &&
          status != ConnectionStatus.error &&
          status != ConnectionStatus.permissionDenied) {
        effectiveStatus = ConnectionStatus.connected;
      }

      print('[ChatScreenWiFi] status = $status, effective = $effectiveStatus');

      setState(() {
        _status = effectiveStatus;
      });

      final bool isTerminalState =
          effectiveStatus == ConnectionStatus.disconnected ||
          effectiveStatus == ConnectionStatus.error ||
          effectiveStatus == ConnectionStatus.permissionDenied;

      if (!isTerminalState) return;

      if (_isLocallyClosing) {
        if (!_hasClosed && mounted && Navigator.of(context).canPop()) {
          _hasClosed = true;
          Navigator.of(context).pop();
        }
        return;
      }

      if (_wifiService.isConnected) {
        await _wifiService.disconnectPeerOnly();
      }

      if (!_disconnectDialogOpen && !_hasClosed) {
        _disconnectDialogOpen = true;
        await _showDisconnectedDialog(effectiveStatus);
        _disconnectDialogOpen = false;
      }
    });
  }

  Future<void> _showDisconnectedDialog(ConnectionStatus cause) async {
    if (!mounted) return;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.link_off_rounded, color: cs.error),
            const SizedBox(width: 12),
            const Text('Connection ended'),
          ],
        ),
        content: Text(
          'The nearby link to ${widget.device.name} was interrupted.\n\n'
          'This usually happens if one of you closed the chat, moved too far '
          'away, or turned off Wi-Fi / Bluetooth / Location.\n\n'
          'You’ll be taken back to the nearby room so you can reconnect or '
          'start a chat with someone else.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              if (mounted && !_hasClosed && Navigator.of(context).canPop()) {
                _hasClosed = true;
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back to nearby room'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final messageId = '${DateTime.now().millisecondsSinceEpoch}';
    final message = ChatMessage(
      id: messageId,
      text: text,
      isSent: true,
      senderName: widget.userName,
      timestamp: DateTime.now(),
      replyToId: _replyingTo?.id,
      replyToMessage: _replyingTo,
    );

    final success = await _wifiService.sendMessage(message.encode());

    if (success) {
      setState(() {
        _messages.add(message);
        _messageMap[message.id] = message;
        _replyingTo = null;
      });

      _messageController.clear();
      _scrollToBottom();
    } else {
      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Message wasn\'t sent. The connection may have dropped.',
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            backgroundColor: cs.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendReaction(ChatMessage message, String emoji) async {
    // Check if user already reacted with this emoji
    final hasReacted = message.hasUserReacted(widget.userName, emoji);

    if (hasReacted) {
      // Remove the reaction
      setState(() {
        final updatedMessage = message.removeReaction(widget.userName, emoji);
        _messageMap[message.id] = updatedMessage;

        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[index] = updatedMessage;
        }
      });

      // Send removal to remote
      final reactionMsg =
          '__REACTION_REMOVE__:${message.id}:$emoji:${widget.userName}:${DateTime.now().toIso8601String()}';
      await _wifiService.sendMessage(reactionMsg);
    } else {
      // Add the reaction
      final reaction = MessageReaction(
        emoji: emoji,
        userId: widget.userName,
        timestamp: DateTime.now(),
      );

      setState(() {
        final updatedMessage = message.addReaction(reaction);
        _messageMap[message.id] = updatedMessage;

        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[index] = updatedMessage;
        }
      });

      // Send addition to remote
      final reactionMsg =
          '__REACTION__:${message.id}:$emoji:${widget.userName}:${reaction.timestamp.toIso8601String()}';
      await _wifiService.sendMessage(reactionMsg);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleReplyToMessage(ChatMessage message) {
    setState(() {
      _replyingTo = message;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  void _showMessageOptions(
    ChatMessage message,
    BuildContext context,
    Offset tapPosition,
  ) {
    EmojiReactionPicker.showQuickReactions(
      context,
      tapPosition,
      (emoji) => _sendReaction(message, emoji),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Future<void> _handleBackPressed() async {
    if (_hasClosed) return;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: cs.primary),
            const SizedBox(width: 8),
            const Text('Leave this chat?'),
          ],
        ),
        content: const Text(
          'Leaving will disconnect from the other phone.\n\n'
          'You\'ll still see this conversation on your device, but you '
          'won\'t get any new messages from them.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay in chat'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: Icon(Icons.call_end_rounded, size: 18),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            label: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted && !_hasClosed) {
      _isLocallyClosing = true;

      if (_wifiService.isConnected) {
        await _wifiService.disconnectPeerOnly();
      }

      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        _hasClosed = true;
        Navigator.pop(context);
      }
    }
  }

  Future<bool> _onWillPop() async {
    await _handleBackPressed();
    return false;
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _statusSub?.cancel();
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: GestureDetector(
        // ADDED: Dismiss keyboard when tapping empty space
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: cs.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: _handleBackPressed,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getStatusText(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _status == ConnectionStatus.connected
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () => _showChatInfo(context),
                tooltip: 'Chat Info',
              ),
            ],
          ),
          body: Column(
            children: [
              ConnectionBanner(status: _status),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState(cs, theme)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return MessageBubble(
                            message: message,
                            currentUserId: widget.userName,
                            onReply: () => _handleReplyToMessage(message),
                            onReaction: (emoji) =>
                                _sendReaction(message, emoji),
                            onLongPress: (position) =>
                                _showMessageOptions(message, context, position),
                          );
                        },
                      ),
              ),
              ChatInputBar(
                controller: _messageController,
                onSend: _sendMessage,
                enabled: _wifiService.isConnected,

                replyingTo: _replyingTo,
                onCancelReply: _cancelReply,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero bubble
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primaryContainer.withOpacity(0.6),
                    cs.primaryContainer.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(Icons.forum_outlined, size: 64, color: cs.primary),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'This chat is still quiet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onBackground,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'You\'re connected to ${widget.device.name}.\n'
              'Drop the first line and see where the conversation goes.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onBackground.withOpacity(0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Info pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.secondary.withOpacity(0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 20, color: cs.secondary),
                  const SizedBox(width: 8),
                  Text(
                    'Messages stay inside this café',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tiny hint
            Text(
              'No internet. No cloud. Just your phones talking directly.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onBackground.withOpacity(0.55),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showChatInfo(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: cs.primary),
            const SizedBox(width: 8),
            const Text('Chat details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Talking with', widget.device.name),
            const SizedBox(height: 12),
            _buildInfoRow('Link type', 'Wi-Fi Direct (phone-to-phone)'),
            const SizedBox(height: 12),
            _buildInfoRow('Messages', '${_messages.length}'),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Reactions',
              '${_messages.fold<int>(0, (sum, msg) => sum + msg.reactions.length)}',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Caflow keeps this chat offline. Messages travel only between '
                      'your phones, not through café Wi-Fi or the cloud.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (_status) {
      case ConnectionStatus.connected:
        return 'Connected here in the café';
      case ConnectionStatus.connecting:
        return 'Linking phones…';
      default:
        return 'Not connected';
    }
  }
}

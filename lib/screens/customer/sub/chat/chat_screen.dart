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

      final messageWithReply = message.copyWith(
        replyToMessage: replyToMessage,
      );

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

      setState(() {
        _status = status;
      });

      final bool isTerminalState = status == ConnectionStatus.disconnected ||
          status == ConnectionStatus.error ||
          status == ConnectionStatus.permissionDenied ||
          status == ConnectionStatus.idle ||
          status == ConnectionStatus.ready ||
          status == ConnectionStatus.discovering ||
          status == ConnectionStatus.advertising;

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
        await _showDisconnectedDialog(status);
        _disconnectDialogOpen = false;
      }
    });
  }

  Future<void> _showDisconnectedDialog(ConnectionStatus cause) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.link_off_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Connection Lost'),
          ],
        ),
        content: const Text(
          'The connection was lost. This can happen if one of you left the chat, '
          'or if Wi-Fi, Bluetooth, or Location services were turned off on either device.\n\n'
          'You will be returned to the nearby users screen.',
        ),
        actions: [
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (mounted && !_hasClosed && Navigator.of(context).canPop()) {
                _hasClosed = true;
                Navigator.pop(context);
              }
            },
            child: const Text('OK'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Failed to send message'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
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
      final reactionMsg = '__REACTION_REMOVE__:${message.id}:$emoji:${widget.userName}:${DateTime.now().toIso8601String()}';
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
      final reactionMsg = '__REACTION__:${message.id}:$emoji:${widget.userName}:${reaction.timestamp.toIso8601String()}';
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

  void _showMessageOptions(ChatMessage message, BuildContext context, Offset tapPosition) {
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Future<void> _handleBackPressed() async {
    if (_hasClosed) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Chat?'),
        content: const Text(
          'Leaving the chat will disconnect from the other device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Leave'),
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
                            onReaction: (emoji) => _sendReaction(message, emoji),
                            onLongPress: (position) => _showMessageOptions(message, context, position),
                          );
                        },
                      ),
              ),
              ChatInputBar(
                controller: _messageController,
                onSend: _sendMessage,
                enabled: _status == ConnectionStatus.connected,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start Chatting Offline',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send your first message to ${widget.device.name}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onBackground.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.wifi_off_rounded, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'No internet needed',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChatInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chat Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Connected to', widget.device.name),
            const SizedBox(height: 12),
            _buildInfoRow('Connection', 'Wi-Fi Direct (P2P)'),
            const SizedBox(height: 12),
            _buildInfoRow('Messages', '${_messages.length}'),
            const SizedBox(height: 12),
            _buildInfoRow('Reactions', '${_messages.fold<int>(0, (sum, msg) => sum + msg.reactions.length)}'),
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
        return 'Connected • Wi-Fi Direct';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      default:
        return 'Connection lost';
    }
  }
}
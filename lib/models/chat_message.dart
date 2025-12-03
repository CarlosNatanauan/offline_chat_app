// models/chat_message.dart
import 'dart:convert';

class MessageReaction {
  final String emoji;
  final String userId; // userName of who reacted
  final DateTime timestamp;

  MessageReaction({
    required this.emoji,
    required this.userId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] as String,
      userId: json['userId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isSent;
  final String senderName;
  final DateTime timestamp;
  final String? replyToId;
  final ChatMessage? replyToMessage;
  final List<MessageReaction> reactions;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isSent,
    required this.senderName,
    required this.timestamp,
    this.replyToId,
    this.replyToMessage,
    this.reactions = const [],
  });

  // Create a copy with modified fields
  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isSent,
    String? senderName,
    DateTime? timestamp,
    String? replyToId,
    ChatMessage? replyToMessage,
    List<MessageReaction>? reactions,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isSent: isSent ?? this.isSent,
      senderName: senderName ?? this.senderName,
      timestamp: timestamp ?? this.timestamp,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      reactions: reactions ?? this.reactions,
    );
  }

  // Add a reaction to this message
  ChatMessage addReaction(MessageReaction reaction) {
    final updatedReactions = List<MessageReaction>.from(reactions);
    
    // Remove any existing reaction from this user with the same emoji
    updatedReactions.removeWhere(
      (r) => r.userId == reaction.userId && r.emoji == reaction.emoji,
    );
    
    updatedReactions.add(reaction);
    return copyWith(reactions: updatedReactions);
  }

  // Remove a reaction from this message
  ChatMessage removeReaction(String userId, String emoji) {
    final updatedReactions = List<MessageReaction>.from(reactions);
    updatedReactions.removeWhere(
      (r) => r.userId == userId && r.emoji == emoji,
    );
    return copyWith(reactions: updatedReactions);
  }

  // Get count of each emoji
  Map<String, int> getReactionCounts() {
    final counts = <String, int>{};
    for (final reaction in reactions) {
      counts[reaction.emoji] = (counts[reaction.emoji] ?? 0) + 1;
    }
    return counts;
  }

  // Check if current user reacted with an emoji
  bool hasUserReacted(String userId, String emoji) {
    return reactions.any((r) => r.userId == userId && r.emoji == emoji);
  }

  // Encode for sending over network (normal message)
  String encode() {
    final map = {
      'id': id,
      'text': text,
      'senderName': senderName,
      'timestamp': timestamp.toIso8601String(),
      if (replyToId != null) 'replyToId': replyToId,
      if (reactions.isNotEmpty)
        'reactions': reactions.map((r) => r.toJson()).toList(),
    };
    return jsonEncode(map);
  }

  // Decode from network
  static ChatMessage? decode(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      
      List<MessageReaction> reactions = [];
      if (map['reactions'] != null) {
        reactions = (map['reactions'] as List)
            .map((r) => MessageReaction.fromJson(r as Map<String, dynamic>))
            .toList();
      }

      return ChatMessage(
        id: map['id'] as String,
        text: map['text'] as String,
        isSent: false,
        senderName: map['senderName'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        replyToId: map['replyToId'] as String?,
        reactions: reactions,
      );
    } catch (e) {
      print('❌ Failed to decode message: $e');
      return null;
    }
  }

  @override
  String toString() => 'ChatMessage($id, $text, $senderName, ${reactions.length} reactions)';
}
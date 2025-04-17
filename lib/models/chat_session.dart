import 'package:collection/collection.dart';
import 'package:flutter_memos/models/chat_message.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';

/// Only one of these exists – the user’s *current* chat session.
class ChatSession {
  static const String activeSessionId = 'currentUserActiveChat';

  final String id; // always activeSessionId
  final String? contextItemId;
  final WorkbenchItemType? contextItemType;
  final String? contextServerId;
  final List<ChatMessage> messages;
  final DateTime lastUpdated;

  const ChatSession({
    required this.id,
    this.contextItemId,
    this.contextItemType,
    this.contextServerId,
    required this.messages,
    required this.lastUpdated,
  });

  factory ChatSession.initial() => ChatSession(
        id: activeSessionId,
        messages: const [],
        lastUpdated: DateTime.now().toUtc(),
      );

  /* ---------- immutability ---------- */

  ChatSession copyWith({
    String? contextItemId,
    WorkbenchItemType? contextItemType,
    String? contextServerId,
    List<ChatMessage>? messages,
    DateTime? lastUpdated,
    bool clearContext = false,
  }) =>
      ChatSession(
        id: id,
        contextItemId: clearContext ? null : contextItemId ?? this.contextItemId,
        contextItemType:
            clearContext ? null : contextItemType ?? this.contextItemType,
        contextServerId:
            clearContext ? null : contextServerId ?? this.contextServerId,
        messages: messages ?? this.messages,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );

  /* ---------- (de)serialisation ---------- */

  Map<String, dynamic> toJson() => {
        'id': id,
        'contextItemId': contextItemId,
        'contextItemType': contextItemType?.name,
        'contextServerId': contextServerId,
        'messages': messages.map((m) => m.toJson()).toList(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    WorkbenchItemType? type;
    final rawType = json['contextItemType'];
    if (rawType is String) {
      try {
        type = WorkbenchItemType.values.byName(rawType);
      } catch (_) {}
    }

    return ChatSession(
      id: json['id'] as String? ?? activeSessionId,
      contextItemId: json['contextItemId'] as String?,
      contextItemType: type,
      contextServerId: json['contextServerId'] as String?,
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.tryParse(json['lastUpdated'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  /* ---------- equality ---------- */

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSession &&
          id == other.id &&
          contextItemId == other.contextItemId &&
          contextItemType == other.contextItemType &&
          contextServerId == other.contextServerId &&
          const ListEquality().equals(messages, other.messages) &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode => Object.hash(id, contextItemId, contextItemType,
      contextServerId, const ListEquality().hash(messages), lastUpdated);
}

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode
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
    'contextItemType': contextItemType?.name, // Store enum name as string
        'contextServerId': contextServerId,
        'messages': messages.map((m) => m.toJson()).toList(),
    'lastUpdated':
        lastUpdated.toIso8601String(), // Store DateTime as ISO string
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    // Parse contextItemType safely
    WorkbenchItemType? type;
    final rawType = json['contextItemType'];
    if (rawType is String && rawType.isNotEmpty) {
      try {
        type = WorkbenchItemType.values.byName(rawType);
      } catch (e) {
        if (kDebugMode) {
          print(
            '[ChatSession.fromJson] Error parsing contextItemType "$rawType": $e',
          );
        }
      }
    }

    // Parse lastUpdated safely, handling both DateTime and String inputs
    DateTime parsedLastUpdated;
    final rawLastUpdated = json['lastUpdated'];
    if (rawLastUpdated is DateTime) {
      parsedLastUpdated =
          rawLastUpdated.toUtc(); // Use DateTime directly, ensure UTC
    } else if (rawLastUpdated is String) {
      // Try parsing if it's a string
      parsedLastUpdated =
          DateTime.tryParse(rawLastUpdated)?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(
            0,
            isUtc: true,
          ); // Default to epoch on parse failure
    } else {
      // Default to epoch if it's null or some other unexpected type
      if (kDebugMode && rawLastUpdated != null) {
        print(
          '[ChatSession.fromJson] Unexpected type for lastUpdated: ${rawLastUpdated.runtimeType}',
        );
      }
      parsedLastUpdated = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    // Parse messages safely
    List<ChatMessage> parsedMessages = const [];
    final rawMessages = json['messages'];
    if (rawMessages is List) {
      try {
        parsedMessages =
            rawMessages
                .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
                .toList();
      } catch (e) {
        if (kDebugMode) {
          print('[ChatSession.fromJson] Error parsing messages list: $e');
        }
        // Keep parsedMessages as empty list on error
      }
    } else if (rawMessages != null) {
      if (kDebugMode) {
        print(
          '[ChatSession.fromJson] Unexpected type for messages: ${rawMessages.runtimeType}',
        );
      }
    }


    return ChatSession(
      id: json['id'] as String? ?? activeSessionId,
      contextItemId: json['contextItemId'] as String?,
      contextItemType: type,
      contextServerId: json['contextServerId'] as String?,
      messages: parsedMessages,
      lastUpdated: parsedLastUpdated, // Use the safely parsed DateTime
    );
  }

  /* ---------- equality ---------- */

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSession &&
          runtimeType == other.runtimeType && // Added runtimeType check
          id == other.id &&
          contextItemId == other.contextItemId &&
          contextItemType == other.contextItemType &&
          contextServerId == other.contextServerId &&
          const ListEquality().equals(messages, other.messages) &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode => Object.hash(
    runtimeType, // Added runtimeType
    id,
    contextItemId,
    contextItemType,
    contextServerId,
    const ListEquality().hash(messages),
    lastUpdated,
  );
}

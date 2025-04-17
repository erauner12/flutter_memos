import 'package:flutter/foundation.dart'; // For kDebugMode

enum Role { system, user, model, function }

@immutable
class ChatMessage {
  final String id;
  final Role role;
  final String text;
  final DateTime timestamp;
  final bool isError;
  final bool isLoading;
  final String? sourceServerId; // Optional: Track source for MCP messages

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.isError = false,
    this.isLoading = false,
    this.sourceServerId,
  });

  // Factory for loading state
  factory ChatMessage.loading() => ChatMessage(
    id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
    role: Role.model, // Usually model is loading
    text: '', // Empty text for loading
    timestamp: DateTime.now().toUtc(),
    isLoading: true,
  );

  // Factory for error state
  factory ChatMessage.error(String errorMessage) => ChatMessage(
    id: 'error_${DateTime.now().millisecondsSinceEpoch}',
    role: Role.model, // Error usually replaces model response
    text: errorMessage,
    timestamp: DateTime.now().toUtc(),
    isError: true,
  );

  ChatMessage copyWith({
    String? id,
    Role? role,
    String? text,
    DateTime? timestamp,
    bool? isError,
    bool? isLoading,
    String? sourceServerId,
    bool clearSourceServerId = false, // Added option to clear
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
      isLoading: isLoading ?? this.isLoading,
      sourceServerId:
          clearSourceServerId ? null : sourceServerId ?? this.sourceServerId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name, // Store enum name
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'isError': isError,
    'isLoading': isLoading,
    'sourceServerId': sourceServerId,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    Role parsedRole = Role.model; // Default role
    final rawRole = json['role'];
    if (rawRole is String) {
      try {
        parsedRole = Role.values.byName(rawRole);
      } catch (e) {
        if (kDebugMode) {
          print('[ChatMessage.fromJson] Error parsing role "$rawRole": $e');
        }
        // Keep default role
      }
    }

    return ChatMessage(
      id:
          json['id'] as String? ??
          'missing_id_${DateTime.now().millisecondsSinceEpoch}',
      role: parsedRole,
      text: json['text'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      isError: json['isError'] as bool? ?? false,
      isLoading: json['isLoading'] as bool? ?? false,
      sourceServerId: json['sourceServerId'] as String?,
    );
  }

  @override
  String toString() =>
      'ChatMessage(id:$id role:${role.name} text:"$text" ts:$timestamp loading:$isLoading error:$isError source:$sourceServerId)';

  // ADDED Equality Implementation
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          role == other.role &&
          text == other.text &&
          timestamp == other.timestamp &&
          isError == other.isError &&
          isLoading == other.isLoading &&
          sourceServerId == other.sourceServerId;

  // ADDED HashCode Implementation
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    role,
    text,
    timestamp,
    isError,
    isLoading,
    sourceServerId,
  );
}

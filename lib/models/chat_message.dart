import 'package:flutter/foundation.dart';

/// Conversation roles recognised by the app.
enum Role { user, model, system }

@immutable
class ChatMessage {
  final String id;
  final Role role;
  final String text;
  final DateTime timestamp;
  final bool isError;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.isError = false,
    this.isLoading = false,
  });

  /* ---------- factory helpers ---------- */

  /// Placeholder shown while waiting for the model’s reply.
  factory ChatMessage.loading() => ChatMessage(
    id: 'loading_${DateTime.now().microsecondsSinceEpoch}',
    role: Role.model,
    text: '',
    timestamp: DateTime.now().toUtc(),
    isLoading: true,
  );

  /// Convenience constructor for error bubbles.
  factory ChatMessage.error(String text) => ChatMessage(
    id: 'error_${DateTime.now().microsecondsSinceEpoch}',
    role: Role.model,
    text: text,
    timestamp: DateTime.now().toUtc(),
    isError: true,
  );

  /* ---------- immutability ---------- */

  ChatMessage copyWith({
    String? id,
    Role? role,
    String? text,
    DateTime? timestamp,
    bool? isError,
    bool? isLoading,
  }) => ChatMessage(
    id: id ?? this.id,
    role: role ?? this.role,
    text: text ?? this.text,
    timestamp: timestamp ?? this.timestamp,
    isError: isError ?? this.isError,
    isLoading: isLoading ?? this.isLoading,
  );

  /* ---------- (de)serialisation ---------- */

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'isError': isError,
    'isLoading': isLoading,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String? ?? '',
    role: Role.values.byName(json['role'] as String? ?? 'model'),
    text: json['text'] as String? ?? '',
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '')?.toUtc() ??
        DateTime.now().toUtc(),
    isError: json['isError'] as bool? ?? false,
    isLoading: json['isLoading'] as bool? ?? false,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          id == other.id &&
          role == other.role &&
          text == other.text &&
          timestamp == other.timestamp &&
          isError == other.isError &&
          isLoading == other.isLoading;

  @override
  int get hashCode =>
      Object.hash(id, role, text, timestamp, isError, isLoading);

  @override
  String toString() =>
      'ChatMessage(id:$id role:${role.name} len:${text.length} err:$isError load:$isLoading)';
}

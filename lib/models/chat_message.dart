import 'package:collection/collection.dart'; // Import collection package
import 'package:flutter/foundation.dart';
// Remove direct import of google_generative_ai Role if it was attempted
// import 'package:google_generative_ai/google_generative_ai.dart' show Role; // Remove this if present

// Define a local Role enum
enum Role { user, model }

@immutable
class ChatMessage {
  final String id; // Unique ID for the message
  final Role role; // Use the local Role enum
  final String text;
  final DateTime timestamp;
  final bool isError;
  final bool isLoading; // Indicates if this is a placeholder for a loading response

  // Optional fields for MCP/Tool interaction
  final String? toolName;
  final Map<String, dynamic>? toolArgs;
  final String? toolResult; // The raw result from the tool
  final String? sourceServerId; // Which MCP server provided the tool/response

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.isError = false,
    this.isLoading = false,
    this.toolName,
    this.toolArgs,
    this.toolResult,
    this.sourceServerId,
  });

  // copyWith method for updating messages (e.g., appending streamed text)
  ChatMessage copyWith({
    String? id,
    Role? role, // Use the local Role enum
    String? text,
    DateTime? timestamp,
    bool? isError,
    bool? isLoading,
    String? toolName,
    Map<String, dynamic>? toolArgs,
    String? toolResult,
    String? sourceServerId,
    bool clearToolInfo = false, // Flag to explicitly nullify tool fields
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
      isLoading: isLoading ?? this.isLoading,
      toolName: clearToolInfo ? null : toolName ?? this.toolName,
      toolArgs: clearToolInfo ? null : toolArgs ?? this.toolArgs,
      toolResult: clearToolInfo ? null : toolResult ?? this.toolResult,
      sourceServerId: clearToolInfo ? null : sourceServerId ?? this.sourceServerId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          role == other.role && // Compare local Role enum
          text == other.text &&
          timestamp == other.timestamp &&
          isError == other.isError &&
          isLoading == other.isLoading &&
          toolName == other.toolName &&
          // Use MapEquality for comparing maps
          const MapEquality().equals(toolArgs, other.toolArgs) &&
          toolResult == other.toolResult &&
          sourceServerId == other.sourceServerId;

  @override
  int get hashCode =>
      id.hashCode ^
      role.hashCode ^ // Hash local Role enum
      text.hashCode ^
      timestamp.hashCode ^
      isError.hashCode ^
      isLoading.hashCode ^
      toolName.hashCode ^
      // Use MapEquality().hash for map hash code
      const MapEquality().hash(toolArgs) ^
      toolResult.hashCode ^
      sourceServerId.hashCode;

  @override
  String toString() {
    // Use the local enum's toString()
    final roleString = role.toString().split('.').last; // Get 'user' or 'model'
    return 'ChatMessage{id: $id, role: $roleString, text: ${text.substring(0, (text.length > 50 ? 50 : text.length))}..., timestamp: $timestamp, isError: $isError, isLoading: $isLoading, toolName: $toolName}';
  }
}

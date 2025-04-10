import 'package:collection/collection.dart'; // For listEquals
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/chat_message.dart';
import 'package:google_generative_ai/google_generative_ai.dart' show Content;

@immutable
class ChatState {
  // Messages displayed in the UI (includes user, model, loading, errors)
  final List<ChatMessage> displayMessages;
  // History sent to the AI API (typically alternating user/model Content)
  final List<Content> chatHistory;
  final bool isLoading; // Is the AI currently processing a message?
  final String? errorMessage; // Any general error message for the chat
  final bool isApiKeySet; // Is the required API key (e.g., Gemini) configured?

  const ChatState({
    this.displayMessages = const [],
    this.chatHistory = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isApiKeySet = false,
  });

  ChatState copyWith({
    List<ChatMessage>? displayMessages,
    List<Content>? chatHistory,
    bool? isLoading,
    String? errorMessage,
    bool? isApiKeySet,
    bool clearErrorMessage = false, // Flag to explicitly nullify error
  }) {
    return ChatState(
      displayMessages: displayMessages ?? this.displayMessages,
      chatHistory: chatHistory ?? this.chatHistory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      isApiKeySet: isApiKeySet ?? this.isApiKeySet,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is ChatState &&
        listEquals(other.displayMessages, displayMessages) &&
        listEquals(other.chatHistory, chatHistory) &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage &&
        other.isApiKeySet == isApiKeySet;
  }

  @override
  int get hashCode =>
      Object.hash(
        const DeepCollectionEquality().hash(displayMessages),
        const DeepCollectionEquality().hash(chatHistory),
        isLoading,
        errorMessage,
        isApiKeySet,
      );

  @override
  String toString() {
    return 'ChatState{messages: ${displayMessages.length}, history: ${chatHistory.length}, isLoading: $isLoading, error: $errorMessage, apiKeySet: $isApiKeySet}';
  }
}

import 'package:collection/collection.dart'; // For listEquals
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/chat_message.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart'; // For WorkbenchItemType
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

  // Context for the current chat session (if initiated from an item)
  final String? currentContextItemId;
  final WorkbenchItemType? currentContextItemType;
  final String? currentContextServerId;
  final String? currentContextString; // The initial formatted thread content

  const ChatState({
    this.displayMessages = const [],
    this.chatHistory = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isApiKeySet = false,
    this.currentContextItemId,
    this.currentContextItemType,
    this.currentContextServerId,
    this.currentContextString,
  });

  ChatState copyWith({
    List<ChatMessage>? displayMessages,
    List<Content>? chatHistory,
    bool? isLoading,
    String? errorMessage,
    bool? isApiKeySet,
    String? currentContextItemId,
    WorkbenchItemType? currentContextItemType,
    String? currentContextServerId,
    String? currentContextString,
    bool clearErrorMessage = false, // Flag to explicitly nullify error
    bool clearContext = false, // Flag to explicitly nullify context fields
  }) {
    return ChatState(
      displayMessages: displayMessages ?? this.displayMessages,
      chatHistory: chatHistory ?? this.chatHistory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      isApiKeySet: isApiKeySet ?? this.isApiKeySet,
      currentContextItemId:
          clearContext
              ? null
              : currentContextItemId ?? this.currentContextItemId,
      currentContextItemType:
          clearContext
              ? null
              : currentContextItemType ?? this.currentContextItemType,
      currentContextServerId:
          clearContext
              ? null
              : currentContextServerId ?? this.currentContextServerId,
      currentContextString:
          clearContext
              ? null
              : currentContextString ?? this.currentContextString,
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
        other.isApiKeySet == isApiKeySet &&
        other.currentContextItemId == currentContextItemId &&
        other.currentContextItemType == currentContextItemType &&
        other.currentContextServerId == currentContextServerId &&
        other.currentContextString == currentContextString;
  }

  @override
  int get hashCode => Object.hash(
        const DeepCollectionEquality().hash(displayMessages),
        const DeepCollectionEquality().hash(chatHistory),
        isLoading,
        errorMessage,
        isApiKeySet,
    currentContextItemId,
    currentContextItemType,
    currentContextServerId,
    currentContextString,
      );

  @override
  String toString() {
    final contextInfo =
        currentContextItemId != null
            ? ', context: ${currentContextItemType?.name} $currentContextItemId'
            : '';
    return 'ChatState{messages: ${displayMessages.length}, history: ${chatHistory.length}, isLoading: $isLoading, error: $errorMessage, apiKeySet: $isApiKeySet$contextInfo}';
  }
}

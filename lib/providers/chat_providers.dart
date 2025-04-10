import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/chat_message.dart'; // Import ChatMessage which now defines Role
import 'package:flutter_memos/models/chat_state.dart';
import 'package:flutter_memos/providers/settings_provider.dart'; // For API key check
import 'package:flutter_memos/services/gemini_service.dart'; // For Gemini interaction
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Keep for Content, TextPart etc.
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  StreamSubscription<GenerateContentResponse>? _geminiStreamSubscription;

  ChatNotifier(this._ref) : super(const ChatState()) {
    // Initial check for API key status
    _updateApiKeyStatus();
    // Listen for changes in the API key to update status
    _ref.listen(geminiApiKeyProvider, (_, next) {
      _updateApiKeyStatus();
    });
  }

  void _updateApiKeyStatus() {
    final apiKey = _ref.read(geminiApiKeyProvider);
    final bool isSet = apiKey.isNotEmpty;
    if (state.isApiKeySet != isSet) {
      state = state.copyWith(isApiKeySet: isSet);
      debugPrint("ChatNotifier: API Key status updated: $isSet");
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isLoading) {
      return;
    }

    final geminiService = _ref.read(geminiServiceProvider);
    // final mcpState = _ref.read(mcpClientProvider); // Keep commented out

    // Check if Gemini API key is set (required for both direct and MCP-tool flows)
    if (geminiService == null || !geminiService.isInitialized) {
      state = state.copyWith(
        errorMessage: geminiService?.initializationError ?? "Gemini service not available. Please configure the API Key in Settings.",
        isLoading: false,
      );
      return;
    }

    final userMessageId = _uuid.v4();
    final userMessage = ChatMessage(
      id: userMessageId,
      role: Role.user, // Use local Role enum
      text: text,
      timestamp: DateTime.now(),
    );

    // Add user message to display and history
    final currentHistory = List<Content>.from(state.chatHistory);
    final currentDisplayMessages = List<ChatMessage>.from(state.displayMessages);

    currentDisplayMessages.add(userMessage);
    // Convert user message text to Content for history
    // Use 'user' string role for Content API
    currentHistory.add(Content('user', [TextPart(text)]));

    // Add placeholder for model response
    final modelMessageId = _uuid.v4();
    final loadingMessage = ChatMessage(
      id: modelMessageId,
      role: Role.model, // Use local Role enum
      text: '', // Start empty
      timestamp: DateTime.now(),
      isLoading: true,
    );
    currentDisplayMessages.add(loadingMessage);

    // Update state immediately with user message and loading placeholder
    state = state.copyWith(
      displayMessages: currentDisplayMessages,
      chatHistory: currentHistory, // History includes the user message now
      isLoading: true,
      clearErrorMessage: true,
    );

    try {
      // TODO: Implement MCP tool calling logic here if needed
      // if (mcpState.hasActiveConnections) { ... } else {

      // --- Direct Gemini Call (Streaming) ---
      _geminiStreamSubscription?.cancel(); // Cancel previous stream if any

      // Pass the history *before* the current user message
      final historyForApi = List<Content>.from(state.chatHistory);
      // Remove the last added user message before sending to API
      if (historyForApi.isNotEmpty && historyForApi.last.role == 'user') {
         // This assumes the last message added was the user's current input
         // A more robust approach might involve checking the content matches `text`
      } else {
         debugPrint("Warning: Chat history doesn't end with user message as expected.");
      }


      final stream = geminiService.sendMessageStream(text, historyForApi);

      _geminiStreamSubscription = stream.listen(
        (response) {
          // Aggregate text from the stream response
          final aggregatedText = response.text ?? '';
          if (aggregatedText.isNotEmpty) {
            // Find the loading message and update its text
            final messages = List<ChatMessage>.from(state.displayMessages);
            final index = messages.indexWhere((m) => m.id == modelMessageId);
            if (index != -1) {
              messages[index] = messages[index].copyWith(
                text: messages[index].text + aggregatedText, // Append text
                isLoading: true, // Still loading until stream ends
              );
              state = state.copyWith(displayMessages: messages);
            }
          }
          // TODO: Handle potential function calls in response if needed
        },
        onDone: () {
          debugPrint("Gemini stream finished.");
          // Finalize the model message and update history
          final messages = List<ChatMessage>.from(state.displayMessages);
          final index = messages.indexWhere((m) => m.id == modelMessageId);
          if (index != -1) {
            final finalMessage = messages[index].copyWith(isLoading: false);
            messages[index] = finalMessage;

            // Add the complete model response to the chat history
            final updatedHistory = List<Content>.from(state.chatHistory);
            // Ensure the role is 'model' for the history entry
            // Use 'model' string role for Content API
            updatedHistory.add(Content('model', finalMessage.text.isNotEmpty ? [TextPart(finalMessage.text)] : []));


            state = state.copyWith(
              displayMessages: messages,
              chatHistory: updatedHistory,
              isLoading: false,
            );
          } else {
            // Should not happen if placeholder was added correctly
            state = state.copyWith(isLoading: false);
          }
          _geminiStreamSubscription = null;
        },
        onError: (error) {
          debugPrint("Error receiving Gemini stream: $error");
          // Update the placeholder message to show the error
          final messages = List<ChatMessage>.from(state.displayMessages);
          final index = messages.indexWhere((m) => m.id == modelMessageId);
          if (index != -1) {
            messages[index] = messages[index].copyWith(
              text: "Error: ${error.toString()}",
              isError: true,
              isLoading: false,
            );
            state = state.copyWith(
              displayMessages: messages,
              isLoading: false,
              errorMessage: "Failed to get response from AI.",
            );
          } else {
            state = state.copyWith(
              isLoading: false,
              errorMessage: "An error occurred: ${error.toString()}",
            );
          }
          _geminiStreamSubscription = null;
        },
      );
      // } // End of else block for direct Gemini call
    } catch (e) {
      debugPrint("Error sending message: $e");
      // Update placeholder to error state if something went wrong before streaming
      final messages = List<ChatMessage>.from(state.displayMessages);
      final index = messages.indexWhere((m) => m.id == modelMessageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(
          text: "Error: ${e.toString()}",
          isError: true,
          isLoading: false,
        );
        state = state.copyWith(
          displayMessages: messages,
          isLoading: false,
          errorMessage: "Failed to send message.",
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: "An error occurred: ${e.toString()}",
        );
      }
      _geminiStreamSubscription?.cancel();
      _geminiStreamSubscription = null;
    }
  }

  void clearChat() {
    _geminiStreamSubscription?.cancel();
    _geminiStreamSubscription = null;
    state = state.copyWith(
      displayMessages: [],
      chatHistory: [],
      isLoading: false,
      clearErrorMessage: true,
    );
    debugPrint("Chat cleared.");
  }

  // Add method to clear only the error message
  void clearErrorMessage() {
     if (state.errorMessage != null) {
       state = state.copyWith(clearErrorMessage: true);
     }
  }


  @override
  void dispose() {
    _geminiStreamSubscription?.cancel();
    super.dispose();
  }
}

// Provider for the ChatNotifier
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});

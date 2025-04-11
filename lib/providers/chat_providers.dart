import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/chat_message.dart'; // Import ChatMessage which now defines Role
import 'package:flutter_memos/models/chat_state.dart';
import 'package:flutter_memos/providers/settings_provider.dart'; // For API key check
import 'package:flutter_memos/services/gemini_service.dart'; // For Gemini interaction
import 'package:flutter_memos/services/mcp_client_service.dart'; // Import MCP service
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Keep for Content, TextPart etc.
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// Provider for the MCP client service
final mcpClientProvider =
    StateNotifierProvider<McpClientNotifier, McpClientState>((ref) {
      return McpClientNotifier(ref);
    });

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  StreamSubscription<GenerateContentResponse>? _geminiStreamSubscription;

  ChatNotifier(this._ref) : super(const ChatState()) {
    // Delay initial check slightly to allow other providers to initialize
    Future.microtask(() => _updateApiKeyStatus());
    // Listen for changes in the API key to update status
    _ref.listen(geminiApiKeyProvider, (_, next) {
      _updateApiKeyStatus();
    });
  }

  // Helper to extract text from Content object
  String getTextFromContent(Content? content) {
    if (content == null) return "";
    // Ensure parts is not null and handle potential non-TextPart elements gracefully
    return content.parts
            .whereType<TextPart>()
        .map((part) => part.text) // No need for null check with whereType
        .join(''); // Use empty string join
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
    final mcpClientNotifier = _ref.read(
      mcpClientProvider.notifier,
    ); // Get notifier
    final mcpState = _ref.read(mcpClientProvider); // Get current state

    // *** ADD LOGGING HERE ***
    debugPrint(
      "ChatNotifier: Checking MCP state. hasActiveConnections: ${mcpState.hasActiveConnections}",
    );

    // Check if Gemini API key is set (required for fallback)
    // We assume MCP servers might function independently or use other models later
    if (geminiService == null || !geminiService.isInitialized) {
      // Allow proceeding if MCP is active, otherwise show Gemini error
      if (!mcpState.hasActiveConnections) {
        state = state.copyWith(
          errorMessage:
              geminiService?.initializationError ??
              "Gemini service not available. Please configure the API Key in Settings.",
          isLoading: false,
        );
        return;
      }
      // If MCP is active, we might not need Gemini immediately, log a warning
      debugPrint(
        "ChatNotifier: Gemini service not ready, but MCP is active. Proceeding with MCP.",
      );
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
      // Decide whether to use MCP or direct Gemini
      if (mcpState.hasActiveConnections) {
        // --- Use MCP Client ---
        debugPrint("ChatNotifier: Processing query via MCP Client(s)...");
        // Pass the history *before* the current user message
        final historyForMcp = List<Content>.from(state.chatHistory);
        // Remove the last user message added in this function call
        if (historyForMcp.isNotEmpty && historyForMcp.last.role == 'user') {
          historyForMcp.removeLast();
        }

        final McpProcessResult mcpResult = await mcpClientNotifier.processQuery(
          text,
          historyForMcp,
        );

        // Process the result from MCP (which contains the echo)
        final String finalText = getTextFromContent(
          mcpResult.finalModelContent,
        ); // Use helper

        // Find the loading message and update it
        final messages = List<ChatMessage>.from(state.displayMessages);
        final index = messages.indexWhere((m) => m.id == modelMessageId);
        if (index != -1) {
          final bool isResultError = finalText.startsWith(
            "Error:",
          ); // Simple check
          messages[index] = messages[index].copyWith(
            text: finalText.isEmpty ? "(No text content from MCP)" : finalText,
            isLoading: false,
            isError: isResultError,
            // Add tool info if needed for display
            toolName: mcpResult.toolName,
            sourceServerId: mcpResult.sourceServerId,
            // toolArgs: jsonEncode(mcpResult.toolArgs), // Example if needed
            // toolResult: mcpResult.toolResult, // Example if needed
          );

          // Update chat history including intermediate steps for context
          final List<Content> finalHistory = [
            ...historyForMcp, // History before user message
            Content('user', [TextPart(text)]), // User message
          ];
          // Add model's function call request if it exists
          if (mcpResult.modelCallContent != null) {
            finalHistory.add(mcpResult.modelCallContent!);
          }
          // Add the tool's response if it exists
          if (mcpResult.toolResponseContent != null) {
            finalHistory.add(mcpResult.toolResponseContent!);
          }
          // Add the final model summary (already in finalModelContent)
          // Ensure it has the 'model' role
          if (mcpResult.finalModelContent.role != 'model') {
            // This case shouldn't happen based on McpClientService logic, but safety check
            final textParts =
                mcpResult.finalModelContent.parts
                    .whereType<TextPart>()
                    .toList();
            finalHistory.add(Content('model', textParts));
            debugPrint(
              "ChatNotifier Warning: finalModelContent from MCP had unexpected role: ${mcpResult.finalModelContent.role}",
            );
          } else {
            finalHistory.add(mcpResult.finalModelContent);
          }


          state = state.copyWith(
            displayMessages: messages,
            chatHistory: finalHistory,
            isLoading: false,
          );
        } else {
          debugPrint(
            "ChatNotifier Error: Could not find loading message placeholder (ID: $modelMessageId) after MCP call.",
          );
          state = state.copyWith(isLoading: false); // Fallback
        }
      } else {
        // --- Use Direct Gemini (Streaming) ---
        debugPrint(
          "ChatNotifier: No active MCP server. Processing query via Direct Gemini Stream...",
        );

        // Ensure Gemini service is ready before proceeding with direct call
        if (geminiService == null || !geminiService.isInitialized) {
          throw Exception(
            geminiService?.initializationError ??
                "Gemini service not available for direct call.",
          );
        }

        _geminiStreamSubscription?.cancel(); // Cancel previous stream if any

        // Pass the history *before* the current user message
        final historyForGemini = List<Content>.from(state.chatHistory);
        // Remove the last added user message before sending to API
        if (historyForGemini.isNotEmpty &&
            historyForGemini.last.role == 'user') {
          historyForGemini.removeLast();
        } else {
          debugPrint(
            "Warning: Chat history doesn't end with user message as expected before Gemini call.",
          );
        }

        final stream = geminiService.sendMessageStream(text, historyForGemini);

        _geminiStreamSubscription = stream.listen(
          (response) {
            // Aggregate text from the stream response
            // Use helper to handle potential null parts or non-text parts
            final chunkText = response.text ?? '';
            if (chunkText.isNotEmpty) {
              // Find the loading message and update its text
              final messages = List<ChatMessage>.from(state.displayMessages);
              final index = messages.indexWhere((m) => m.id == modelMessageId);
              if (index != -1) {
                messages[index] = messages[index].copyWith(
                  text: messages[index].text + chunkText, // Append text
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
              // Use helper to get text, handle empty case
              final modelText = getTextFromContent(
                Content('model', [TextPart(finalMessage.text)]),
              );
              updatedHistory.add(
                Content(
                  'model',
                  modelText.isNotEmpty ? [TextPart(modelText)] : [],
                ),
              );

              state = state.copyWith(
                displayMessages: messages,
                chatHistory: updatedHistory,
                isLoading: false,
              );
            } else {
              // Should not happen if placeholder was added correctly
              debugPrint(
                "ChatNotifier Error: Could not find loading message placeholder (ID: $modelMessageId) on Gemini stream done.",
              );
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
          cancelOnError: true,
        );
      } // End of else block for direct Gemini call
    } catch (e) {
      debugPrint("Error sending message: $e");
      // Update placeholder to error state if something went wrong before streaming/MCP call
      final messages = List<ChatMessage>.from(state.displayMessages);
      final index = messages.indexWhere((m) => m.id == modelMessageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(
          text: "Error processing message: ${e.toString()}",
          isError: true,
          isLoading: false,
        );
        state = state.copyWith(
          displayMessages: messages,
          isLoading: false,
          errorMessage: "Failed to process message.",
        );
      } else {
        // If placeholder wasn't even added, set general error
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

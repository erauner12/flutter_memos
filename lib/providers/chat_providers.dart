import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/chat_message.dart'; // Import ChatMessage which now defines Role
import 'package:flutter_memos/models/chat_state.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart'; // For WorkbenchItemType
import 'package:flutter_memos/providers/settings_provider.dart'; // For API key check
import 'package:flutter_memos/services/gemini_service.dart'; // For Gemini interaction
import 'package:flutter_memos/services/mcp_client_service.dart'; // Import MCP service
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Keep for Content, TextPart etc.
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

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

  /// Starts a new chat session with context from a specific item thread.
  /// Clears any existing chat history and context.
  void startChatWithContext({
    required String contextString,
    required String parentItemId,
    required WorkbenchItemType parentItemType,
    required String parentServerId,
  }) {
    debugPrint(
      "ChatNotifier: Starting chat with context for ${parentItemType.name} $parentItemId",
    );
    // Cancel any ongoing stream
    _geminiStreamSubscription?.cancel();
    _geminiStreamSubscription = null;

    // Clear previous state and set new context
    state = state.copyWith(
      displayMessages: [],
      chatHistory: [],
      isLoading: false,
      clearErrorMessage: true,
      clearContext:
          false, // Explicitly don't clear context here, we are setting it
      currentContextItemId: parentItemId,
      currentContextItemType: parentItemType,
      currentContextServerId: parentServerId,
      currentContextString: contextString,
    );

    // Optionally add an initial system message to display?
    // final initialSystemMessage = ChatMessage(
    //   id: _uuid.v4(),
    //   role: Role.system, // Assuming Role.system exists or use Role.model
    //   text: "Chatting about ${parentItemType.name} $parentItemId...",
    //   timestamp: DateTime.now(),
    // );
    // state = state.copyWith(displayMessages: [initialSystemMessage]);
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

    debugPrint(
      "ChatNotifier: Checking MCP state. hasActiveConnections: ${mcpState.hasActiveConnections}",
    );
    if (mcpState.hasActiveConnections && kDebugMode) {
      final activeStatuses =
          mcpState.serverStatuses.entries
              .where((e) => e.value == McpConnectionStatus.connected)
              .map((e) => e.key)
              .toList();
      debugPrint("ChatNotifier: Active MCP server IDs: $activeStatuses");
    }

    if (geminiService == null || !geminiService.isInitialized) {
      if (!mcpState.hasActiveConnections) {
        state = state.copyWith(
          errorMessage:
              geminiService?.initializationError ??
              "Gemini service not available. Please configure the API Key in Settings.",
          isLoading: false,
        );
        return;
      }
      debugPrint(
        "ChatNotifier: Gemini service not ready, but MCP is active. Proceeding with MCP.",
      );
    }

    // --- Context Injection Logic ---
    String messageToSend = text; // Start with the user's raw input
    bool isFirstMessageInContext = false;

    // Check if this is the first message in a contextual chat
    if (state.currentContextItemId != null &&
        state.currentContextString != null &&
        state.chatHistory.isEmpty) {
      // History is empty before adding this user message
      isFirstMessageInContext = true;
      final contextHeader =
          "Context for ${state.currentContextItemType?.name} ${state.currentContextItemId}:\n---\n";
      final contextFooter = "\n---\nUser Query: ";
      // Prepend the stored context string to the user's message for the AI
      messageToSend =
          "$contextHeader${state.currentContextString}$contextFooter$text";
      debugPrint(
        "ChatNotifier: Prepending context for the first message in this session.",
      );
    }
    // --- End Context Injection Logic ---


    // *** ADD TODOIST CONTEXT ***
    const String todoistContext = """
  Todoist Filter Reference (Examples):
  - `today`: Tasks due today.
  - `overdue`: Tasks past their due date.
  - `p1`, `p2`, `p3`, `p4`: Filter by priority.
  - `#ProjectName`: Tasks in a specific project.
  - `##ParentProject`: Tasks in a project and its sub-projects.
  - `@labelName`: Tasks with a specific label.
  - `7 days`: Tasks due in the next 7 days.
  - `no date`: Tasks without a due date.
  - `search: keyword`: Tasks containing a keyword.
  - Combine with `&` (AND), `|` (OR), `!` (NOT), `()` (grouping). Example: `(today | overdue) & #Work`

  Todoist Date Reference (Examples):
  - `today`, `tomorrow`, `next monday`, `Jan 27`, `in 3 weeks`
  - `every day`, `every other week`, `every 3rd friday`, `every! day` (repeats from completion date)
  - `starting tomorrow`, `until Dec 31`, `for 3 weeks`
  - `at 5pm`, `for 2h` (duration)
  """;

    // Combine Todoist context with the potentially context-prepended message
    final String messageWithAllContext = "$todoistContext\n\n$messageToSend";
    // *** END TODOIST CONTEXT ***

    final userMessageId = _uuid.v4();
    final userMessage = ChatMessage(
      id: userMessageId,
      role: Role.user, // Use local Role enum
      // Display the original user text, NOT the context-prepended version
      text: text,
      timestamp: DateTime.now(),
    );

    // Add user message to display and history
    final currentHistory = List<Content>.from(state.chatHistory);
    final currentDisplayMessages = List<ChatMessage>.from(state.displayMessages);

    currentDisplayMessages.add(userMessage);
    // Add the message *with all context* (Todoist + potentially item thread) to the history sent to the AI
    currentHistory.add(Content('user', [TextPart(messageWithAllContext)]));

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
        // Pass the history *before* the current user message (with all context)
        final historyForMcp = List<Content>.from(state.chatHistory);
        if (historyForMcp.isNotEmpty && historyForMcp.last.role == 'user') {
          historyForMcp.removeLast();
        }

        // Pass the message *with all context* to processQuery
        final McpProcessResult mcpResult = await mcpClientNotifier.processQuery(
          messageWithAllContext,
          historyForMcp,
        );

        // Process the result from MCP
        final String finalText = getTextFromContent(
          mcpResult.finalModelContent,
        );

        // Find the loading message and update it
        final messages = List<ChatMessage>.from(state.displayMessages);
        final index = messages.indexWhere((m) => m.id == modelMessageId);
        if (index != -1) {
          final bool isResultError = finalText.startsWith("Error:");
          messages[index] = messages[index].copyWith(
            text: finalText.isEmpty ? "(No text content from MCP)" : finalText,
            isLoading: false,
            isError: isResultError,
            toolName: mcpResult.toolName,
            sourceServerId: mcpResult.sourceServerId,
          );

          // Update chat history including intermediate steps
          final List<Content> finalHistory = [
            ...historyForMcp, // History before user message
            Content('user', [
              TextPart(messageWithAllContext),
            ]), // User message (with all context)
          ];
          if (mcpResult.modelCallContent != null) {
            // Ensure role is 'model'
            final role =
                mcpResult.modelCallContent!.role == 'model' ? 'model' : 'model';
            if (mcpResult.modelCallContent!.role != 'model') {
              debugPrint(
                "ChatNotifier Warning: MCP modelCallContent role was ${mcpResult.modelCallContent!.role}, forcing 'model'.",
              );
            }
            finalHistory.add(Content(role, mcpResult.modelCallContent!.parts));
          }
          if (mcpResult.toolResponseContent != null) {
            // Ensure role is 'function' (or 'tool')
            final role =
                mcpResult.toolResponseContent!.role == 'function'
                    ? 'function'
                    : 'function';
            if (mcpResult.toolResponseContent!.role != 'function') {
              debugPrint(
                "ChatNotifier Warning: MCP toolResponseContent role was ${mcpResult.toolResponseContent!.role}, forcing 'function'.",
              );
            }
            finalHistory.add(
              Content(role, mcpResult.toolResponseContent!.parts),
            );
          }
          if (mcpResult.finalModelContent.parts.isNotEmpty) {
            // Ensure role is 'model'
            final role =
                mcpResult.finalModelContent.role == 'model' ? 'model' : 'model';
            if (mcpResult.finalModelContent.role != 'model') {
              debugPrint(
                "ChatNotifier Warning: MCP finalModelContent role was ${mcpResult.finalModelContent.role}, forcing 'model'.",
              );
            }
            finalHistory.add(Content(role, mcpResult.finalModelContent.parts));
          } else {
            debugPrint(
              "ChatNotifier Info: finalModelContent from MCP was empty. Not adding to history.",
            );
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

        if (geminiService == null || !geminiService.isInitialized) {
          throw Exception(
            geminiService?.initializationError ??
                "Gemini service not available for direct call.",
          );
        }

        _geminiStreamSubscription?.cancel();

        // Pass the history *before* the current user message (with all context)
        final historyForGemini = List<Content>.from(state.chatHistory);
        if (historyForGemini.isNotEmpty &&
            historyForGemini.last.role == 'user') {
          historyForGemini.removeLast();
        } else {
          debugPrint(
            "Warning: Chat history doesn't end with user message as expected before Gemini call.",
          );
        }

        // Pass the message *with all context* to sendMessageStream
        final stream = geminiService.sendMessageStream(
          messageWithAllContext,
          historyForGemini,
        );

        _geminiStreamSubscription = stream.listen(
          (response) {
            final chunkText = response.text ?? '';
            if (chunkText.isNotEmpty) {
              final messages = List<ChatMessage>.from(state.displayMessages);
              final index = messages.indexWhere((m) => m.id == modelMessageId);
              if (index != -1) {
                messages[index] = messages[index].copyWith(
                  text: messages[index].text + chunkText,
                  isLoading: true,
                );
                state = state.copyWith(displayMessages: messages);
              }
            }
          },
          onDone: () {
            debugPrint("Gemini stream finished.");
            final messages = List<ChatMessage>.from(state.displayMessages);
            final index = messages.indexWhere((m) => m.id == modelMessageId);
            if (index != -1) {
              final finalMessage = messages[index].copyWith(isLoading: false);
              messages[index] = finalMessage;

              // Add the complete model response to the chat history
              // History already contains the user message with all context
              final updatedHistory = List<Content>.from(state.chatHistory);
              final modelText = getTextFromContent(
                Content('model', [TextPart(finalMessage.text)]),
              );
              // Only add if there's actual text content
              if (modelText.isNotEmpty) {
                updatedHistory.add(Content('model', [TextPart(modelText)]));
              } else {
                debugPrint(
                  "ChatNotifier Info: Gemini final message was empty. Not adding to history.",
                );
              }


              state = state.copyWith(
                displayMessages: messages,
                chatHistory: updatedHistory,
                isLoading: false,
              );
            } else {
              debugPrint(
                "ChatNotifier Error: Could not find loading message placeholder (ID: $modelMessageId) on Gemini stream done.",
              );
              state = state.copyWith(isLoading: false);
            }
            _geminiStreamSubscription = null;
          },
          onError: (error) {
            debugPrint("Error receiving Gemini stream: $error");
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
    } catch (e, s) {
      debugPrint("Error sending message: $e\n$s");
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
        state = state.copyWith(
          isLoading: false,
          errorMessage: "An error occurred: ${e.toString()}",
        );
      }
      _geminiStreamSubscription?.cancel();
      _geminiStreamSubscription = null;
    }
  }

  /// Clears the chat history, display messages, error message, and any active context.
  void clearChat() {
    _geminiStreamSubscription?.cancel();
    _geminiStreamSubscription = null;
    state = state.copyWith(
      displayMessages: [],
      chatHistory: [],
      isLoading: false,
      clearErrorMessage: true,
      clearContext: true, // Ensure context fields are cleared
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

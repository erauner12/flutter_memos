import 'package:flutter_memos/services/mcp_client_service.dart'
    show McpClientNotifier, McpProcessResult;
import 'package:flutter_memos/services/minimal_openai_service.dart';
import 'package:flutter_memos/utils/logger.dart'; // Assuming logger exists
import 'package:google_generative_ai/google_generative_ai.dart' as gen_ai;

/// Response returned by any AI backend.
class ChatAiResponse {
  final String text;
  final List<gen_ai.Content> toolTrace; // Keep for MCP compatibility for now
  ChatAiResponse({required this.text, this.toolTrace = const []});
}

/// Uniform interface for AI backends.
abstract interface class ChatAiBackend {
  Future<ChatAiResponse> send(
    List<gen_ai.Content>
    history, // Still uses Google's Content type for interface consistency
    String userMessage,
  );
}

/// Strategy selector between a default AI backend (now OpenAI) and MCP.
class ChatAiFacade implements ChatAiBackend {
  ChatAiFacade({
    required this.defaultBackend, // Renamed from geminiBackend
    required this.mcpNotifier,
  });

  /// The primary AI backend (e.g., OpenAiGptBackend)
  final ChatAiBackend defaultBackend;
  final McpClientNotifier mcpNotifier;

  @override
  Future<ChatAiResponse> send(
      List<gen_ai.Content> history, String userMessage) async {
    if (mcpNotifier.hasActiveConnections) {
      // If MCP is active, use the MCP proxy
      return McpAiProxy(mcpNotifier).send(history, userMessage);
    }
    // Otherwise, use the default backend (OpenAI)
    return defaultBackend.send(history, userMessage);
  }
}

/// NEW: Backend implementation for OpenAI GPT models using Chat Completions.
class OpenAiGptBackend implements ChatAiBackend {
  final MinimalOpenAiService _service;
  final String defaultModel;
  final Logger _logger = const Logger('OpenAiGptBackend'); // Add logger

  OpenAiGptBackend(
    this._service, {
    this.defaultModel = 'gpt-4o',
  }); // Default to gpt-4o

  @override
  Future<ChatAiResponse> send(
      List<gen_ai.Content> history, String userMessage) async {

    // 1. Convert gen_ai.Content history to List<OpenAiChatMessage>
    final List<OpenAiChatMessage> openAiMessages = [];
    for (final content in history) {
      // Extract text from parts
      final textPart =
          content.parts.whereType<gen_ai.TextPart>().map((p) => p.text).join();

      if (textPart.isEmpty) {
        _logger.info(
          'Skipping history item with no text content. Role: ${content.role}',
        );
        continue; // Skip if no text
      }

      // Map roles: Google's 'model' -> OpenAI's 'assistant'
      final String openAiRole;
      switch (content.role) {
        case 'user':
          openAiRole = 'user';
          break;
        case 'model':
          openAiRole = 'assistant';
          break;
        case 'system': // Pass system role through
          openAiRole = 'system';
          break;
        // case 'function': // Google's FunctionCall/FunctionResponse map differently
        //   // Decide how to handle function calls/responses if needed.
        //   // For now, we might skip them or try a basic mapping.
        //   _logger.info('Skipping function role during conversion.');
        //   continue; // Skip function parts for now
        default:
          // Handle Gemini specific roles if necessary, or treat as user/assistant
          _logger.info(
            'Unhandled role "${content.role}" during conversion, treating as user.',
          );
          openAiRole = 'user'; // Default fallback or skip
        // continue;
      }
      openAiMessages.add(
        OpenAiChatMessage(role: openAiRole, content: textPart),
      );
    }

    // 2. Add the current user message
    openAiMessages.add(OpenAiChatMessage(role: 'user', content: userMessage));

    // 3. Call the service
    try {
      final responseText = await _service.createChatCompletion(
        openAiMessages,
        model: defaultModel,
        // Add temperature, maxTokens etc. if needed
      );
      // 4. Return response (toolTrace is empty for direct OpenAI calls)
      return ChatAiResponse(text: responseText, toolTrace: const []);
    } catch (e) {
      _logger.error('Error calling OpenAI service: $e');
      // Re-throw or handle as needed, maybe return an error response
      // For simplicity, rethrowing for now. ChatNotifier should catch it.
      rethrow;
    }
  }
}


/// Adapter to invoke MCP and map result to ChatAiResponse.
/// (No changes needed here, but kept for context)
class McpAiProxy implements ChatAiBackend {
  McpAiProxy(this._mcp);
  final McpClientNotifier _mcp;

  @override
  Future<ChatAiResponse> send(
      List<gen_ai.Content> history, String userMessage) async {
    // MCP uses google_generative_ai types internally for now
    final McpProcessResult result = await _mcp.processQuery(
      userMessage,
      history,
    );

    // Flatten text parts from the final model content
    final String finalText =
        result.finalModelContent.parts
        .whereType<gen_ai.TextPart>()
        .map((p) => p.text)
        .join();

    // Build tool trace using google_generative_ai types
    final List<gen_ai.Content> trace = <gen_ai.Content>[];
    if (result.modelCallContent != null) {
      trace.add(result.modelCallContent!);
    }
    if (result.toolResponseContent != null) {
      trace.add(result.toolResponseContent!);
    }
    // Ensure finalModelContent is added even if others are null
    trace.add(result.finalModelContent);

    return ChatAiResponse(text: finalText, toolTrace: trace);
  }
}

// --- REMOVED GeminiAi class ---
// class GeminiAi implements ChatAiBackend { ... }

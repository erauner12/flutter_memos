import 'package:flutter_memos/services/mcp_client_service.dart' show McpClientNotifier;
import 'package:google_generative_ai/google_generative_ai.dart' as gen_ai;

/// Response returned by any AI backend.
class ChatAiResponse {
  final String text;
  final List<gen_ai.Content> toolTrace;
  ChatAiResponse({required this.text, this.toolTrace = const []});
}

/// Uniform interface for AI backends.
abstract interface class ChatAiBackend {
  Future<ChatAiResponse> send(
    List<gen_ai.Content> history,
    String userMessage,
  );
}

/// Strategy selector between Gemini and MCP.
class ChatAiFacade implements ChatAiBackend {
  ChatAiFacade({
    required this.geminiBackend,
    required this.mcpNotifier,
  });
  final GeminiAi geminiBackend;
  final McpClientNotifier mcpNotifier;

  @override
  Future<ChatAiResponse> send(
      List<gen_ai.Content> history, String userMessage) async {
    if (mcpNotifier.state.hasActiveConnections) {
      return McpAiProxy(mcpNotifier).send(history, userMessage);
    }
    return geminiBackend.send(history, userMessage);
  }
}

/// Adapter for direct Gemini calls.
class GeminiAi implements ChatAiBackend {
  final gen_ai.GenerativeModel _model;
  GeminiAi({required gen_ai.GenerativeModel model}) : _model = model;

  @override
  Future<ChatAiResponse> send(
      List<gen_ai.Content> history, String userMessage) async {
    final request = gen_ai.Content('user', [gen_ai.TextPart(userMessage)]);
    final response = await _model.generateContent([...history, request]);
    final text = response.candidates.firstOrNull?.content.parts
            .whereType<gen_ai.TextPart>()
            .map((p) => p.text)
            .join() ??
        '';
    return ChatAiResponse(text: text);
  }
}

/// Adapter to invoke MCP and map result to ChatAiResponse.
class McpAiProxy implements ChatAiBackend {
  McpAiProxy(this._mcp);
  final McpClientNotifier _mcp;

  @override
  Future<ChatAiResponse> send(
      List<gen_ai.Content> history, String userMessage) async {
    final result = await _mcp.processQuery(userMessage, history);
    // Flatten text parts
    final finalText = result.finalModelContent.parts
        .whereType<gen_ai.TextPart>()
        .map((p) => p.text)
        .join();
    // Build tool trace
    final trace = <gen_ai.Content>[];
    if (result.modelCallContent != null) {
      trace.add(result.modelCallContent!);
    }
    if (result.toolResponseContent != null) {
      trace.add(result.toolResponseContent!);
    }
    trace.add(result.finalModelContent);
    return ChatAiResponse(text: finalText, toolTrace: trace);
  }
}

import 'package:flutter_memos/services/chat_ai.dart';
import 'package:flutter_memos/services/mcp_client_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gen_ai;
import 'package:mockito/mockito.dart';

class MockGeminiBackend extends Mock implements ChatAiBackend {}
class MockMcpNotifier extends Mock implements McpClientNotifier {}

void main() {
  late MockGeminiBackend gemini;
  late MockMcpNotifier mcpNotifier;
  late ChatAiFacade facade;
  final history = <gen_ai.Content>[];
  const userMsg = 'hello';

  setUp(() {
    gemini = MockGeminiBackend();
    mcpNotifier = MockMcpNotifier();
    facade = ChatAiFacade(
      geminiBackend: gemini,
      mcpNotifier: mcpNotifier,
    );
  });

  test('uses MCP when activeConnections is true', () async {
    // Stub direct property, not nested state, to route to MCP
    when(mcpNotifier.hasActiveConnections).thenReturn(true);
    when(mcpNotifier.state).thenReturn(
      const McpClientState(serverStatuses: {'id': McpConnectionStatus.connected}),
    );
    when(
      gemini.send(any<List<gen_ai.Content>>(), any<String>()),
    ).thenThrow(Exception('should not call'));
    when(
      mcpNotifier.processQuery(any<String>(), any<List<gen_ai.Content>>()),
    ).thenAnswer(
      (_) async =>
          McpProcessResult(finalModelContent: gen_ai.Content.text('mcp')),
    );

    final resp = await facade.send(history, userMsg);
    expect(resp.text, 'mcp');
  });

  test('falls back to Gemini when no MCP', () async {
    when(mcpNotifier.state).thenReturn(
      const McpClientState(serverStatuses: {'id': McpConnectionStatus.disconnected}),
    );
    when(mcpNotifier.state.hasActiveConnections).thenReturn(false);
    when(
      gemini.send(any<List<gen_ai.Content>>(), any<String>()),
    )
        .thenAnswer((_) async => ChatAiResponse(text: 'gemini'));

    final resp = await facade.send(history, userMsg);
    expect(resp.text, 'gemini');
  });
}

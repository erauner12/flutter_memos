import 'package:flutter_memos/services/chat_ai.dart';
import 'package:flutter_memos/services/mcp_client_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gen_ai;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Use annotation to generate proper mocks
@GenerateNiceMocks([
  MockSpec<ChatAiBackend>(),
  MockSpec<McpClientNotifier>(),
])
import 'chat_ai_facade_test.mocks.dart';

void main() {
  late MockChatAiBackend gemini;
  late MockMcpClientNotifier mcpNotifier;
  late ChatAiFacade facade;
  final history = <gen_ai.Content>[gen_ai.Content.text('history content')]; // Non-empty history
  const userMsg = 'hello';

  setUp(() {
    gemini = MockChatAiBackend();
    mcpNotifier = MockMcpClientNotifier();
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
    
    // Using Mockito's typed matchers to avoid null dereferencing
    when(gemini.send(any, any))
        .thenThrow(Exception('should not call'));
        
    // Create an actual McpProcessResult for the response
    final mockResult = McpProcessResult(
        finalModelContent: gen_ai.Content.text('mcp')
    );
    
    when(mcpNotifier.processQuery(any, any))
        .thenAnswer((_) async => mockResult);

    final resp = await facade.send(history, userMsg);
    expect(resp.text, 'mcp');
  });

  test('falls back to Gemini when no MCP', () async {
    when(mcpNotifier.hasActiveConnections).thenReturn(false);
    when(mcpNotifier.state).thenReturn(
      const McpClientState(serverStatuses: {'id': McpConnectionStatus.disconnected}),
    );
    
    // Using proper matcher with explicit type to avoid null derefence
    when(gemini.send(any, any))
        .thenAnswer((_) async => ChatAiResponse(text: 'gemini'));

    final resp = await facade.send(history, userMsg);
    expect(resp.text, 'gemini');
  });
}

import 'package:flutter_memos/providers/chat_providers.dart' show ChatNotifier;
import 'package:flutter_memos/providers/chat_providers.dart' show chatProvider;
import 'package:flutter_memos/providers/service_providers.dart';
import 'package:flutter_memos/services/chat_ai.dart';
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_memos/services/gemini_service.dart';
import 'package:flutter_memos/services/mcp_client_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for accessing the CloudKitService instance.
final cloudKitServiceProvider = Provider<CloudKitService>((ref) {
  return CloudKitService();
}, name: 'cloudKitService');

/// Facade between Gemini and MCP backends.
final chatAiFacadeProvider = Provider<ChatAiBackend>((ref) {
  final geminiService = ref.read(geminiServiceProvider)!;
  final gemini = GeminiAi(model: geminiService.model!);
  final mcpNotifier = ref.read(mcpClientProvider.notifier);
  return ChatAiFacade(geminiBackend: gemini, mcpNotifier: mcpNotifier);
});

/// Update chatProvider to inject ChatAiBackend.
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(
    ref,
    ref.read(localStorageServiceProvider),
    ref.read(chatSessionCloudKitServiceProvider),
    ai: ref.read(chatAiFacadeProvider),
  );
});

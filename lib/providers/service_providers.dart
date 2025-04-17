import 'package:flutter_memos/services/chat_ai.dart';
import 'package:flutter_memos/services/chat_session_cloud_kit_service.dart'; // Import for ChatSessionCloudKitService
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_memos/services/gemini_service.dart';
import 'package:flutter_memos/services/local_storage_service.dart'; // Import for LocalStorageService
import 'package:flutter_memos/services/mcp_client_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for accessing the CloudKitService instance.
final cloudKitServiceProvider = Provider<CloudKitService>((ref) {
  return CloudKitService();
}, name: 'cloudKitService');

/// Provider for the LocalStorageService instance.
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
}, name: 'localStorageService');

/// Provider for the ChatSessionCloudKitService instance.
final chatSessionCloudKitServiceProvider = Provider<ChatSessionCloudKitService>(
  (ref) {
    return ChatSessionCloudKitService();
  },
  name: 'chatSessionCloudKitService',
);

/// Facade between Gemini and MCP backends.
final chatAiFacadeProvider = Provider<ChatAiBackend>((ref) {
  final geminiService = ref.read(geminiServiceProvider)!;
  final gemini = GeminiAi(model: geminiService.model!);
  final mcpNotifier = ref.read(mcpClientProvider.notifier);
  return ChatAiFacade(geminiBackend: gemini, mcpNotifier: mcpNotifier);
});

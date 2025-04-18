// Add these imports to fix the errors
import 'package:flutter_memos/services/chat_ai.dart'; // Import for ChatAiBackend, ChatAiFacade
import 'package:flutter_memos/services/chat_session_cloud_kit_service.dart'; // Import for ChatSessionCloudKitService
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_memos/services/local_storage_service.dart'; // Import for LocalStorageService
import 'package:flutter_memos/services/mcp_client_service.dart';
import 'package:flutter_memos/services/minimal_openai_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for accessing the CloudKitService instance.
final cloudKitServiceProvider = Provider<CloudKitService>((ref) {
  return CloudKitService();
}, name: 'cloudKitService');

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

// / Facade between OpenAI and MCP backends.
final chatAiFacadeProvider = Provider<ChatAiBackend>((ref) {
  // Create the OpenAI backend, providing the MinimalOpenAiService instance
  final openAiBackend = OpenAiGptBackend(
    ref.watch(minimalOpenAiServiceProvider),
    // Optionally configure defaultModel: 'gpt-4' or 'gpt-4o' here if needed
    // defaultModel: 'gpt-4o',
  );

  // Get the MCP Notifier
  final mcpNotifier = ref.read(mcpClientProvider.notifier);

  // Return the Facade, using openAiBackend as the default
  return ChatAiFacade(defaultBackend: openAiBackend, mcpNotifier: mcpNotifier);
});

/// Provide a single instance of MinimalOpenAiService for the app.
final minimalOpenAiServiceProvider = Provider<MinimalOpenAiService>((ref) {
  // You can optionally configure or do a health check here
  final service = MinimalOpenAiService();
  // Example: Configure with an API key from environment or secure storage
  // final apiKey = ref.watch(apiKeyProvider); // Assuming an apiKeyProvider exists
  // if (apiKey.isNotEmpty) {
  //   service.configureService(authToken: apiKey);
  // }
  return service;
}, name: 'minimalOpenAiService'); // Added name for clarity

/// Provide a single instance of McpClientNotifier
final mcpClientProvider =
    StateNotifierProvider<McpClientNotifier, McpClientState>(
      (ref) => McpClientNotifier(ref),
      name: 'mcpClient', // Added name for clarity
    );

// --- Removed old providers ---
// If these providers are defined elsewhere (like in chat_providers.dart),
// they should be removed from this file to avoid conflicts.
// If they are truly unused, they can be deleted entirely.

// final cloudKitServiceProvider = Provider<CloudKitService>((ref) { ... });
// final localStorageServiceProvider = Provider<LocalStorageService>((ref) { ... });
// final chatSessionCloudKitServiceProvider = Provider<ChatSessionCloudKitService>((ref) { ... });
// final chatAiFacadeProvider = Provider<ChatAiBackend>((ref) { ... }); // This is now in chat_providers.dart
// final geminiServiceProvider = Provider<GeminiService?>((ref) { ... }); // Assuming GeminiService is removed or handled differently

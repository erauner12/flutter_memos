// Add these imports to fix the errors
import 'package:flutter_memos/services/chat_ai.dart'; // Import for ChatAiBackend, ChatAiFacade
// Removed CloudKit service imports
// import 'package:flutter_memos/services/chat_session_cloud_kit_service.dart';
// import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_memos/services/local_storage_service.dart'; // Import for LocalStorageService
import 'package:flutter_memos/services/mcp_client_service.dart';
import 'package:flutter_memos/services/minimal_openai_service.dart';
import 'package:flutter_memos/services/supabase_data_service.dart'; // Import SupabaseDataService
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Removed CloudKit Providers ---
// final cloudKitServiceProvider = Provider<CloudKitService>((ref) { ... });
// final chatSessionCloudKitServiceProvider = Provider<ChatSessionCloudKitService>((ref) { ... });

/// Provider for accessing the LocalStorageService instance.
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
}, name: 'localStorageService');

/// Provider for accessing the SupabaseDataService instance.
final supabaseDataServiceProvider = Provider<SupabaseDataService>((ref) {
  return SupabaseDataService();
}, name: 'supabaseDataService');


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

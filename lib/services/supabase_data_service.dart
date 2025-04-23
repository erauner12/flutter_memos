import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/chat_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for interacting with Supabase.
///
/// Handles saving, fetching, and deleting records related to
/// chat sessions, server configurations (if moved to Supabase),
/// workbench items, instances, and user settings.
class SupabaseDataService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Define table name constants
  static const String chatSessionsTable = 'chat_sessions';
  // Add other table names as needed
  // static const String serverConfigsTable = 'server_configs';
  // static const String workbenchItemsTable = 'workbench_items';
  // static const String workbenchInstancesTable = 'workbench_instances';
  // static const String userSettingsTable = 'user_settings';

  // --- ChatSession Methods ---

  /// Saves or updates a ChatSession in the Supabase table.
  /// Assumes a table 'chat_sessions' exists with columns matching ChatSession.toJson().
  /// Uses 'upsert' which requires the 'id' column to be the primary key or have a unique constraint.
  Future<bool> saveChatSession(ChatSession session) async {
    try {
      final data = session.toJson();
      // Ensure messages are stored as JSONB or text in Supabase
      // Supabase client handles JSON encoding automatically for Map/List types if column is json/jsonb
      await _supabase.from(chatSessionsTable).upsert(data);
      if (kDebugMode) {
        print('[SupabaseDataService] Saved/Updated chat session ${session.id}');
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('[SupabaseDataService] Error saving chat session ${session.id}: $e\n$s');
      }
      // Consider more specific error handling (e.g., PostgrestException)
      return false;
    }
  }

  /// Fetches a single ChatSession by its ID.
  /// Returns null if not found or on error.
  Future<ChatSession?> getChatSession(String id) async {
    try {
      final response = await _supabase
          .from(chatSessionsTable)
          .select()
          .eq('id', id)
          .maybeSingle(); // Fetches a single row or null

      if (response == null) {
        if (kDebugMode) {
          print('[SupabaseDataService] Chat session $id not found.');
        }
        return null;
      }

      // Supabase returns a Map<String, dynamic>, pass directly to fromJson
      final session = ChatSession.fromJson(response);
      if (kDebugMode) {
        print('[SupabaseDataService] Fetched chat session $id');
      }
      return session;
    } catch (e, s) {
      if (kDebugMode) {
        print('[SupabaseDataService] Error fetching chat session $id: $e\n$s');
      }
      return null;
    }
  }

  /// Deletes a ChatSession by its ID.
  Future<bool> deleteChatSession(String id) async {
    try {
      await _supabase.from(chatSessionsTable).delete().eq('id', id);
      if (kDebugMode) {
        print('[SupabaseDataService] Deleted chat session $id');
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('[SupabaseDataService] Error deleting chat session $id: $e\n$s');
      }
      return false;
    }
  }

  // --- Other Data Type Methods (Examples - Implement as needed) ---

  // Future<bool> saveServerConfig(ServerConfig config) async { ... }
  // Future<List<ServerConfig>> getAllServerConfigs() async { ... }
  // Future<bool> deleteServerConfig(String id) async { ... }

  // Future<bool> saveWorkbenchItem(WorkbenchItemReference item) async { ... }
  // Future<List<WorkbenchItemReference>> getAllWorkbenchItems({String? instanceId}) async { ... }
  // Future<bool> deleteWorkbenchItem(String id) async { ... }

  // --- Realtime (Example) ---

  /// Subscribes to changes in the chat sessions table.
  /// The callback will receive a SupabaseRealtimePayload.
  /// Remember to call .unsubscribe() when the listener is disposed.
  // RealtimeChannel subscribeToChatSessionChanges(
  //   String channelName,
  //   void Function(SupabaseRealtimePayload payload) callback,
  // ) {
  //   final channel = _supabase.channel(channelName);
  //   channel.on(
  //     RealtimeListenTypes.postgresChanges,
  //     ChannelFilter(event: '*', schema: 'public', table: chatSessionsTable),
  //     callback,
  //   ).subscribe();
  //   if (kDebugMode) {
  //     print('[SupabaseDataService] Subscribed to channel $channelName for table $chatSessionsTable');
  //   }
  //   return channel;
  // }
}

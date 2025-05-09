import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/chat_session.dart';
// Add these at the top alongside existing imports:
import 'package:flutter_memos/models/workbench_item_reference.dart';
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
  // Add other table names as needed if these entities are moved to Supabase
  static const String serverConfigsTable = 'server_configs'; // Example
  static const String mcpServerConfigsTable = 'mcp_server_configs'; // Example
  static const String workbenchItemsTable = 'workbench_items'; // Example
  static const String workbenchInstancesTable =
      'workbench_instances'; // Example
  static const String userSettingsTable = 'user_settings'; // Example

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
    } on PostgrestException catch (e, s) {
      if (kDebugMode) {
        print(
          '[SupabaseDataService] PostgrestException saving chat session ${session.id}: ${e.message}\nCode: ${e.code}\nDetails: ${e.details}\nHint: ${e.hint}\n$s',
        );
      }
      return false;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[SupabaseDataService] Generic error saving chat session ${session.id}: $e\n$s',
        );
      }
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
    } on PostgrestException catch (e, s) {
      if (kDebugMode) {
        print(
          '[SupabaseDataService] PostgrestException fetching chat session $id: ${e.message}\nCode: ${e.code}\nDetails: ${e.details}\nHint: ${e.hint}\n$s',
        );
      }
      return null;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[SupabaseDataService] Generic error fetching chat session $id: $e\n$s',
        );
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
    } on PostgrestException catch (e, s) {
      if (kDebugMode) {
        print(
          '[SupabaseDataService] PostgrestException deleting chat session $id: ${e.message}\nCode: ${e.code}\nDetails: ${e.details}\nHint: ${e.hint}\n$s',
        );
      }
      return false;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[SupabaseDataService] Generic error deleting chat session $id: $e\n$s',
        );
      }
      return false;
    }
  }

  /// Saves or updates a WorkbenchItemReference in Supabase.
  Future<bool> saveWorkbenchItem(WorkbenchItemReference item) async {
    try {
      final data = {
        'id': item.id,
        'instance_id': item.instanceId,
        'referenced_item_id': item.referencedItemId,
        'referenced_item_type': describeEnum(item.referencedItemType),
        'server_id': item.serverId,
        'server_type': describeEnum(item.serverType),
        'server_name': item.serverName,
        'preview_content': item.previewContent,
        'added_timestamp': item.addedTimestamp.toIso8601String(),
        'parent_note_id': item.parentNoteId,
        'sort_order': item.sortOrder,
      };
      await _supabase.from(workbenchItemsTable).upsert(data);
      if (kDebugMode) {
        print('[SupabaseDataService] Upserted workbench item ${item.id}');
      }
      return true;
    } on PostgrestException catch (e, s) {
      if (kDebugMode) {
        print(
          '[SupabaseDataService] PostgrestException saving item ${item.id}: ${e.message}',
        );
      }
      return false;
    } catch (e, s) {
      if (kDebugMode) {
        print('[SupabaseDataService] Error saving item ${item.id}: $e');
      }
      return false;
    }
  }

  /// Deletes a WorkbenchItemReference by its ID.
  Future<bool> deleteWorkbenchItem(String id) async {
    try {
      await _supabase.from(workbenchItemsTable).delete().eq('id', id);
      if (kDebugMode) {
        print('[SupabaseDataService] Deleted workbench item $id');
      }
      return true;
    } on PostgrestException catch (e, s) {
      if (kDebugMode) {
        print(
          '[SupabaseDataService] PostgrestException deleting item $id: ${e.message}',
        );
      }
      return false;
    } catch (e, s) {
      if (kDebugMode) {
        print('[SupabaseDataService] Error deleting item $id: $e');
      }
      return false;
    }
  }

  /// Retrieves all WorkbenchItemReference records, optionally filtered by instanceId.
  Future<List<WorkbenchItemReference>> getAllWorkbenchItems([
    String? instanceId,
  ]) async {
    try {
      final builder = _supabase.from(workbenchItemsTable).select();
      if (instanceId != null) {
        builder.eq('instance_id', instanceId);
      }
      final response = await builder;
      return (response as List<dynamic>)
          .map(
            (e) => WorkbenchItemReference.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e, s) {
      if (kDebugMode) {
        print('[SupabaseDataService] Error fetching workbench items: $e');
      }
      return [];
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

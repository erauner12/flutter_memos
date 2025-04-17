import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cloud_kit/flutter_cloud_kit.dart';
import 'package:flutter_cloud_kit/types/database_scope.dart';
import 'package:flutter_memos/models/chat_session.dart';
import 'package:flutter_memos/utils/env.dart';

class ChatSessionCloudKitService {
  static const _recordType = 'ChatSessionRecord';
  static const _recordName = 'currentUserActiveChat';

  final FlutterCloudKit _cloudKit =
      FlutterCloudKit(containerId: Env.cloudKitContainerId);

  final CloudKitDatabaseScope _scope = CloudKitDatabaseScope.private;

  // Helper to convert Map<String, dynamic> to Map<String, String> for saving
  Map<String, String> _asStringMap(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is DateTime) {
        return MapEntry(
          key,
          value.toIso8601String(),
        ); // Convert DateTime to ISO string
      } else if (value is List) {
        // Handle lists (like messages) by JSON encoding them
        return MapEntry(key, jsonEncode(value));
      } else {
        // Convert other types to string, handle nulls
        return MapEntry(key, value?.toString() ?? '');
      }
    });
  }


  Future<bool> saveChatSession(ChatSession session) async {
    try {
      final json = session.toJson();
      // No need to manually encode messages here, _asStringMap handles it
      await _cloudKit.saveRecord(
        scope: _scope,
        recordType: _recordType,
        recordName: _recordName,
        record: _asStringMap(json), // Use the helper to serialize
      );
      if (kDebugMode)
        print('[ChatSessionCloudKitService] Saved session successfully.');
      return true;
    } on PlatformException catch (e) {
      // treat conflict as success (newer‑wins elsewhere)
      if (e.message?.contains('already exists') == true ||
          e.message?.contains('conflict') == true) {
        if (kDebugMode)
          print(
            '[ChatSessionCloudKitService] Handled save conflict/already exists.',
          );
        return true;
      }
      if (kDebugMode)
        print(
          '[ChatSessionCloudKitService] Save PlatformException: ${e.message}',
        );
      rethrow;
    } catch (e, s) {
      if (kDebugMode) {
        print('[ChatSessionCloudKitService] Save error: $e\n$s');
      }
      return false;
    }
  }

  Future<ChatSession?> getChatSession() async {
    try {
      final rec =
          await _cloudKit.getRecord(
        scope: _scope,
        recordName: _recordName,
      );

      if (rec.recordType != _recordType) {
        if (kDebugMode)
          print(
            '[ChatSessionCloudKitService] Fetched record $_recordName but type was ${rec.recordType}, expected $_recordType',
          );
        return null;
      }

      // Deserialize the values, handling types correctly
      final Map<String, dynamic> json = rec.values.map((key, value) {
        if (key == 'messages') {
          // Value should be a JSON string, decode it
          try {
            return MapEntry(key, jsonDecode(value as String));
          } catch (e) {
            if (kDebugMode)
              print('[ChatSessionCloudKitService] Error decoding messages: $e');
            return MapEntry(key, []); // Return empty list on error
          }
        } else if (key == 'lastUpdated') {
          // Value might be DateTime or String, handle both
          if (value is DateTime) {
            return MapEntry(key, value); // Already a DateTime
          } else if (value is String) {
            return MapEntry(
              key,
              DateTime.tryParse(value),
            ); // Try parsing string
          } else {
            if (kDebugMode)
              print(
                '[ChatSessionCloudKitService] Unexpected type for lastUpdated: ${value.runtimeType}',
              );
            // Fallback or error handling needed? For now, try null.
            // The fromJson should handle null if the field is nullable,
            // but ChatSession.lastUpdated is not nullable.
            // Let's default to epoch to avoid crashing fromJson.
            return MapEntry(
              key,
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            );
          }
        } else if (key == 'contextItemType') {
          // Enum needs special handling if stored as string
          return MapEntry(
            key,
            ChatSession.parseWorkbenchItemType(value as String?),
          );
        }
        // For other fields, assume they are returned correctly or as strings
        return MapEntry(key, value);
      });

      json['id'] = _recordName; // Add the record name as the ID

      // Ensure required fields are present before calling fromJson
      if (json['lastUpdated'] == null) {
        if (kDebugMode)
          print(
            '[ChatSessionCloudKitService] lastUpdated field was null after processing, defaulting to epoch.',
          );
        json['lastUpdated'] = DateTime.fromMillisecondsSinceEpoch(
          0,
          isUtc: true,
        );
      }
      if (json['messages'] == null || json['messages'] is! List) {
        if (kDebugMode)
          print(
            '[ChatSessionCloudKitService] messages field was null or not a list after processing, defaulting to empty list.',
          );
        json['messages'] = [];
      }

      if (kDebugMode)
        print('[ChatSessionCloudKitService] Deserialized CloudKit data: $json');
      return ChatSession.fromJson(json);

    } on PlatformException catch (e) {
      if (e.message?.contains('not found') == true) {
        if (kDebugMode)
          print('[ChatSessionCloudKitService] Record $_recordName not found.');
        return null;
      }
      if (kDebugMode)
        print(
          '[ChatSessionCloudKitService] Get PlatformException: ${e.message}',
        );
      // Rethrow other platform exceptions unless specific handling is needed
      rethrow;
    } catch (e, s) {
      // Catch potential type errors during map processing or fromJson
      if (kDebugMode) {
        print('[ChatSessionCloudKitService] Get general error: $e\n$s');
      }
      return null;
    }
  }

  Future<bool> deleteChatSession() async {
    try {
      await _cloudKit.deleteRecord(scope: _scope, recordName: _recordName);
      if (kDebugMode)
        print('[ChatSessionCloudKitService] Deleted session successfully.');
      return true;
    } on PlatformException catch (e) {
      if (e.message?.contains('not found') == true) {
        if (kDebugMode)
          print(
            '[ChatSessionCloudKitService] Record $_recordName not found during delete (already deleted?).',
          );
        return true; // Record doesn't exist, consider it deleted
      }
      if (kDebugMode)
        print(
          '[ChatSessionCloudKitService] Delete PlatformException: ${e.message}',
        );
      rethrow;
    } catch (e, s) {
      if (kDebugMode) {
        print('[ChatSessionCloudKitService] Delete error: $e\n$s');
      }
      return false;
    }
  }
}

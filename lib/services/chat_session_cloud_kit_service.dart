import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cloud_kit/flutter_cloud_kit.dart';
import 'package:flutter_cloud_kit/types/database_scope.dart';
import 'package:flutter_memos/models/chat_session.dart';
// Import needed for WorkbenchItemType enum access if needed directly (though fromJson handles it)
// import 'package:flutter_memos/models/workbench_item_reference.dart';
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
      } else if (value is Enum) {
        // Handle enums by saving their name
        return MapEntry(key, value.name);
      } else {
        // Convert other types to string, handle nulls
        return MapEntry(key, value?.toString() ?? '');
      }
    });
  }


  Future<bool> saveChatSession(ChatSession session) async {
    try {
      final json = session.toJson();
      // _asStringMap handles serialization including enums and lists
      await _cloudKit.saveRecord(
        scope: _scope,
        recordType: _recordType,
        recordName: _recordName,
        record: _asStringMap(json), // Use the helper to serialize
      );
      if (kDebugMode) {
        print('[ChatSessionCloudKitService] Saved session successfully.');
      }
      return true;
    } on PlatformException catch (e) {
      // treat conflict as success (newer‑wins elsewhere)
      if (e.message?.contains('already exists') == true ||
          e.message?.contains('conflict') == true) {
        if (kDebugMode) {
          print(
            '[ChatSessionCloudKitService] Handled save conflict/already exists.',
          );
        }
        return true;
      }
      if (kDebugMode) {
        print(
          '[ChatSessionCloudKitService] Save PlatformException: ${e.message}',
        );
      }
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
        if (kDebugMode) {
          print(
            '[ChatSessionCloudKitService] Fetched record $_recordName but type was ${rec.recordType}, expected $_recordType',
          );
        }
        return null;
      }

      // Deserialize the values, handling types correctly
      final Map<String, dynamic> json = rec.values.map((key, value) {
        // Value from CloudKit is likely String, needs conversion based on key
        if (key == 'messages') {
          // Value should be a JSON string, decode it
          try {
            // Ensure value is treated as String before decoding
            return MapEntry(key, jsonDecode(value as String));
          } catch (e) {
            if (kDebugMode) {
              print('[ChatSessionCloudKitService] Error decoding messages: $e');
            }
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
            if (kDebugMode) {
              print(
                '[ChatSessionCloudKitService] Unexpected type for lastUpdated: ${value.runtimeType}',
              );
            }
            // Default to epoch to avoid crashing fromJson.
            return MapEntry(
              key,
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            );
          }
        }
        // REMOVED specific handling for contextItemType here.
        // Pass the raw value (likely String) directly to fromJson.
        return MapEntry(key, value);
      });

      json['id'] = _recordName; // Add the record name as the ID

      // Ensure required fields are present before calling fromJson
      // (fromJson handles null checks internally now)

      if (kDebugMode) {
        print('[ChatSessionCloudKitService] Deserialized CloudKit data: $json');
      }
      // Let ChatSession.fromJson handle all parsing, including enums
      return ChatSession.fromJson(json);

    } on PlatformException catch (e) {
      if (e.message?.contains('not found') == true) {
        if (kDebugMode) {
          print('[ChatSessionCloudKitService] Record $_recordName not found.');
        }
        return null;
      }
      if (kDebugMode) {
        print(
          '[ChatSessionCloudKitService] Get PlatformException: ${e.message}',
        );
      }
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
      if (kDebugMode) {
        print('[ChatSessionCloudKitService] Deleted session successfully.');
      }
      return true;
    } on PlatformException catch (e) {
      if (e.message?.contains('not found') == true) {
        if (kDebugMode) {
          print(
            '[ChatSessionCloudKitService] Record $_recordName not found during delete (already deleted?).',
          );
        }
        return true; // Record doesn't exist, consider it deleted
      }
      if (kDebugMode) {
        print(
          '[ChatSessionCloudKitService] Delete PlatformException: ${e.message}',
        );
      }
      rethrow;
    } catch (e, s) {
      if (kDebugMode) {
        print('[ChatSessionCloudKitService] Delete error: $e\n$s');
      }
      return false;
    }
  }
}

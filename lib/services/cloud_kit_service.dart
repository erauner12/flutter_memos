import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// Add CloudKit package imports
import 'package:flutter_cloud_kit/flutter_cloud_kit.dart';
import 'package:flutter_cloud_kit/types/cloud_kit_account_status.dart';
import 'package:flutter_cloud_kit/types/database_scope.dart';
// Existing model imports
import 'package:flutter_memos/models/mcp_server_config.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
// Add Env import
import 'package:flutter_memos/utils/env.dart';

/// Service class for interacting with Apple CloudKit.
///
/// This class handles saving, fetching, and deleting records related to
/// server configurations, workbench items, and user settings stored in CloudKit.
class CloudKitService {
  // Use the container ID from Env
  final FlutterCloudKit _cloudKit = FlutterCloudKit(
    containerId: Env.cloudKitContainerId, // Use the constant from Env
  );
  final String _userSettingsRecordName =
      'currentUserSettings'; // Fixed name for settings record
  final CloudKitDatabaseScope _scope =
      CloudKitDatabaseScope.private; // Default scope

  // Define record type constants
  static const String serverConfigRecordType = 'ServerConfig';
  static const String mcpServerConfigRecordType = 'McpServerConfig';
  static const String workbenchItemRecordType = 'WorkbenchItemReference';
  static const String userSettingsRecordType = 'UserSettings';

  // Helper function to serialize Map<String, dynamic> to Map<String, String>
  // This is a workaround for the flutter_cloud_kit plugin expecting Map<String, String>.
  Map<String, String> _serializeMap(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value == null) {
        // Convert null to empty string as plugin expects String values
        return MapEntry(key, '');
      } else if (value is DateTime) {
        // Convert DateTime to ISO 8601 string
        return MapEntry(key, value.toIso8601String());
      } else {
        // Convert other types (bool, int, double, String) to string
        return MapEntry(key, value.toString());
      }
    });
  }

  /// Initializes the CloudKit service, potentially checking account status.
  /// Returns the current CloudKit account status.
  Future<CloudKitAccountStatus> initialize() async {
    if (kDebugMode) {
      print('[CloudKitService] Initializing...');
    }
    try {
      final status = await _cloudKit.getAccountStatus();
      if (kDebugMode) {
        print('[CloudKitService] CloudKit Account Status: ${status.name}');
      }
      return status;
    } catch (e, s) {
      if (kDebugMode) {
        print('[CloudKitService] Error getting account status: $e\n$s');
      }
      return CloudKitAccountStatus.couldNotDetermine;
    }
  }

  // --- ServerConfig Methods ---

  /// Saves a Memos server configuration to CloudKit.
  /// Returns true if successful, false otherwise.
  Future<bool> saveServerConfig(ServerConfig config) async {
    if (kDebugMode) {
      print('[CloudKitService] saveServerConfig called for ${config.id}');
    }
    try {
      // Serialize the data before sending
      final recordData = _serializeMap(config.toJson());
      await _cloudKit.saveRecord(
        scope: _scope,
        recordType: serverConfigRecordType,
        recordName: config.id,
        record: recordData, // Pass serialized Map<String, String>
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Successfully saved ServerConfig ${config.id}',
        );
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error saving ServerConfig ${config.id}: $e\n$s',
        );
      }
      return false;
    }
  }

  /// Retrieves a specific Memos server configuration from CloudKit by its ID.
  /// Returns the ServerConfig if found, null otherwise.
  Future<ServerConfig?> getServerConfig(String id) async {
    if (kDebugMode) print('[CloudKitService] getServerConfig called for $id');
    try {
      final record = await _cloudKit.getRecord(
        scope: _scope,
        recordName: id, // Assuming recordName is the ID for this type
      );
      // Note: getRecord doesn't take recordType, relies on unique recordName across types or plugin handles it.
      // We need to check the returned recordType if the plugin doesn't filter.
      if (record.recordType == serverConfigRecordType) {
        final config = ServerConfig.fromJson(record.values);
        if (kDebugMode) {
          print('[CloudKitService] Successfully fetched ServerConfig $id');
        }
        return config;
      } else {
        if (kDebugMode) {
          print(
            '[CloudKitService] Fetched record $id but type was ${record.recordType}, expected $serverConfigRecordType',
          );
        }
        return null; // Wrong type fetched
      }
    } catch (e, s) {
      // Handle specific "record not found" errors if the plugin provides them, otherwise treat all errors as failure.
      if (kDebugMode) {
        print('[CloudKitService] Error fetching ServerConfig $id: $e\n$s');
      }
      return null;
    }
  }

  /// Retrieves all Memos server configurations from CloudKit.
  /// Returns a list of ServerConfig objects.
  Future<List<ServerConfig>> getAllServerConfigs() async {
    if (kDebugMode) print('[CloudKitService] getAllServerConfigs called');
    try {
      final records = await _cloudKit.getRecordsByType(
        scope: _scope,
        recordType: serverConfigRecordType,
      );
      final configs =
          records
              .map((record) {
                try {
                  // Inject recordName as 'id' into the values map
                  final valuesWithId = Map<String, dynamic>.from(record.values);
                  valuesWithId['id'] = record.recordName;
                  return ServerConfig.fromJson(valuesWithId);
                } catch (e) {
                  if (kDebugMode) {
                    print(
                      '[CloudKitService] Error parsing ServerConfig record ${record.recordName}: $e',
                    );
                  }
                  return null; // Skip records that fail parsing
                }
              })
              .whereType<ServerConfig>()
              .toList();
      if (kDebugMode) {
        print(
          '[CloudKitService] Successfully fetched ${configs.length} ServerConfigs',
        );
      }
      return configs;
    } catch (e, s) {
      if (kDebugMode) {
        print('[CloudKitService] Error fetching all ServerConfigs: $e\n$s');
      }
      return []; // Return empty list on error
    }
  }

  /// Deletes a Memos server configuration from CloudKit by its ID.
  /// Returns true if successful, false otherwise.
  Future<bool> deleteServerConfig(String id) async {
    if (kDebugMode) {
      print('[CloudKitService] deleteServerConfig called for $id');
    }
    try {
      // Assuming deleteRecord uses recordName. The plugin interface doesn't specify recordType for delete.
      await _cloudKit.deleteRecord(scope: _scope, recordName: id);
      if (kDebugMode) {
        print('[CloudKitService] Successfully deleted ServerConfig $id');
      }
      return true;
    } catch (e, s) {
      // Handle specific "record not found" errors if needed, otherwise treat all errors as failure.
      if (kDebugMode) {
        print('[CloudKitService] Error deleting ServerConfig $id: $e\n$s');
      }
      return false;
    }
  }

  // --- McpServerConfig Methods ---

  /// Saves an MCP server configuration to CloudKit.
  /// Returns true if successful, false otherwise.
  Future<bool> saveMcpServerConfig(McpServerConfig config) async {
    if (kDebugMode) {
      print('[CloudKitService] saveMcpServerConfig called for ${config.id}');
    }
    try {
      // Serialize the data before sending
      final recordData = _serializeMap(config.toJson());
      await _cloudKit.saveRecord(
        scope: _scope,
        recordType: mcpServerConfigRecordType,
        recordName: config.id,
        record: recordData, // Pass serialized Map<String, String>
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Successfully saved McpServerConfig ${config.id}',
        );
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error saving McpServerConfig ${config.id}: $e\n$s',
        );
      }
      return false;
    }
  }

  /// Retrieves all MCP server configurations from CloudKit.
  /// Returns a list of McpServerConfig objects.
  Future<List<McpServerConfig>> getAllMcpServerConfigs() async {
    if (kDebugMode) print('[CloudKitService] getAllMcpServerConfigs called');
    try {
      final records = await _cloudKit.getRecordsByType(
        scope: _scope,
        recordType: mcpServerConfigRecordType,
      );
      final configs =
          records
              .map((record) {
                try {
                  // Inject recordName as 'id' into the values map
                  final valuesWithId = Map<String, dynamic>.from(record.values);
                  valuesWithId['id'] = record.recordName;
                  return McpServerConfig.fromJson(valuesWithId);
                } catch (e) {
                  if (kDebugMode) {
                    print(
                      '[CloudKitService] Error parsing McpServerConfig record ${record.recordName}: $e',
                    );
                  }
                  return null;
                }
              })
              .whereType<McpServerConfig>()
              .toList();
      if (kDebugMode) {
        print(
          '[CloudKitService] Successfully fetched ${configs.length} McpServerConfigs',
        );
      }
      return configs;
    } catch (e, s) {
      // Check for the specific "not queryable" error
      if (e is PlatformException &&
          e.message != null &&
          e.message!.contains('is not marked queryable')) {
        if (kDebugMode) {
          print(
            '[CloudKitService] Schema Error: A field (likely recordName or creationDate) for $mcpServerConfigRecordType needs to be marked Queryable with Sort enabled in CloudKit Dashboard.',
          );
        }
      } else if (kDebugMode) {
        print(
          '[CloudKitService] Error fetching all McpServerConfigs: $e\n$s',
        );
      }
      return [];
    }
  }

  /// Deletes an MCP server configuration from CloudKit by its ID.
  /// Returns true if successful, false otherwise.
  Future<bool> deleteMcpServerConfig(String id) async {
    if (kDebugMode) {
      print('[CloudKitService] deleteMcpServerConfig called for $id');
    }
    try {
      await _cloudKit.deleteRecord(scope: _scope, recordName: id);
      if (kDebugMode) {
        print('[CloudKitService] Successfully deleted McpServerConfig $id');
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error deleting McpServerConfig $id: $e\n$s',
        );
      }
      return false;
    }
  }

  // --- WorkbenchItemReference Methods ---

  /// Saves a workbench item reference to CloudKit.
  /// Returns true if successful, false otherwise.
  Future<bool> saveWorkbenchItemReference(WorkbenchItemReference item) async {
    if (kDebugMode) {
      print(
        '[CloudKitService] saveWorkbenchItemReference called for ${item.id}',
      );
    }
    try {
      // Serialize the data before sending
      final recordData = _serializeMap(item.toJson());
      await _cloudKit.saveRecord(
        scope: _scope,
        recordType: workbenchItemRecordType,
        recordName: item.id,
        record: recordData, // Pass serialized Map<String, String>
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Successfully saved WorkbenchItemReference ${item.id}',
        );
      }
      return true;
    } catch (e, s) {
      // Log the specific error related to TIMESTAMP if it occurs
      if (e is PlatformException &&
          e.message != null &&
          e.message!.contains('TIMESTAMP')) {
        print(
          '[CloudKitService] WORKAROUND WARNING: Encountered expected TIMESTAMP type mismatch error for WorkbenchItemReference ${item.id}. The flutter_cloud_kit plugin needs modification for proper DateTime handling. Error: $e',
        );
      } else if (kDebugMode) {
        print(
          '[CloudKitService] Error saving WorkbenchItemReference ${item.id}: $e\n$s',
        );
      }
      return false;
    }
  }

  /// Retrieves all workbench item references from CloudKit.
  /// Returns a list of WorkbenchItemReference objects.
  Future<List<WorkbenchItemReference>> getAllWorkbenchItemReferences() async {
    if (kDebugMode) {
      print('[CloudKitService] getAllWorkbenchItemReferences called');
    }
    try {
      final records = await _cloudKit.getRecordsByType(
        scope: _scope,
        recordType: workbenchItemRecordType,
      );
      final items =
          records
              .map((record) {
                try {
                  // Inject recordName as 'id' into the values map
                  final valuesWithId = Map<String, dynamic>.from(record.values);
                  valuesWithId['id'] = record.recordName;
                  return WorkbenchItemReference.fromJson(valuesWithId);
                } catch (e) {
                  if (kDebugMode) {
                    print(
                      '[CloudKitService] Error parsing WorkbenchItemReference record ${record.recordName}: $e',
                    );
                  }
                  return null;
                }
              })
              .whereType<WorkbenchItemReference>()
              .toList();
      if (kDebugMode) {
        print(
          '[CloudKitService] Successfully fetched ${items.length} WorkbenchItemReferences',
        );
      }
      return items;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error fetching all WorkbenchItemReferences: $e\n$s',
        );
      }
      return [];
    }
  }

  /// Deletes a workbench item reference from CloudKit by its ID.
  /// Returns true if successful, false otherwise.
  Future<bool> deleteWorkbenchItemReference(String referenceId) async {
    if (kDebugMode) {
      print(
        '[CloudKitService] deleteWorkbenchItemReference called for $referenceId',
      );
    }
    try {
      await _cloudKit.deleteRecord(scope: _scope, recordName: referenceId);
      if (kDebugMode) {
        print(
          '[CloudKitService] Successfully deleted WorkbenchItemReference $referenceId',
        );
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error deleting WorkbenchItemReference $referenceId: $e\n$s',
        );
      }
      return false;
    }
  }

  /// Updates the last opened timestamp for a specific workbench item in CloudKit.
  /// Returns true if successful, false otherwise.
  Future<bool> updateWorkbenchItemLastOpened(String referenceId) async {
    if (kDebugMode) {
      print(
        '[CloudKitService] updateWorkbenchItemLastOpened called for $referenceId',
      );
    }
    try {
      // 1. Fetch the existing record
      final record = await _cloudKit.getRecord(
        scope: _scope,
        recordName: referenceId,
      );

      // Check if the fetched record is of the correct type
      if (record.recordType != workbenchItemRecordType) {
        if (kDebugMode) {
          print(
            '[CloudKitService] Fetched record $referenceId but type was ${record.recordType}, expected $workbenchItemRecordType. Cannot update timestamp.',
          );
        }
        return false;
      }

      // 2. Prepare updated data (convert existing dynamic map to object for updating)
      final currentItem = WorkbenchItemReference.fromJson(record.values);
      final updatedItem = currentItem.copyWith(
        lastOpenedTimestamp: DateTime.now(),
      );

      // 3. Save the modified record back
      // Serialize the updated data before sending
      final updatedRecordData = _serializeMap(updatedItem.toJson());
      await _cloudKit.saveRecord(
        scope: _scope,
        recordType: workbenchItemRecordType, // Must specify type on save
        recordName: referenceId,
        record: updatedRecordData, // Pass serialized Map<String, String>
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Successfully updated lastOpenedTimestamp for $referenceId',
        );
      }
      return true;
    } catch (e, s) {
      // Log the specific error related to TIMESTAMP if it occurs
      if (e is PlatformException &&
          e.message != null &&
          e.message!.contains('TIMESTAMP')) {
        print(
          '[CloudKitService] WORKAROUND WARNING: Encountered expected TIMESTAMP type mismatch error when updating lastOpenedTimestamp for $referenceId. The flutter_cloud_kit plugin needs modification for proper DateTime handling. Error: $e',
        );
      } else if (kDebugMode) {
        print(
          '[CloudKitService] Error updating lastOpenedTimestamp for $referenceId: $e\n$s',
        );
      }
      return false;
    }
  }

  // --- Settings Methods ---

  /// Retrieves a specific setting value from the UserSettings record in CloudKit.
  /// Returns the setting value as a String if found, null otherwise.
  Future<String?> getSetting(String keyName) async {
    if (kDebugMode) print('[CloudKitService] getSetting called for $keyName');
    try {
      final record = await _cloudKit.getRecord(
        scope: _scope,
        recordName: _userSettingsRecordName,
      );

      // Check type just in case
      if (record.recordType != userSettingsRecordType) {
        if (kDebugMode) {
          print(
            '[CloudKitService] Fetched settings record but type was ${record.recordType}.',
          );
        }
        return null;
      }

      // Access the specific key from the values map
      final value = record.values[keyName];
      if (value != null) {
        if (kDebugMode) {
          print('[CloudKitService] Successfully fetched setting $keyName');
        }
        // Ensure it's returned as a String
        return value.toString();
      } else {
        if (kDebugMode) {
          print(
            '[CloudKitService] Setting $keyName not found in UserSettings record.',
          );
        }
        return null;
      }
    } catch (e, s) {
      // Handle "record not found" specifically if possible, otherwise treat as error
      if (kDebugMode) {
        print('[CloudKitService] Error fetching setting $keyName: $e\n$s');
      }
      return null;
    }
  }

  /// Saves a specific setting key-value pair to the UserSettings record in CloudKit.
  /// Returns true if successful, false otherwise.
  Future<bool> saveSetting(String keyName, String value) async {
    if (kDebugMode) print('[CloudKitService] saveSetting called for $keyName');
    try {
      Map<String, dynamic> currentSettings = {};
      // 1. Try to fetch the existing record
      try {
        final existingRecord = await _cloudKit.getRecord(
          scope: _scope,
          recordName: _userSettingsRecordName,
        );
        // Check type
        if (existingRecord.recordType == userSettingsRecordType) {
          currentSettings = Map<String, dynamic>.from(existingRecord.values);
          if (kDebugMode) {
            print(
              '[CloudKitService] Found existing UserSettings record for saveSetting.',
            );
          }
        } else {
          if (kDebugMode) {
            print(
              '[CloudKitService] Found record $_userSettingsRecordName but it was wrong type: ${existingRecord.recordType}. Overwriting.',
            );
          }
        }
      } catch (e) {
        // Assume record not found error, proceed with empty map
        if (kDebugMode) {
          if (e is PlatformException &&
              e.message != null &&
              e.message!.contains('Record not found')) {
            print(
              '[CloudKitService] UserSettings record not found, will create new one.',
            );
          } else {
            print(
              '[CloudKitService] Error fetching UserSettings record during saveSetting (will attempt create): $e',
            );
          }
        }
      }

      // 2. Update the specific key
      currentSettings[keyName] = value; // Note: value is already String here

      // 3. Save the record
      // Serialize the potentially mixed-type map (though unlikely for settings)
      final recordData = _serializeMap(currentSettings);
      await _cloudKit.saveRecord(
        scope: _scope,
        recordType: userSettingsRecordType,
        recordName: _userSettingsRecordName,
        record: recordData, // Pass serialized Map<String, String>
      );
      if (kDebugMode) {
        print('[CloudKitService] Successfully saved setting $keyName');
      }
      return true;
    } catch (e, s) {
      // *** Add specific handling for "record already exists" ***
      if (e is PlatformException &&
          e.message != null &&
          e.message!.contains('record to insert already exists')) {
        if (kDebugMode) {
          print(
            '[CloudKitService] saveSetting: Handled "record already exists" for "$_userSettingsRecordName" when saving key "$keyName". Treating as success (likely concurrent init).',
          );
        }
        return true;
      }
      // *** End specific handling ***

      if (kDebugMode) {
        print('[CloudKitService] Error saving setting $keyName: $e\n$s');
      }
      return false;
    }
  }

  // --- Utility Methods ---

  /// Deletes all CloudKit records of a specific type. Use with caution!
  /// Returns true if successful, false otherwise.
  Future<bool> deleteAllRecordsOfType(String recordType) async {
    if (kDebugMode) {
      print('[CloudKitService] deleteAllRecordsOfType called for $recordType');
    }
    try {
      // 1. Fetch all records of the given type
      final records = await _cloudKit.getRecordsByType(
        scope: _scope,
        recordType: recordType,
      );

      if (records.isEmpty) {
        if (kDebugMode) {
          print(
            '[CloudKitService] No records found for type $recordType to delete.',
          );
        }
        return true; // Nothing to delete, considered success
      }

      if (kDebugMode) {
        print(
          '[CloudKitService] Found ${records.length} records of type $recordType to delete.',
        );
      }

      // 2. Delete each record individually (plugin lacks batch delete)
      bool allSucceeded = true;
      for (final record in records) {
        try {
          await _cloudKit.deleteRecord(
            scope: _scope,
            recordName: record.recordName,
          );
          if (kDebugMode) {
            print(
              '[CloudKitService] Deleted record ${record.recordName} of type $recordType',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              '[CloudKitService] Error deleting record ${record.recordName} of type $recordType: $e',
            );
          }
          allSucceeded = false;
        }
      }
      return allSucceeded;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error fetching records for deletion (type $recordType): $e\n$s',
        );
      }
      return false;
    }
  }

  /// Deletes the UserSettings record from CloudKit. Use with caution!
  /// Returns true if successful, false otherwise.
  Future<bool> deleteUserSettingsRecord() async {
    if (kDebugMode) print('[CloudKitService] deleteUserSettingsRecord called');
    try {
      await _cloudKit.deleteRecord(
        scope: _scope,
        recordName: _userSettingsRecordName,
      );
      if (kDebugMode) {
        print('[CloudKitService] Successfully deleted UserSettings record.');
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('[CloudKitService] Error deleting UserSettings record: $e\n$s');
      }
      return false;
    }
  }
}

// GENERATED FILE - DO NOT MODIFY BY HAND
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// CloudKit package imports
import 'package:flutter_cloud_kit/flutter_cloud_kit.dart';
import 'package:flutter_cloud_kit/types/cloud_kit_account_status.dart';
import 'package:flutter_cloud_kit/types/database_scope.dart';
// Existing model imports
import 'package:flutter_memos/models/mcp_server_config.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/workbench_instance.dart'; // Import WorkbenchInstance
import 'package:flutter_memos/models/workbench_item_reference.dart';
// Env import
import 'package:flutter_memos/utils/env.dart';
// Add Uuid import
import 'package:uuid/uuid.dart';

/// Service class for interacting with Apple CloudKit.
///
/// This class handles saving, fetching, and deleting records related to
/// server configurations, workbench items, instances, and user settings.
class CloudKitService {
  final FlutterCloudKit _cloudKit = FlutterCloudKit(
    containerId: Env.cloudKitContainerId,
  );
  final String _userSettingsRecordName = 'currentUserSettings';
  final CloudKitDatabaseScope _scope = CloudKitDatabaseScope.private;

  // Define record type constants
  static const String serverConfigRecordType = 'ServerConfig';
  static const String mcpServerConfigRecordType = 'McpServerConfig';
  static const String workbenchItemRecordType = 'WorkbenchItemReference';
  static const String userSettingsRecordType = 'UserSettings';
  static const String workbenchInstanceRecordType =
      'WorkbenchInstance'; // Add new constant

  // Helper function to serialize Map<String, dynamic> to Map<String, String>
  Map<String, String> _serializeMap(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value == null) {
        return MapEntry(key, ''); // Represent null as empty string
      } else if (value is DateTime) {
        return MapEntry(key, value.toIso8601String());
      } else if (value is bool) {
        return MapEntry(key, value.toString()); // 'true' or 'false'
      } else if (value is Enum) {
        return MapEntry(key, describeEnum(value)); // Use standard enum name
      } else {
        return MapEntry(key, value.toString());
      }
    });
  }

  /// Initializes the CloudKit service, potentially checking account status.
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
  Future<bool> saveServerConfig(ServerConfig config) async {
    if (kDebugMode) {
      print('[CloudKitService] saveServerConfig called for ${config.id}');
    }
    try {
      final recordData = _serializeMap(config.toJson());
      await _cloudKit.saveRecord(
        scope: _scope,
        recordType: serverConfigRecordType,
        recordName: config.id,
        record: recordData,
      );
      if (kDebugMode) {
        print('[CloudKitService] Successfully saved ServerConfig ${config.id}');
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

  Future<ServerConfig?> getServerConfig(String id) async {
    if (kDebugMode) print('[CloudKitService] getServerConfig called for $id');
    try {
      final record = await _cloudKit.getRecord(
        scope: _scope,
        recordName: id,
      );
      if (record.recordType == serverConfigRecordType) {
        final valuesWithId = Map<String, dynamic>.from(record.values);
        valuesWithId.putIfAbsent('id', () => record.recordName);
        final config = ServerConfig.fromJson(valuesWithId);
        if (kDebugMode) {
          print('[CloudKitService] Successfully fetched ServerConfig $id');
        }
        return config;
      } else {
        if (kDebugMode) {
          print(
            '[CloudKitService] Fetched record $id but type was ${record.recordType}',
          );
        }
        return null;
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('[CloudKitService] Error fetching ServerConfig $id: $e\n$s');
      }
      return null;
    }
  }

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
                  final valuesWithId = Map<String, dynamic>.from(record.values);
                  valuesWithId.putIfAbsent('id', () => record.recordName);
                  return ServerConfig.fromJson(valuesWithId);
                } catch (e) {
                  if (kDebugMode) {
                    print(
                      '[CloudKitService] Error parsing ServerConfig ${record.recordName}: $e',
                    );
                  }
                  return null;
                }
              })
              .whereType<ServerConfig>()
              .where((config) => config.serverType != ServerType.todoist)
              .toList();
      if (kDebugMode) {
        print(
          '[CloudKitService] Fetched ${configs.length} valid ServerConfigs',
        );
      }
      return configs;
    } catch (e, s) {
      if (kDebugMode) {
        print('[CloudKitService] Error fetching all ServerConfigs: $e\n$s');
      }
      return [];
    }
  }

  Future<bool> deleteServerConfig(String id) async {
    if (kDebugMode) {
      print('[CloudKitService] deleteServerConfig called for $id');
    }
    try {
      await _cloudKit.deleteRecord(scope: _scope, recordName: id);
      if (kDebugMode) {
        print('[CloudKitService] Successfully deleted ServerConfig $id');
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('[CloudKitService] Error deleting ServerConfig $id: $e\n$s');
      }
      return false;
    }
  }

  // --- McpServerConfig Methods ---
  Future<bool> saveMcpServerConfig(McpServerConfig config) async {
    if (kDebugMode) {
      print('[CloudKitService] saveMcpServerConfig called for ${config.id}');
    }
    try {
      final recordData = _serializeMap(config.toJson());
      await _cloudKit.saveRecord(
        scope: _scope,
        recordType: mcpServerConfigRecordType,
        recordName: config.id,
        record: recordData,
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
                  final valuesWithId = Map<String, dynamic>.from(record.values);
                  valuesWithId['id'] = record.recordName;
                  return McpServerConfig.fromJson(valuesWithId);
                } catch (e) {
                  if (kDebugMode) {
                    print(
                      '[CloudKitService] Error parsing McpServerConfig ${record.recordName}: $e',
                    );
                  }
                  return null;
                }
              })
              .whereType<McpServerConfig>()
              .toList();
      if (kDebugMode) {
        print('[CloudKitService] Fetched ${configs.length} McpServerConfigs');
      }
      return configs;
    } catch (e, s) {
      if (e is PlatformException &&
          e.message != null &&
          e.message!.contains('is not marked queryable')) {
        if (kDebugMode) {
          print(
            '[CloudKitService] Schema Error for $mcpServerConfigRecordType needs Queryable fields.',
          );
        }
      } else if (kDebugMode) {
        print('[CloudKitService] Error fetching all McpServerConfigs: $e\n$s');
      }
      return [];
    }
  }

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
        print('[CloudKitService] Error deleting McpServerConfig $id: $e\n$s');
      }
      return false;
    }
  }

  // --- WorkbenchInstance Methods ---
  Future<bool> saveWorkbenchInstance(WorkbenchInstance instance) async {
    if (kDebugMode) {
      print(
        '[CloudKitService] saveWorkbenchInstance called for ${instance.id}',
      );
    }
    try {
      final recordData = _serializeMap(instance.toJson());
      await _cloudKit.saveRecord(
        scope: _scope,
        recordType: workbenchInstanceRecordType,
        recordName: instance.id,
        record: recordData,
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Successfully saved WorkbenchInstance ${instance.id}',
        );
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error saving WorkbenchInstance ${instance.id}: $e\n$s',
        );
      }
      return false;
    }
  }

  Future<List<WorkbenchInstance>> getAllWorkbenchInstances() async {
    if (kDebugMode) {
      print('[CloudKitService] getAllWorkbenchInstances called');
    }
    try {
      final records = await _cloudKit.getRecordsByType(
        scope: _scope,
        recordType: workbenchInstanceRecordType,
      );
      final instances =
          records
              .map((record) {
                try {
                  return WorkbenchInstance.fromJson(
                    record.values,
                    record.recordName,
                  );
                } catch (e) {
                  if (kDebugMode) {
                    print(
                      '[CloudKitService] Error parsing WorkbenchInstance ${record.recordName}: $e',
                    );
                  }
                  return null;
                }
              })
              .whereType<WorkbenchInstance>()
              .toList();

      if (instances.isEmpty) {
        if (kDebugMode) {
          print(
            '[CloudKitService] No instances found, creating default instance.',
          );
        }
        final defaultInstance = WorkbenchInstance.defaultInstance();
        final success = await saveWorkbenchInstance(defaultInstance);
        if (success) {
          instances.add(defaultInstance);
          if (kDebugMode) {
            print(
              '[CloudKitService] Successfully created and added default instance.',
            );
          }
        } else {
          if (kDebugMode) {
            print('[CloudKitService] Failed to save default instance.');
          }
        }
      }

      if (kDebugMode) {
        print(
          '[CloudKitService] Fetched ${instances.length} WorkbenchInstances',
        );
      }
      return instances;
    } catch (e, s) {
      if (kDebugMode) {
        print('[CloudKitService] Error fetching WorkbenchInstances: $e\n$s');
      }
      try {
        final defaultInstance = WorkbenchInstance.defaultInstance();
        await saveWorkbenchInstance(defaultInstance);
        return [defaultInstance];
      } catch (_) {
        return [];
      }
    }
  }

  Future<bool> deleteWorkbenchInstance(String instanceId) async {
    if (kDebugMode) {
      print('[CloudKitService] deleteWorkbenchInstance called for $instanceId');
    }
    if (instanceId == WorkbenchInstance.defaultInstanceId) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Attempted to delete the default workbench instance. Operation aborted.',
        );
      }
      return false;
    }
    try {
      await _cloudKit.deleteRecord(scope: _scope, recordName: instanceId);
      if (kDebugMode) {
        print(
          '[CloudKitService] Successfully deleted WorkbenchInstance $instanceId',
        );
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error deleting WorkbenchInstance $instanceId: $e\n$s',
        );
      }
      return false;
    }
  }

  // --- WorkbenchItemReference Methods ---

  Future<bool> saveWorkbenchItemReference(WorkbenchItemReference item) async {
    if (kDebugMode) {
      print(
        '[CloudKitService] saveWorkbenchItemReference called for ${item.id} in instance ${item.instanceId}',
      );
    }
    try {
      final recordData = _serializeMap(item.toJson());
      await _cloudKit.saveRecord(
        scope: _scope,
        recordType: workbenchItemRecordType,
        recordName: item.id,
        record: recordData,
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Successfully saved WorkbenchItemReference ${item.id}',
        );
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error saving WorkbenchItemReference ${item.id}: $e\n$s',
        );
      }
      return false;
    }
  }

  // REMOVED the old moveWorkbenchItemReference method above

  /// Instead of updating the existing record,
  /// we delete it and create a brand-new record with a new ID.
  Future<bool> moveWorkbenchItemReferenceByDeleteRecreate({
    required String recordName, // old record's ID
    required String newInstanceId,
    required Map<String, dynamic> oldRecordFields, // fields from old record
  }) async {
    if (kDebugMode) {
      print(
        '[CloudKitService] moveWorkbenchItemReferenceByDeleteRecreate called for $recordName to instance $newInstanceId',
      );
    }
    try {
      // 1. Delete the old record from CloudKit
      // Use the existing delete method for robustness
      final deleteSuccess = await deleteWorkbenchItemReference(recordName);
      if (!deleteSuccess) {
        // Log the failure but proceed to attempt creation anyway,
        // in case the delete failed because the record was already gone.
        if (kDebugMode) {
          print(
            '[CloudKitService] Failed to delete old record $recordName during move, but proceeding with creation.',
          );
        }
        // Optionally: return false here if delete must succeed first.
        // return false;
      } else {
        if (kDebugMode) {
          print(
            '[CloudKitService] Successfully deleted old record $recordName during move.',
          );
        }
      }

      // 2. Build new data map with new instanceId and potentially new ID
      final newValues = Map<String, dynamic>.from(oldRecordFields);
      newValues['instanceId'] = newInstanceId;

      // 3. Generate a new random ID for the new record
      final newRecordId = const Uuid().v4();
      // Update the 'id' field in the map to match the new recordName
      newValues['id'] = newRecordId;

      // 4. Serialize fields & save new record
      final recordData = _serializeMap(newValues);
      await _cloudKit.saveRecord(
        scope: _scope,
        recordType: workbenchItemRecordType,
        recordName: newRecordId, // Use the new UUID as the record name
        record: recordData,
      );

      if (kDebugMode) {
        print(
          '[CloudKitService] Successfully created new record $newRecordId for moved item (original: $recordName).',
        );
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error during delete-recreate move for $recordName: $e\n$s',
        );
      }
      return false;
    }
  }

  /// Retrieves all workbench item references from CloudKit, optionally filtered by instanceId.
  /// Handles migration by assigning a default instanceId if missing and persists the change.
  Future<List<WorkbenchItemReference>> getAllWorkbenchItemReferences({
    String? instanceId,
  }) async {
    if (kDebugMode) {
      print(
        '[CloudKitService] getAllWorkbenchItemReferences called${instanceId != null ? ' for instance $instanceId' : ''}',
      );
    }
    try {
      final records = await _cloudKit.getRecordsByType(
        scope: _scope,
        recordType: workbenchItemRecordType,
      );

      final List<WorkbenchItemReference> items = [];
      final List<Future<void>> migrationFutures = [];

      for (final record in records) {
        WorkbenchItemReference? item;
        bool needsMigrationSave = false;
        try {
          final values = Map<String, dynamic>.from(record.values);
          final originalInstanceId = values['instanceId'];
          item = WorkbenchItemReference.fromJson(
            values,
            record.recordName,
          );
          if ((originalInstanceId == null ||
                  (originalInstanceId is String &&
                      originalInstanceId.isEmpty)) &&
              item.instanceId == WorkbenchInstance.defaultInstanceId) {
            if (kDebugMode) {
              print(
                '[CloudKitService] Item ${item.id} requires instanceId migration. Queuing save.',
              );
            }
            needsMigrationSave = true;
          }
          if (instanceId == null || item.instanceId == instanceId) {
            items.add(item);
          }
          if (needsMigrationSave) {
            migrationFutures.add(saveWorkbenchItemReference(item));
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              '[CloudKitService] Error parsing WorkbenchItemReference ${record.recordName}: $e. Skipping item.',
            );
          }
        }
      }

      if (migrationFutures.isNotEmpty) {
        Future.wait(migrationFutures)
            .then((_) {
              if (kDebugMode) {
                print(
                  '[CloudKitService] Completed ${migrationFutures.length} item migration persistence tasks.',
                );
              }
            })
            .catchError((e, s) {
              if (kDebugMode) {
                print(
                  '[CloudKitService] Error during background migration persistence: $e\n$s',
                );
              }
            });
        if (kDebugMode) {
          print(
            '[CloudKitService] Initiated ${migrationFutures.length} background item migration saves.',
          );
        }
      }

      if (kDebugMode) {
        print(
          '[CloudKitService] Successfully fetched ${records.length} total references, returning ${items.length} after filtering for instance ${instanceId ?? 'all'}',
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

  Future<bool> deleteAllWorkbenchItemReferences({String? instanceId}) async {
    if (kDebugMode) {
      print(
        '[CloudKitService] deleteAllWorkbenchItemReferences called${instanceId != null ? ' for instance $instanceId' : ''}',
      );
    }
    try {
      final itemsToDelete = await getAllWorkbenchItemReferences(
        instanceId: instanceId,
      );

      if (itemsToDelete.isEmpty) {
        if (kDebugMode) {
          print(
            '[CloudKitService] No WorkbenchItemReferences found${instanceId != null ? ' for instance $instanceId' : ''} to delete.',
          );
        }
        return true;
      }

      if (kDebugMode) {
        print(
          '[CloudKitService] Found ${itemsToDelete.length} WorkbenchItemReferences to delete.',
        );
      }

      final recordNamesToDelete = itemsToDelete.map((item) => item.id).toList();
      bool allSucceeded = true;
      for (final recordName in recordNamesToDelete) {
        try {
          await _cloudKit.deleteRecord(scope: _scope, recordName: recordName);
          if (kDebugMode) {
            print(
              '[CloudKitService] Deleted WorkbenchItemReference $recordName',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              '[CloudKitService] Error deleting WorkbenchItemReference $recordName: $e',
            );
          }
          allSucceeded = false;
        }
      }

      if (kDebugMode) {
        print(
          '[CloudKitService] Finished deleting ${itemsToDelete.length} items. Success: $allSucceeded',
        );
      }
      return allSucceeded;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error during deleteAllWorkbenchItemReferences (fetch phase): $e\n$s',
        );
      }
      return false;
    }
  }

  // --- Settings Methods ---

  Future<String?> getSetting(String keyName) async {
    if (kDebugMode) print('[CloudKitService] getSetting called for $keyName');
    try {
      final record = await _cloudKit.getRecord(
        scope: _scope,
        recordName: _userSettingsRecordName,
      );
      if (record.recordType != userSettingsRecordType) {
        if (kDebugMode) {
          print(
            '[CloudKitService] Fetched settings record wrong type: ${record.recordType}.',
          );
        }
        return null;
      }
      final value = record.values[keyName];
      if (value != null) {
        if (kDebugMode) {
          print('[CloudKitService] Successfully fetched setting $keyName');
        }
        return value.toString();
      } else {
        if (kDebugMode) {
          print('[CloudKitService] Setting $keyName not found.');
        }
        return null;
      }
    } catch (e) {
      if (e is PlatformException &&
          e.message != null &&
          e.message!.contains('Record not found')) {
        if (kDebugMode) {
          print(
            '[CloudKitService] UserSettings record not found when getting setting $keyName.',
          );
        }
      } else if (kDebugMode) {
        print('[CloudKitService] Error fetching setting $keyName: $e');
      }
      return null;
    }
  }

  Future<bool> saveSetting(String keyName, String value) async {
    if (kDebugMode) print('[CloudKitService] saveSetting called for $keyName');
    try {
      Map<String, dynamic> currentSettings = {};
      try {
        final existingRecord = await _cloudKit.getRecord(
          scope: _scope,
          recordName: _userSettingsRecordName,
        );
        if (existingRecord.recordType == userSettingsRecordType) {
          currentSettings = Map<String, dynamic>.from(existingRecord.values);
          if (kDebugMode) {
            print('[CloudKitService] Found existing UserSettings record.');
          }
        } else {
          if (kDebugMode) {
            print(
              '[CloudKitService] Existing record $_userSettingsRecordName has wrong type: ${existingRecord.recordType}. Overwriting.',
            );
          }
        }
      } catch (e) {
        if (e is PlatformException &&
            e.message != null &&
            e.message!.contains('Record not found')) {
          if (kDebugMode) {
            print(
              '[CloudKitService] UserSettings record not found, will create new one.',
            );
          }
        } else {
          if (kDebugMode) {
            print(
              '[CloudKitService] Error fetching existing UserSettings, proceeding with save attempt: $e',
            );
          }
        }
      }

      currentSettings[keyName] = value;
      final recordData = _serializeMap(currentSettings);
      await _cloudKit.saveRecord(
        scope: _scope,
        recordType: userSettingsRecordType,
        recordName: _userSettingsRecordName,
        record: recordData,
      );
      if (kDebugMode) {
        print('[CloudKitService] Successfully saved setting $keyName');
      }
      return true;
    } catch (e, s) {
      if (e is PlatformException &&
          e.message != null &&
          e.message!.contains('record to insert already exists')) {
        if (kDebugMode) {
          print(
            '[CloudKitService] Handled "record already exists" conflict for $_userSettingsRecordName. Save likely succeeded or will be retried.',
          );
        }
        return true;
      }
      if (kDebugMode) {
        print('[CloudKitService] Error saving setting $keyName: $e\n$s');
      }
      return false;
    }
  }

  // --- Utility Methods ---

  Future<bool> deleteAllRecordsOfType(String recordType) async {
    if (recordType == workbenchItemRecordType) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Warning: deleteAllRecordsOfType called for $workbenchItemRecordType. This deletes ALL items across ALL instances. Use deleteAllWorkbenchItemReferences for targeted deletion.',
        );
      }
    }
    if (recordType == workbenchInstanceRecordType) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Warning: deleteAllRecordsOfType called for $workbenchInstanceRecordType. This will delete ALL instances, *except* the default instance (${WorkbenchInstance.defaultInstanceId}).',
        );
      }
    }
    if (recordType == userSettingsRecordType) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Warning: deleteAllRecordsOfType called for $userSettingsRecordType. This will delete the user settings record.',
        );
      }
    }

    if (kDebugMode) {
      print('[CloudKitService] deleteAllRecordsOfType called for $recordType');
    }
    try {
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
        return true;
      }

      final recordNamesToDelete =
          records
              .map((r) => r.recordName)
              .where(
                (name) =>
                    !(recordType == workbenchInstanceRecordType &&
                        name == WorkbenchInstance.defaultInstanceId),
              )
              .toList();

      if (recordNamesToDelete.isEmpty &&
          recordType == workbenchInstanceRecordType &&
          records.isNotEmpty) {
        if (kDebugMode) {
          print(
            '[CloudKitService] Only the default instance exists for type $recordType. No records will be deleted.',
          );
        }
        return true;
      }

      if (kDebugMode) {
        print(
          '[CloudKitService] Found ${recordNamesToDelete.length} records of type $recordType to delete (excluding default instance if applicable).',
        );
      }

      bool allSucceeded = true;
      for (final recordName in recordNamesToDelete) {
        try {
          await _cloudKit.deleteRecord(
            scope: _scope,
            recordName: recordName,
          );
          if (kDebugMode) {
            print(
              '[CloudKitService] Deleted record $recordName of type $recordType',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              '[CloudKitService] Error deleting record $recordName: $e',
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
      if (e is PlatformException &&
          e.message != null &&
          e.message!.contains('Record not found')) {
        if (kDebugMode) {
          print(
            '[CloudKitService] UserSettings record already deleted or never existed.',
          );
        }
        return true;
      }
      if (kDebugMode) {
        print('[CloudKitService] Error deleting UserSettings record: $e\n$s');
      }
      return false;
    }
  }
}

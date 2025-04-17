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
        // Inject recordName as 'id' if not present in values (should be)
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
                  // Ensure 'id' is present, using recordName as fallback
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
              // Filter out any configs that ended up as 'todoist' type (shouldn't happen with new fromJson)
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

  /// Saves a workbench instance to CloudKit.
  /// Returns true if successful, false otherwise.
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

  /// Retrieves all workbench instances from CloudKit.
  /// Returns a list of WorkbenchInstance objects. Creates default if none exist.
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
                  // Pass recordName explicitly to fromJson
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

      // Ensure default instance exists if no instances are found
      if (instances.isEmpty) {
        if (kDebugMode) {
          print(
            '[CloudKitService] No instances found, creating default instance.',
          );
        }
        final defaultInstance = WorkbenchInstance.defaultInstance();
        final success = await saveWorkbenchInstance(defaultInstance);
        if (success) {
          // Add the newly created default instance to the list to be returned
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
          // Consider throwing an error or returning empty list if default creation fails
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
      // Attempt to return at least the default instance in case of error fetching others
      try {
        final defaultInstance = WorkbenchInstance.defaultInstance();
        await saveWorkbenchInstance(defaultInstance); // Ensure it exists
        return [defaultInstance];
      } catch (_) {
        return []; // Return empty if even default fails
      }
    }
  }

  /// Deletes a workbench instance from CloudKit by its ID.
  /// Returns true if successful, false otherwise. Cannot delete default instance.
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
      return false; // Prevent deletion of the default instance
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

  /// Saves a workbench item reference to CloudKit.
  /// Returns true if successful, false otherwise.
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
        recordName: item.id, // Use item.id as the recordName
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
        WorkbenchItemReference? item; // Use nullable type
        bool needsMigrationSave = false;
        try {
          // Get raw values and check original instanceId before parsing
          final values = Map<String, dynamic>.from(record.values);
          final originalInstanceId = values['instanceId'];

          // Parse the item using fromJson, which now handles default assignment
          item = WorkbenchItemReference.fromJson(
            values,
            record.recordName, // Pass recordName as the ID source
          );

          // Check if migration occurred (original was null/empty AND current is default)
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

          // Add to list if it matches the filter (or if no filter)
          if (instanceId == null || item.instanceId == instanceId) {
            items.add(item);
          }

          // If migration is needed, queue the save operation
          if (needsMigrationSave) {
            // Pass the *parsed and potentially updated* item to save
            migrationFutures.add(saveWorkbenchItemReference(item));
          }

        } catch (e) {
          if (kDebugMode) {
            print(
              '[CloudKitService] Error parsing WorkbenchItemReference ${record.recordName}: $e. Skipping item.',
            );
          }
          // Continue to the next record if parsing fails
        }
      }

      // Wait for all pending migration saves to complete (fire-and-forget essentially)
      if (migrationFutures.isNotEmpty) {
        // Don't await here to avoid blocking return, but log initiation
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


  /// Deletes a workbench item reference from CloudKit by its ID.
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

  /// Deletes all workbench item references, optionally filtered by instanceId.
  Future<bool> deleteAllWorkbenchItemReferences({String? instanceId}) async {
    if (kDebugMode) {
      print(
        '[CloudKitService] deleteAllWorkbenchItemReferences called${instanceId != null ? ' for instance $instanceId' : ''}',
      );
    }
    try {
      // Fetch only the items that need to be deleted
      final itemsToDelete = await getAllWorkbenchItemReferences(
        instanceId: instanceId, // Apply filter here
      );

      if (itemsToDelete.isEmpty) {
        if (kDebugMode) {
          print(
            '[CloudKitService] No WorkbenchItemReferences found${instanceId != null ? ' for instance $instanceId' : ''} to delete.',
          );
        }
        return true; // Nothing to delete, operation successful
      }

      if (kDebugMode) {
        print(
          '[CloudKitService] Found ${itemsToDelete.length} WorkbenchItemReferences to delete.',
        );
      }

      // Prepare list of record names to delete
      final recordNamesToDelete = itemsToDelete.map((item) => item.id).toList();

      // Use batch delete if available and efficient, otherwise loop
      // Assuming flutter_cloud_kit might not have batch delete, loop for now:
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
          allSucceeded = false; // Mark failure but continue deleting others
        }
      }

      if (kDebugMode) {
        print(
          '[CloudKitService] Finished deleting ${itemsToDelete.length} items. Success: $allSucceeded',
        );
      }
      return allSucceeded;
    } catch (e, s) {
      // Catch errors during the fetch phase
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
        return value.toString(); // CloudKit often returns values as strings
      } else {
        if (kDebugMode) {
          print('[CloudKitService] Setting $keyName not found.');
        }
        return null;
      }
    } catch (e) {
      // Specifically check for "Record not found"
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
      return null; // Return null if record doesn't exist or other error
    }
  }


  Future<bool> saveSetting(String keyName, String value) async {
    if (kDebugMode) print('[CloudKitService] saveSetting called for $keyName');
    try {
      Map<String, dynamic> currentSettings = {};
      try {
        // Attempt to fetch the existing record
        final existingRecord = await _cloudKit.getRecord(
          scope: _scope,
          recordName: _userSettingsRecordName,
        );
        // Check if it's the correct type before using its values
        if (existingRecord.recordType == userSettingsRecordType) {
          currentSettings = Map<String, dynamic>.from(existingRecord.values);
          if (kDebugMode) {
            print('[CloudKitService] Found existing UserSettings record.');
          }
        } else {
          // If record exists but is wrong type, log warning and overwrite
          if (kDebugMode) {
            print(
              '[CloudKitService] Existing record $_userSettingsRecordName has wrong type: ${existingRecord.recordType}. Overwriting.',
            );
          }
          // currentSettings remains empty, effectively starting fresh
        }
      } catch (e) {
        // If fetching fails (e.g., "Record not found"), proceed with empty currentSettings
        if (e is PlatformException &&
            e.message != null &&
            e.message!.contains('Record not found')) {
          if (kDebugMode) {
            print(
              '[CloudKitService] UserSettings record not found, will create new one.',
            );
          }
        } else {
          // Log other fetch errors but still attempt to save
          if (kDebugMode) {
            print(
              '[CloudKitService] Error fetching existing UserSettings, proceeding with save attempt: $e',
            );
          }
        }
      }

      // Update the specific setting
      currentSettings[keyName] = value;

      // Serialize and save the entire settings map
      final recordData = _serializeMap(currentSettings);
      await _cloudKit.saveRecord(
        scope: _scope,
        recordType: userSettingsRecordType, // Ensure correct type is saved
        recordName: _userSettingsRecordName,
        record: recordData,
      );
      if (kDebugMode) {
        print('[CloudKitService] Successfully saved setting $keyName');
      }
      return true;
    } catch (e, s) {
      // Handle potential race condition where record was created between fetch and save
      if (e is PlatformException &&
          e.message != null &&
          e.message!.contains('record to insert already exists')) {
        if (kDebugMode) {
          print(
            '[CloudKitService] Handled "record already exists" conflict for $_userSettingsRecordName. Save likely succeeded or will be retried.',
          );
        }
        // Consider retrying the fetch-update-save cycle or just return true/false based on policy
        return true; // Assume success or let higher level handle retry
      }
      // Log other save errors
      if (kDebugMode) {
        print('[CloudKitService] Error saving setting $keyName: $e\n$s');
      }
      return false;
    }
  }


  // --- Utility Methods ---

  /// Deletes all CloudKit records of a specific type. Use with caution!
  /// For WorkbenchItemReference, prefer using deleteAllWorkbenchItemReferences which supports filtering.
  Future<bool> deleteAllRecordsOfType(String recordType) async {
    // Add specific warnings
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
        return true; // Nothing to delete
      }

      final recordNamesToDelete =
          records
              .map((r) => r.recordName)
              // Explicitly prevent deletion of the default workbench instance
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
      // Use batch delete if available, otherwise loop
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
          allSucceeded = false; // Mark failure but continue
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
      // Handle "Record not found" gracefully
      if (e is PlatformException &&
          e.message != null &&
          e.message!.contains('Record not found')) {
        if (kDebugMode) {
          print(
            '[CloudKitService] UserSettings record already deleted or never existed.',
          );
        }
        return true; // Consider it success if it's already gone
      }
      if (kDebugMode) {
        print('[CloudKitService] Error deleting UserSettings record: $e\n$s');
      }
      return false;
    }
  }
}

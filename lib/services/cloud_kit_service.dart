import 'dart:convert'; // For jsonEncode/Decode

import 'package:flutter/foundation.dart';
// Correct import for flutter_cloud_kit types and main class
import 'package:flutter_cloud_kit/flutter_cloud_kit.dart';
// Import the type using the misspelled filename from the dependency
import 'package:flutter_cloud_kit/types/cloud_ket_record.dart'; // Keep this import path
// Add explicit imports for the required types
import 'package:flutter_cloud_kit/types/cloud_kit_account_status.dart';
import 'package:flutter_cloud_kit/types/database_scope.dart';
import 'package:flutter_memos/models/mcp_server_config.dart'; // Import MCP model (contains the enum)
import 'package:flutter_memos/models/server_config.dart';
// Ensure to import WorkbenchItemReference model and its associated types
import 'package:flutter_memos/models/workbench_item_reference.dart';
// Import the synchronized package
import 'package:synchronized/synchronized.dart';

/// Service to interact with CloudKit for syncing data.
class CloudKitService {
  // IMPORTANT: Replace with your actual container ID from Apple Developer Portal
  // Ensure this matches the one configured in Xcode Capabilities (iOS & macOS)
  // e.g., 'iCloud.com.yourcompany.yourapp'
  static const String _containerId =
      'iCloud.com.erauner.fluttermemos'; // Updated value
  static const String _serverConfigRecordType = 'ServerConfig';
  static const String _userSettingsRecordType = 'UserSettings';
  static const String _userSettingsRecordName = 'user_settings_singleton';
  // Add record type for MCP Servers
  static const String _mcpServerConfigRecordType = 'McpServerConfig';
  // Add record type for Workbench Items
  static const String _workbenchItemReferenceRecordType =
      'WorkbenchItemReference';

  final FlutterCloudKit _cloudKit;
  // Add a lock specifically for the user settings singleton record operations
  final _settingsLock = Lock();

  CloudKitService() : _cloudKit = FlutterCloudKit(containerId: _containerId);

  /// Check the iCloud account status.
  Future<CloudKitAccountStatus> initialize() async {
    // Use CloudKitAccountStatus
    // Use correct type CloudKitAccountStatus
    try {
      final status = await _cloudKit.getAccountStatus();
      if (kDebugMode) {
        print('[CloudKitService] Account Status: \$status');
      }
      return status;
    } catch (e) {
      if (kDebugMode) {
        print('[CloudKitService] Error getting account status: \$e');
      }
      return CloudKitAccountStatus.couldNotDetermine; // Use CloudKitAccountStatus enum value
    }
  }

  // --- ServerConfig (Memos) Methods ---

  /// Convert ServerConfig to a map suitable for CloudKit storage (`Map<String, String>`).
  Map<String, String> _serverConfigToMap(ServerConfig config) {
    // CloudKit fields must match keys here. All values MUST be strings.
    return {
      'name': config.name ?? '', // Ensure null becomes empty string
      'serverUrl': config.serverUrl, // Already a string
      'authToken': config.authToken, // Already a string
      'serverType': config.serverType.name, // <-- ADD serverType field
      // 'id' is the recordName, not stored as a field within the record data
    };
  }

  /// Convert CloudKit record data (`Map<String, dynamic>`) back to a ServerConfig object.
  ServerConfig _mapToServerConfig(
    String recordName,
    Map<String, dynamic> recordData, // Changed type to match CloudKitRecord.values
  ) {
    if (kDebugMode) {
      print(
        '[CloudKitService][_mapToServerConfig] Mapping recordName: \$recordName, data: \$recordData',
      );
    }
    // Access values assuming they are strings, as saved by _serverConfigToMap
    final config = ServerConfig(
      id: recordName, // Use CloudKit's recordName as the unique ID
      name: recordData['name'] as String?, // Cast to String? (or handle null)
      serverUrl: recordData['serverUrl'] as String? ?? '', // Cast and handle null
      authToken: recordData['authToken'] as String? ?? '', // Cast and handle null
      // --- START serverType Parsing ---
      serverType: () {
        ServerType type = ServerType.memos; // Default
        final rawServerType = recordData['serverType'];
        if (kDebugMode) {
          print(
            '[CloudKitService][_mapToServerConfig] Raw serverType from CloudKit data for \$recordName: "\$rawServerType" (Type: \${rawServerType?.runtimeType})',
          );
        }
        if (rawServerType is String) {
          type = ServerType.values.firstWhere(
            (e) => e.name == rawServerType,
            orElse: () {
              if (kDebugMode) {
                print(
                  '[CloudKitService][_mapToServerConfig] Warning: CloudKit serverType "\$rawServerType" invalid for \$recordName, defaulting to memos.',
                );
              }
              return ServerType.memos;
            },
          );
        } else if (rawServerType != null) {
          if (kDebugMode) {
            print(
              '[CloudKitService][_mapToServerConfig] Warning: CloudKit serverType field for \$recordName was not a String (Type: \${rawServerType.runtimeType}), defaulting to memos.',
            );
          }
        }
        return type;
      }(), // Immediately invoke the function to get the type
      // --- END serverType Parsing ---
    );
    if (kDebugMode) {
      print(
        '[CloudKitService][_mapToServerConfig] Mapped result: \${config.toJson()}',
      ); // Log the resulting object
    }
    return config;
  }

  /// Save or update a ServerConfig in CloudKit.
  Future<bool> saveServerConfig(ServerConfig config) async {
    try {
      final mapData = _serverConfigToMap(config);
      // --- Add Logging Here ---
      if (kDebugMode) {
        // Log the serverType being saved (it's part of the config object, but _serverConfigToMap might exclude it)
        // Let's log the type from the original config object for clarity.
        print(
          '[CloudKitService] Preparing to save ServerConfig (ID: \${config.id}, Type: \${config.serverType.name}) to CloudKit with data: \$mapData',
        );
      }
      // --- End Logging ---
      await _cloudKit.saveRecord(
        scope: CloudKitDatabaseScope.private, // Use CloudKitDatabaseScope
        recordType: _serverConfigRecordType,
        recordName: config.id, // Use ServerConfig's ID as the CloudKit recordName
        record: mapData,
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Saved ServerConfig (ID: \${config.id}) successfully.',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error saving ServerConfig (ID: \${config.id}): \$e',
        );
      }
      return false;
    }
  }

  /// Retrieve a single ServerConfig from CloudKit by its ID.
  Future<ServerConfig?> getServerConfig(String id) async {
    try {
      if (kDebugMode) {
        print(
          '[CloudKitService] Getting ServerConfig (ID: \$id) from CloudKit...',
        );
      }
      // getRecord returns CloudKitRecord (due to dependency typo in filename, but correct class name)
      final CloudKitRecord ckRecord = await _cloudKit.getRecord(
        // Use correct class name CloudKitRecord
        scope: CloudKitDatabaseScope.private, // Use CloudKitDatabaseScope enum
        recordName: id,
      );

      // The package might throw an exception if not found.
      // Assuming it throws if not found, and the object is non-null on success.
      if (kDebugMode) {
        print('[CloudKitService] Found ServerConfig (ID: \$id).');
      }
      // Access fields using the '.values' property
      return _mapToServerConfig(ckRecord.recordName, ckRecord.values);
    } catch (e) {
      if (kDebugMode) {
        print('[CloudKitService] Error getting ServerConfig (ID: \$id): \$e');
      }
      return null;
    }
  }

  /// Retrieve all ServerConfig records from CloudKit's private database.
  Future<List<ServerConfig>> getAllServerConfigs() async {
    try {
      if (kDebugMode) {
        print('[CloudKitService] Getting all ServerConfigs from CloudKit...');
      }
      final List<CloudKitRecord> ckRecords = await _cloudKit.getRecordsByType(
        scope: CloudKitDatabaseScope.private, // Use CloudKitDatabaseScope enum
        recordType: _serverConfigRecordType,
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Found \${ckRecords.length} ServerConfig records raw from CloudKit.',
        );
      }
      // Log raw data including inferred type before mapping
      if (kDebugMode) {
        for (final ckRecord in ckRecords) {
          final rawType = ckRecord.values['serverType'];
          print(
            '[CloudKitService] Raw Fetched ServerConfig Record: Name=\${ckRecord.recordName}, Values=\${ckRecord.values}, Raw Type Field="\$rawType"',
          );
        }
      }
      return ckRecords
          .map(
            (ckRecord) =>
                _mapToServerConfig(ckRecord.recordName, ckRecord.values),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('[CloudKitService] Error getting all ServerConfigs: \$e');
      }
      return [];
    }
  }

  /// Delete a ServerConfig from CloudKit by its ID.
  Future<bool> deleteServerConfig(String id) async {
    try {
      if (kDebugMode) {
        print(
          '[CloudKitService] Deleting ServerConfig (ID: \$id) from CloudKit...',
        );
      }
      await _cloudKit.deleteRecord(
        scope: CloudKitDatabaseScope.private, // Use CloudKitDatabaseScope enum
        recordName: id,
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Deleted ServerConfig (ID: \$id) successfully.',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[CloudKitService] Error deleting ServerConfig (ID: \$id): \$e');
      }
      return false;
    }
  }

  /// Delete all records of a specific type from CloudKit's private database.
  Future<bool> deleteAllRecordsOfType(String recordType) async {
    if (kDebugMode) {
      print(
        '[CloudKitService] Attempting to delete all records of type: \$recordType',
      );
    }
    try {
      // 1. Fetch all records of the given type
      final List<CloudKitRecord> ckRecords = await _cloudKit.getRecordsByType(
        scope: CloudKitDatabaseScope.private,
        recordType: recordType,
      );

      if (kDebugMode) {
        print(
          '[CloudKitService] Found \${ckRecords.length} records of type \$recordType to delete.',
        );
      }

      if (ckRecords.isEmpty) {
        return true; // Nothing to delete
      }

      // 2. Extract record names
      final recordNames = ckRecords.map((r) => r.recordName).toList();

      // 3. Delete each record
      for (final recordName in recordNames) {
        try {
          if (kDebugMode) {
            print(
              '[CloudKitService] Deleting record: \$recordName (type: \$recordType)',
            );
          }
          await _cloudKit.deleteRecord(
            scope: CloudKitDatabaseScope.private,
            recordName: recordName,
          );
        } catch (deleteError) {
          if (kDebugMode) {
            print(
              '[CloudKitService] Error deleting record \$recordName (type: \$recordType): \$deleteError',
            );
          }
        }
      }

      if (kDebugMode) {
        print(
          '[CloudKitService] Finished deleting records of type \$recordType.',
        );
      }
      // Return true if the process completed, even if individual deletions failed.
      return true;
    } catch (fetchError) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error fetching records for deletion (type: \$recordType): \$fetchError',
        );
      }
      return false;
    }
  }

  /// Delete the singleton UserSettings record from CloudKit.
  Future<bool> deleteUserSettingsRecord() async {
    if (kDebugMode) {
      print(
        '[CloudKitService] Attempting to delete UserSettings record (\$_userSettingsRecordName)...',
      );
    }
    // Use the lock to prevent conflicts with saveSetting potentially running concurrently
    return _settingsLock.synchronized(() async {
      try {
        await _cloudKit.deleteRecord(
          scope: CloudKitDatabaseScope.private,
          recordName: _userSettingsRecordName,
        );
        if (kDebugMode) {
          print(
            '[CloudKitService] Successfully deleted UserSettings record (\$_userSettingsRecordName).',
          );
        }
        return true;
      } catch (e) {
        if (e.toString().toLowerCase().contains('record not found') ||
            e.toString().toLowerCase().contains('unknown item')) {
          if (kDebugMode) {
            print(
              '[CloudKitService] UserSettings record already deleted or never existed.',
            );
          }
          return true;
        }
        if (kDebugMode) {
          print(
            '[CloudKitService] Error deleting UserSettings record (\$_userSettingsRecordName): \$e',
          );
        }
        return false;
      }
    });
  }

  // --- UserSettings Methods ---
  // (Existing methods for fetching and saving user settings)

  /// Fetches the user settings record from CloudKit.
  Future<CloudKitRecord?> _fetchUserSettingsRecord() async {
    try {
      if (kDebugMode) {
        print('[CloudKitService] Getting UserSettings record...');
      }
      final CloudKitRecord ckRecord = await _cloudKit.getRecord(
        scope: CloudKitDatabaseScope.private,
        recordName: _userSettingsRecordName,
      );
      if (kDebugMode) {
        print('[CloudKitService] Found UserSettings record.');
      }
      return ckRecord;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error getting UserSettings record (may not exist yet): \$e',
        );
      }
      return null;
    }
  }

  /// Retrieve a specific setting value from the UserSettings record.
  Future<String?> getSetting(String keyName) async {
    final CloudKitRecord? ckRecord = await _fetchUserSettingsRecord();
    if (ckRecord != null && ckRecord.values.containsKey(keyName)) {
      final value = ckRecord.values[keyName] as String?;
      if (kDebugMode) {
        print(
          '[CloudKitService] GetSetting: Found value for key "\$keyName": \${value != null && value.isNotEmpty ? "present" : "empty/null"}',
        );
      }
      return value;
    }
    if (kDebugMode) {
      print(
        '[CloudKitService] GetSetting: Key "\$keyName" not found in UserSettings record.',
      );
    }
    return null;
  }

  /// Save or update a specific setting in the UserSettings record.
  Future<bool> saveSetting(String keyName, String value) async {
    return _settingsLock.synchronized(() async {
      CloudKitRecord? ckRecord;
      try {
        ckRecord = await _fetchUserSettingsRecord();
        Map<String, String> dataToSave;
        if (ckRecord != null) {
          dataToSave = Map<String, String>.from(
            ckRecord.values.map((key, val) => MapEntry(key, val.toString())),
          );
          dataToSave[keyName] = value;
        } else {
          dataToSave = {keyName: value};
        }

        if (kDebugMode) {
          print(
            '[CloudKitService] Preparing to save UserSettings with key "\$keyName". Merged Data: \$dataToSave',
          );
        }

        if (ckRecord != null) {
          try {
            if (kDebugMode) {
              print(
                '[CloudKitService] Deleting existing UserSettings record before saving...',
              );
            }
            await _cloudKit.deleteRecord(
              scope: CloudKitDatabaseScope.private,
              recordName: _userSettingsRecordName,
            );
            if (kDebugMode) {
              print(
                '[CloudKitService] Successfully deleted existing UserSettings record.',
              );
            }
          } catch (deleteError) {
            if (kDebugMode) {
              print(
                '[CloudKitService] Error deleting existing UserSettings record (proceeding to save): \$deleteError',
              );
            }
          }
        }

        if (kDebugMode) {
          print(
            '[CloudKitService] Saving UserSettings record (attempting insert)...',
          );
        }
        await _cloudKit.saveRecord(
          scope: CloudKitDatabaseScope.private,
          recordType: _userSettingsRecordType,
          recordName: _userSettingsRecordName,
          record: dataToSave,
        );

        if (kDebugMode) {
          print('[CloudKitService] Saved UserSettings successfully.');
        }
        return true;
      } catch (e) {
        if (kDebugMode) {
          print(
            '[CloudKitService] Error saving UserSettings for key "\$keyName" (within synchronized block): \$e',
          );
        }
        return false;
      }
    });
  }

  // --- MCP ServerConfig Methods ---
  // (Existing methods for MCP ServerConfig)

  /// Convert McpServerConfig to a map suitable for CloudKit storage (`Map<String, String>`).
  Map<String, String> _mcpServerConfigToMap(McpServerConfig config) {
    return {
      'name': config.name,
      'connectionType': config.connectionType.name, // Store enum name
      'command': config.command,
      'args': config.args,
      'host': config.host ?? '', // Store nullable string, default to empty
      'port': config.port.toString(),
      'isActive': config.isActive.toString(), // Store bool as string 'true'/'false'
      'customEnvironment': jsonEncode(
        config.customEnvironment,
      ), // Store the environment map as a JSON string
    };
  }

  /// Convert CloudKit record data (`Map<String, dynamic>`) back to an McpServerConfig object.
  McpServerConfig _mapToMcpServerConfig(
    String recordName,
    Map<String, dynamic> recordData,
  ) {
    if (kDebugMode) {
      print(
        '[CloudKitService][_mapToMcpServerConfig] Mapping recordName: \$recordName, data: \$recordData',
      );
    }

    // Safely parse the custom environment JSON string
    Map<String, String> environment = {};
    final envString = recordData['customEnvironment'] as String?;
    if (envString != null && envString.isNotEmpty) {
      try {
        final decodedMap = jsonDecode(envString);
        if (decodedMap is Map) {
          environment = Map<String, String>.from(
            decodedMap.map((k, v) => MapEntry(k.toString(), v.toString())),
          );
        }
      } catch (e) {
        debugPrint(
          "Error parsing customEnvironment JSON string from CloudKit for server \$recordName: \$e",
        );
      }
    }

    // Parse connectionType safely, defaulting to stdio if missing/invalid
    McpConnectionType parsedConnectionType = McpConnectionType.stdio;
    final typeString = recordData['connectionType'] as String?;
    if (typeString != null) {
      try {
        parsedConnectionType = McpConnectionType.values.byName(typeString);
      } catch (_) {
        debugPrint(
          "Invalid connectionType '\$typeString' found for server \$recordName, defaulting to stdio.",
        );
      }
    } else {
      debugPrint(
        "Missing connectionType for server \$recordName, defaulting to stdio.",
      );
      final potentialHost = recordData['host'] as String?;
      final potentialPortStr = recordData['port'] as String?;
      final potentialPort =
          (potentialPortStr != null && potentialPortStr.isNotEmpty)
              ? int.tryParse(potentialPortStr)
              : null;
      if (potentialHost != null &&
          potentialHost.isNotEmpty &&
          potentialPort != null &&
          potentialPort > 0) {
        debugPrint(
          "Applying heuristic: Assuming SSE type due to valid host/port for server \$recordName.",
        );
        parsedConnectionType = McpConnectionType.sse;
      }
    }

    String? parsedHost = recordData['host'] as String?;
    if (parsedHost != null && parsedHost.isEmpty) {
      parsedHost = null;
    }

    int? parsedPort;
    final portString = recordData['port'] as String?;
    if (portString != null && portString.isNotEmpty) {
      parsedPort = int.tryParse(portString);
      if (parsedPort == null || parsedPort <= 0 || parsedPort > 65535) {
        debugPrint(
          "Invalid port value '\$portString' found for server \$recordName, setting port to null.",
        );
        parsedPort = null;
      }
    }

    final config = McpServerConfig(
      id: recordName,
      name: recordData['name'] as String? ?? '',
      connectionType: parsedConnectionType,
      command: recordData['command'] as String? ?? '',
      args: recordData['args'] as String? ?? '',
      host: parsedHost,
      port: parsedPort,
      isActive: (recordData['isActive'] as String?)?.toLowerCase() == 'true',
      customEnvironment: environment,
    );

    if (kDebugMode) {
      print('[CloudKitService][_mapToMcpServerConfig] Mapped result: \$config');
    }
    return config;
  }

  /// Save or update an McpServerConfig in CloudKit.
  Future<bool> saveMcpServerConfig(McpServerConfig config) async {
    try {
      final mapData = _mcpServerConfigToMap(config);
      if (kDebugMode) {
        print(
          '[CloudKitService] Saving McpServerConfig (ID: \${config.id}) to CloudKit with data: \$mapData',
        );
      }
      await _cloudKit.saveRecord(
        scope: CloudKitDatabaseScope.private,
        recordType: _mcpServerConfigRecordType,
        recordName: config.id,
        record: mapData,
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Saved McpServerConfig (ID: \${config.id}) successfully.',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error saving McpServerConfig (ID: \${config.id}): \$e',
        );
      }
      return false;
    }
  }

  /// Retrieve all McpServerConfig records from CloudKit's private database.
  Future<List<McpServerConfig>> getAllMcpServerConfigs() async {
    try {
      if (kDebugMode) {
        print(
          '[CloudKitService] Getting all McpServerConfigs from CloudKit...',
        );
      }
      final List<CloudKitRecord> ckRecords = await _cloudKit.getRecordsByType(
        scope: CloudKitDatabaseScope.private,
        recordType: _mcpServerConfigRecordType,
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Found \${ckRecords.length} McpServerConfig records raw from CloudKit.',
        );
      }
      return ckRecords
          .map(
            (ckRecord) =>
                _mapToMcpServerConfig(ckRecord.recordName, ckRecord.values),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('[CloudKitService] Error getting all McpServerConfigs: \$e');
      }
      return [];
    }
  }

  /// Delete an McpServerConfig from CloudKit by its ID.
  Future<bool> deleteMcpServerConfig(String id) async {
    try {
      if (kDebugMode) {
        print(
          '[CloudKitService] Deleting McpServerConfig (ID: \$id) from CloudKit...',
        );
      }
      await _cloudKit.deleteRecord(
        scope: CloudKitDatabaseScope.private,
        recordName: id,
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Deleted McpServerConfig (ID: \$id) successfully.',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error deleting McpServerConfig (ID: \$id): \$e',
        );
      }
      return false;
    }
  }

  // --- WorkbenchItemReference Methods ---

  /// Convert WorkbenchItemReference to a map suitable for CloudKit storage (`Map<String, String>`).
  Map<String, String> _workbenchItemReferenceToMap(
    WorkbenchItemReference item,
  ) {
    return {
      // 'id' is the recordName, not stored as a field
      'referencedItemId': item.referencedItemId,
      'referencedItemType': item.referencedItemType.name, // Store enum name
      'serverId': item.serverId,
      'serverType': item.serverType.name, // Store enum name
      'serverName': item.serverName ?? '', // Handle null
      'previewContent': item.previewContent ?? '', // Handle null
      'addedTimestamp': item.addedTimestamp.toIso8601String(), // Store as ISO string
      // Add the new lastOpenedTimestamp field, store as ISO string or empty if null
      'lastOpenedTimestamp': item.lastOpenedTimestamp?.toIso8601String() ?? '',
    };
  }

  /// Convert CloudKit record data (`Map<String, dynamic>`) back to a WorkbenchItemReference object.
  WorkbenchItemReference _mapToWorkbenchItemReference(
    String recordName, // This is the WorkbenchItemReference.id
    Map<String, dynamic> recordData,
  ) {
    if (kDebugMode) {
      print(
        '[CloudKitService][_mapToWorkbenchItemReference] Mapping recordName: \$recordName, data: \$recordData',
      );
    }

    // Helper to parse enums safely
    T parseEnum<T extends Enum>(
      List<T> enumValues,
      String? name,
      T defaultValue,
    ) {
      if (name == null) return defaultValue;
      try {
        // Find enum value by comparing its .name property to the stored string
        return enumValues.firstWhere(
          (e) => e.name == name,
          orElse: () {
            if (kDebugMode) {
              print(
                '[CloudKitService][_mapToWorkbenchItemReference] Warning: Invalid enum value "\$name" for type \$T, using default \$defaultValue.',
              );
            }
            return defaultValue;
          },
        );
      } catch (e) {
        // Catch potential errors during lookup
        if (kDebugMode) {
          print(
            '[CloudKitService][_mapToWorkbenchItemReference] Error parsing enum value "\$name" for type \$T: \$e. Using default \$defaultValue.',
          );
        }
        return defaultValue;
      }
    }

    final item = WorkbenchItemReference(
      id: recordName, // Use CloudKit recordName as the reference's unique ID
      referencedItemId: recordData['referencedItemId'] as String? ?? '',
      referencedItemType: parseEnum<WorkbenchItemType>(
        // Explicitly type the generic
        WorkbenchItemType.values,
        recordData['referencedItemType'] as String?,
        WorkbenchItemType.note, // Default if parsing fails
      ),
      serverId: recordData['serverId'] as String? ?? '',
      serverType: parseEnum<ServerType>(
        // Explicitly type the generic
        ServerType.values,
        recordData['serverType'] as String?,
        ServerType.memos, // Default if parsing fails
      ),
      serverName: recordData['serverName'] as String?,
      previewContent: recordData['previewContent'] as String?,
      addedTimestamp: DateTime.tryParse(recordData['addedTimestamp'] as String? ?? '') ??
          DateTime.now(), // Default to now if parsing fails
      // Parse the new lastOpenedTimestamp field
      lastOpenedTimestamp: DateTime.tryParse(
        recordData['lastOpenedTimestamp'] as String? ?? '',
      ),
    );

    if (kDebugMode) {
      print(
        '[CloudKitService][_mapToWorkbenchItemReference] Mapped result: \$item',
      );
    }
    return item;
  }

  /// Save or update a WorkbenchItemReference in CloudKit.
  Future<bool> saveWorkbenchItemReference(WorkbenchItemReference item) async {
    try {
      final mapData = _workbenchItemReferenceToMap(item);
      if (kDebugMode) {
        print(
          '[CloudKitService] Saving WorkbenchItemReference (ID: \${item.id}) to CloudKit with data: \$mapData',
        );
      }
      await _cloudKit.saveRecord(
        scope: CloudKitDatabaseScope.private,
        recordType: _workbenchItemReferenceRecordType,
        recordName: item.id, // Use WorkbenchItemReference's ID as the CloudKit recordName
        record: mapData,
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Saved WorkbenchItemReference (ID: \${item.id}) successfully.',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error saving WorkbenchItemReference (ID: \${item.id}): \$e',
        );
      }
      return false;
    }
  }

  /// Retrieve all WorkbenchItemReference records from CloudKit's private database.
  Future<List<WorkbenchItemReference>> getAllWorkbenchItemReferences() async {
    try {
      if (kDebugMode) {
        print(
          '[CloudKitService] Getting all WorkbenchItemReferences from CloudKit...',
        );
      }
      // Import WorkbenchItemReference model at the top
      final List<CloudKitRecord> ckRecords = await _cloudKit.getRecordsByType(
        scope: CloudKitDatabaseScope.private,
        recordType: _workbenchItemReferenceRecordType,
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Found \${ckRecords.length} WorkbenchItemReference records raw from CloudKit.',
        );
      }
      return ckRecords
          .map(
            (ckRecord) => _mapToWorkbenchItemReference(
              ckRecord.recordName,
              ckRecord.values,
            ),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error getting all WorkbenchItemReferences: \$e',
        );
      }
      return []; // Return empty list on error
    }
  }

  /// Delete a WorkbenchItemReference from CloudKit by its ID.
  Future<bool> deleteWorkbenchItemReference(String referenceId) async {
    try {
      if (kDebugMode) {
        print(
          '[CloudKitService] Deleting WorkbenchItemReference (ID: \$referenceId) from CloudKit...',
        );
      }
      await _cloudKit.deleteRecord(
        scope: CloudKitDatabaseScope.private,
        recordName: referenceId, // The ID of the reference is the record name
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Deleted WorkbenchItemReference (ID: \$referenceId) successfully.',
        );
      }
      return true;
    } catch (e) {
      if (e.toString().toLowerCase().contains('record not found') ||
          e.toString().toLowerCase().contains('unknown item')) {
        if (kDebugMode) {
          print(
            '[CloudKitService] WorkbenchItemReference (ID: \$referenceId) not found for deletion (already deleted?).',
          );
        }
        return true; // Consider deletion successful if it doesn't exist
      }
      if (kDebugMode) {
        print(
          '[CloudKitService] Error deleting WorkbenchItemReference (ID: \$referenceId): \$e',
        );
      }
      return false;
    }
  }

  /// Updates only the lastOpenedTimestamp for a specific WorkbenchItemReference.
  Future<bool> updateWorkbenchItemLastOpened(String referenceId) async {
    try {
      if (kDebugMode) {
        print(
          '[CloudKitService] Updating lastOpenedTimestamp for WorkbenchItemReference (ID: \$referenceId)...',
        );
      }
      // 1. Fetch the existing record
      final CloudKitRecord ckRecord = await _cloudKit.getRecord(
        scope: CloudKitDatabaseScope.private,
        recordName: referenceId,
      );

      // 2. Prepare the update map - only include the timestamp
      final Map<String, String> updateData = {
        'lastOpenedTimestamp': DateTime.now().toIso8601String(),
      };

      // 3. Save the record with only the updated field
      // Note: flutter_cloud_kit's saveRecord might overwrite fields not present
      // in the `record` map if the underlying native implementation does.
      // A safer approach if partial updates aren't supported is to merge:
      final Map<String, String> mergedData = Map<String, String>.from(
        ckRecord.values.map((key, value) => MapEntry(key, value.toString())),
      )..addAll(updateData);

      await _cloudKit.saveRecord(
        scope: CloudKitDatabaseScope.private,
        recordType: _workbenchItemReferenceRecordType,
        recordName: referenceId,
        record: mergedData, // Save the merged data
      );

      if (kDebugMode) {
        print(
          '[CloudKitService] Updated lastOpenedTimestamp for WorkbenchItemReference (ID: \$referenceId) successfully.',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error updating lastOpenedTimestamp for WorkbenchItemReference (ID: \$referenceId): \$e',
        );
      }
      return false;
    }
  }

} // End of CloudKitService class

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
      return CloudKitAccountStatus.couldNotDetermine;
    }
  }

  // --- ServerConfig (Memos) Methods ---

  /// Convert ServerConfig to a map suitable for CloudKit storage (`Map<String, String>`).
  Map<String, String> _serverConfigToMap(ServerConfig config) {
    return {
      'name': config.name ?? '',
      'serverUrl': config.serverUrl,
      'authToken': config.authToken,
      'serverType': config.serverType.name,
    };
  }

  /// Convert CloudKit record data (`Map<String, dynamic>`) back to a ServerConfig object.
  ServerConfig _mapToServerConfig(
    String recordName,
    Map<String, dynamic> recordData,
  ) {
    if (kDebugMode) {
      print(
        '[CloudKitService][_mapToServerConfig] Mapping recordName: \$recordName, data: \$recordData',
      );
    }
    final config = ServerConfig(
      id: recordName,
      name: recordData['name'] as String?,
      serverUrl: recordData['serverUrl'] as String? ?? '',
      authToken: recordData['authToken'] as String? ?? '',
      serverType: () {
        ServerType type = ServerType.memos;
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
      }(),
    );
    if (kDebugMode) {
      print(
        '[CloudKitService][_mapToServerConfig] Mapped result: \${config.toJson()}',
      );
    }
    return config;
  }

  /// Save or update a ServerConfig in CloudKit.
  Future<bool> saveServerConfig(ServerConfig config) async {
    try {
      final mapData = _serverConfigToMap(config);
      if (kDebugMode) {
        print(
          '[CloudKitService] Preparing to save ServerConfig (ID: \${config.id}, Type: \${config.serverType.name}) to CloudKit with data: \$mapData',
        );
      }
      await _cloudKit.saveRecord(
        scope: CloudKitDatabaseScope.private,
        recordType: _serverConfigRecordType,
        recordName: config.id,
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
      final CloudKitRecord ckRecord = await _cloudKit.getRecord(
        scope: CloudKitDatabaseScope.private,
        recordName: id,
      );
      if (kDebugMode) {
        print('[CloudKitService] Found ServerConfig (ID: \$id).');
      }
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
        scope: CloudKitDatabaseScope.private,
        recordType: _serverConfigRecordType,
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Found \${ckRecords.length} ServerConfig records raw from CloudKit.',
        );
      }
      if (kDebugMode) {
        for (final ckRecord in ckRecords) {
          print(
            '[CloudKitService] Raw Fetched ServerConfig Record: Name=\${ckRecord.recordName}, Values=\${ckRecord.values}',
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
        scope: CloudKitDatabaseScope.private,
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
        return true;
      }

      final recordNames = ckRecords.map((r) => r.recordName).toList();

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

  /// Convert McpServerConfig to a map suitable for CloudKit storage (`Map<String, String>`).
  Map<String, String> _mcpServerConfigToMap(McpServerConfig config) {
    return {
      'name': config.name,
      'connectionType': config.connectionType.name,
      'command': config.command,
      'args': config.args,
      'host': config.host ?? '',
      'port': config.port.toString(),
      'isActive': config.isActive.toString(),
      'customEnvironment': jsonEncode(
        config.customEnvironment,
      ),
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
    final map = {
      // 'id' is the recordName, not stored as a field
      'referencedItemId': item.referencedItemId,
      'referencedItemType':
          item.referencedItemType.name, // Store enum name as String
      'serverId': item.serverId,
      'serverType': item.serverType.name, // Store enum name as String
      'serverName':
          item.serverName ?? '', // Store String, default to empty if null
      'previewContent':
          item.previewContent ?? '', // Store String, default to empty if null
      'addedTimestamp':
          item.addedTimestamp.toIso8601String(), // Store DateTime as ISO String
      // Add parentNoteId if needed in the future
      // 'parentNoteId': item.parentNoteId ?? '',
    };

    // Conditionally add lastOpenedTimestamp only if it's not null
    if (item.lastOpenedTimestamp != null) {
      map['lastOpenedTimestamp'] = item.lastOpenedTimestamp!.toIso8601String();
    }

    return map;
  }

  /// Convert CloudKit record data (`Map<String, dynamic>`) back to a WorkbenchItemReference object.
  WorkbenchItemReference _mapToWorkbenchItemReference(
    String recordName,
    Map<String, dynamic> recordData,
  ) {
    if (kDebugMode) {
      print(
        '[CloudKitService][_mapToWorkbenchItemReference] Mapping recordName: \$recordName, data: \$recordData',
      );
    }

    T parseEnum<T extends Enum>(
      List<T> enumValues,
      String? name,
      T defaultValue,
    ) {
      if (name == null) return defaultValue;
      try {
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
        if (kDebugMode) {
          print(
            '[CloudKitService][_mapToWorkbenchItemReference] Error parsing enum value "\$name" for type \$T: \$e. Using default \$defaultValue.',
          );
        }
        return defaultValue;
      }
    }

    DateTime? parseDateTimeRobustly(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      if (kDebugMode) {
        print(
          '[CloudKitService][_mapToWorkbenchItemReference] Warning: Unexpected type for DateTime field: \${value.runtimeType}. Value: \$value',
        );
      }
      return null;
    }

    final item = WorkbenchItemReference(
      id: recordName,
      referencedItemId: recordData['referencedItemId'] as String? ?? '',
      referencedItemType: parseEnum<WorkbenchItemType>(
        WorkbenchItemType.values,
        recordData['referencedItemType'] as String?,
        WorkbenchItemType.note,
      ),
      serverId: recordData['serverId'] as String? ?? '',
      serverType: parseEnum<ServerType>(
        ServerType.values,
        recordData['serverType'] as String?,
        ServerType.memos,
      ),
      serverName: recordData['serverName'] as String?,
      previewContent: recordData['previewContent'] as String?,
      addedTimestamp:
          parseDateTimeRobustly(recordData['addedTimestamp']) ?? DateTime.now(),
      lastOpenedTimestamp: parseDateTimeRobustly(
        recordData['lastOpenedTimestamp'],
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
      final Map<String, String> mapData = _workbenchItemReferenceToMap(item);
      if (kDebugMode) {
        // Log the exact data being sent
        print(
          '[CloudKitService] Saving WorkbenchItemReference (ID: ${item.id}) to CloudKit with data: $mapData',
        );
      }
      await _cloudKit.saveRecord(
        scope: CloudKitDatabaseScope.private,
        recordType: _workbenchItemReferenceRecordType,
        recordName:
            item.id, // Use WorkbenchItemReference\'s ID as the CloudKit recordName
        record: mapData, // Pass the Map<String, String>
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Saved WorkbenchItemReference (ID: ${item.id}) successfully.',
        );
      }
      return true;
    } catch (e) {
      // Removed unused stack trace variable 's'
      // Add stack trace logging if needed, but variable 's' is removed if unused
      if (kDebugMode) {
        print(
          '[CloudKitService] Error saving WorkbenchItemReference (ID: ${item.id}): $e', // Log error only
        );
        // If stack trace is needed: print('[CloudKitService] Error saving WorkbenchItemReference (ID: ${item.id}): $e\n$s');
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
      return [];
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
        recordName: referenceId,
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
        return true;
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
          '[CloudKitService] Updating lastOpenedTimestamp for WorkbenchItemReference (ID: $referenceId)...',
        );
      }
      // 1. Fetch the existing record.
      final CloudKitRecord ckRecord = await _cloudKit.getRecord(
        scope: CloudKitDatabaseScope.private,
        recordName: referenceId,
      );

      // 2. Convert fetched values (Map<String, dynamic>) to Map<String, String>
      //    Handle potential null values during conversion.
      final Map<String, String> dataToSave = ckRecord.values.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      // Update the timestamp field with an ISO 8601 string.
      dataToSave['lastOpenedTimestamp'] =
          DateTime.now().toIso8601String(); // Use ISO String

      if (kDebugMode) {
        print(
          '[CloudKitService] updateWorkbenchItemLastOpened: Saving data: $dataToSave',
        );
      }

      // 3. Save the record with the modified Map<String, String>.
      await _cloudKit.saveRecord(
        scope: CloudKitDatabaseScope.private,
        recordType: _workbenchItemReferenceRecordType,
        recordName: referenceId, // Use the ID as the record name
        record: dataToSave, // Save the map with the updated timestamp string
      );

      if (kDebugMode) {
        print(
          '[CloudKitService] Updated lastOpenedTimestamp for WorkbenchItemReference (ID: $referenceId) successfully.',
        );
      }
      return true;
    } catch (e) {
      // Removed unused stack trace variable 's'
      // Log specific CloudKit errors if possible
      if (kDebugMode) {
        print(
          '[CloudKitService] Error updating lastOpenedTimestamp for WorkbenchItemReference (ID: $referenceId): $e', // Log error only
        );
        // If stack trace is needed: print('[CloudKitService] Error updating lastOpenedTimestamp for WorkbenchItemReference (ID: $referenceId): $e\n$s');
      }
      return false;
    }
  }
}

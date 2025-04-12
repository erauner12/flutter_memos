import 'dart:convert'; // For jsonEncode/Decode

import 'package:flutter/foundation.dart';
// Correct import for flutter_cloud_kit types and main class
import 'package:flutter_cloud_kit/flutter_cloud_kit.dart';
// Import the type using the misspelled filename from the dependency
import 'package:flutter_cloud_kit/types/cloud_ket_record.dart'; // Keep this import path
// Add explicit imports for the required types
import 'package:flutter_cloud_kit/types/cloud_kit_account_status.dart';
import 'package:flutter_cloud_kit/types/database_scope.dart';
import 'package:flutter_memos/models/mcp_connection_type.dart'; // Import MCP connection type
import 'package:flutter_memos/models/mcp_server_config.dart'; // Import MCP model
import 'package:flutter_memos/models/server_config.dart';
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
      return CloudKitAccountStatus
          .couldNotDetermine; // Use CloudKitAccountStatus enum value
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
      // 'id' is the recordName, not stored as a field within the record data
    };
  }

  /// Convert CloudKit record data (`Map<String, dynamic>`) back to a ServerConfig object.
  ServerConfig _mapToServerConfig(
    String recordName,
    Map<String, dynamic>
    recordData, // Changed type to match CloudKitRecord.values
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
      serverUrl:
          recordData['serverUrl'] as String? ?? '', // Cast and handle null
      authToken:
          recordData['authToken'] as String? ?? '', // Cast and handle null
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
      if (kDebugMode) {
        print(
          '[CloudKitService] Saving ServerConfig (ID: \${config.id}) to CloudKit with data: \$mapData',
        );
      }
      await _cloudKit.saveRecord(
        scope: CloudKitDatabaseScope.private, // Use CloudKitDatabaseScope
        recordType: _serverConfigRecordType,
        recordName:
            config.id, // Use ServerConfig's ID as the CloudKit recordName
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
      // Handle specific CloudKit errors if needed, e.g., record not found might throw
      if (kDebugMode) {
        // Check if the error indicates "Record not found" specifically if possible
        print('[CloudKitService] Error getting ServerConfig (ID: \$id): \$e');
      }
      return null; // Return null if record not found or other error
    }
  }

  /// Retrieve all ServerConfig records from CloudKit's private database.
  Future<List<ServerConfig>> getAllServerConfigs() async {
    try {
      if (kDebugMode) {
        print('[CloudKitService] Getting all ServerConfigs from CloudKit...');
      }
      // getRecordsByType returns List<CloudKitRecord> (due to dependency typo in filename, but correct class name)
      final List<CloudKitRecord> ckRecords = await _cloudKit.getRecordsByType(
        // Use correct class name CloudKitRecord
        scope: CloudKitDatabaseScope.private, // Use CloudKitDatabaseScope enum
        recordType: _serverConfigRecordType,
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Found \${ckRecords.length} ServerConfig records raw from CloudKit.',
        );
        // Add detailed logging for each record
        for (final ckRecord in ckRecords) {
          print(
            '[CloudKitService][Raw Record] recordName: \${ckRecord.recordName}, values: \${ckRecord.values}',
          );
        }
      }
      // Map using the '.values' property
      return ckRecords
          .map(
            (ckRecord) => _mapToServerConfig(
              ckRecord.recordName, ckRecord.values,
            ),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('[CloudKitService] Error getting all ServerConfigs: \$e');
      }
      return []; // Return empty list on error
    }
  }

  /// Delete a ServerConfig from CloudKit by its ID.
  Future<bool> deleteServerConfig(String id) async {
    // Add the function body here
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
      return true; // Return true on success
    } catch (e) {
      if (kDebugMode) {
        print('[CloudKitService] Error deleting ServerConfig (ID: \$id): \$e');
      }
      return false; // Return false on error
    }
  }

  // --- UserSettings Methods ---

  /// Fetches the user settings record from CloudKit.
  Future<CloudKitRecord?> _fetchUserSettingsRecord() async {
    // Use correct class name CloudKitRecord
    try {
      if (kDebugMode) {
        print('[CloudKitService] Getting UserSettings record...');
      }
      // The getRecord method returns the correct CloudKitRecord type
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
      return null; // Return null if not found or error
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
    // CloudKit fields must match keys here. All values MUST be strings.
    return {
      'name': config.name,
      'connectionType': config.connectionType.name, // Store enum name
      'command': config.command,
      'args': config.args,
      'host':
          config.host ?? '', // Store nullable string, default to empty if null
      'port':
          config.port.toString() ??
          '', // Store nullable int as string, default to empty if null
      'isActive':
          config.isActive.toString(), // Store bool as string 'true'/'false'
      // Store the environment map as a JSON string
      'customEnvironment': jsonEncode(config.customEnvironment),
      // 'id' is the recordName, not stored as a field within the record data
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
    McpConnectionType parsedConnectionType = McpConnectionType.stdio; // Default
    final typeString = recordData['connectionType'] as String?;
    if (typeString != null) {
      try {
        parsedConnectionType = McpConnectionType.values.byName(typeString);
      } catch (_) {
        debugPrint(
          "Invalid connectionType '\$typeString' found for server \$recordName, defaulting to stdio.",
        );
        // Keep default stdio
      }
    } else {
      debugPrint(
        "Missing connectionType for server \$recordName, defaulting to stdio.",
      );
      // Apply heuristic for old data: if host/port look valid, assume SSE
      final potentialHost = recordData['host'] as String?;
      final potentialPortStr =
          recordData['port'] as String?; // Port stored as string
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

    // Parse host (nullable) - Treat empty string from CK as null
    String? parsedHost = recordData['host'] as String?;
    if (parsedHost != null && parsedHost.isEmpty) {
      parsedHost = null;
    }

    // Parse port from string safely (nullable)
    int? parsedPort; // Default to null
    final portString = recordData['port'] as String?; // Expect string
    if (portString != null && portString.isNotEmpty) {
      parsedPort = int.tryParse(portString);
      // Invalidate if not parseable or out of range
      if (parsedPort == null || parsedPort <= 0 || parsedPort > 65535) {
        debugPrint(
          "Invalid port value '\$portString' found for server \$recordName, setting port to null.",
        );
        parsedPort = null;
      }
    }

    final config = McpServerConfig(
      id: recordName, // Use CloudKit's recordName as the unique ID
      name: recordData['name'] as String? ?? '',
      connectionType: parsedConnectionType, // Use parsed type
      command: recordData['command'] as String? ?? '',
      args: recordData['args'] as String? ?? '',
      host: parsedHost, // Use nullable host
      port: parsedPort, // Use nullable port
      // Parse bool from string, default to false if invalid/missing
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
        recordName: config.id, // Use McpServerConfig's ID as the recordName
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
        for (final ckRecord in ckRecords) {
          print(
            '[CloudKitService][Raw MCP Record] recordName: \${ckRecord.recordName}, values: \${ckRecord.values}',
          );
        }
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
      return []; // Return empty list on error
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
}

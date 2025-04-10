import 'package:flutter/foundation.dart';
// Correct import for flutter_cloud_kit types and main class
import 'package:flutter_cloud_kit/flutter_cloud_kit.dart';
// Import the type using the misspelled filename from the dependency
import 'package:flutter_cloud_kit/types/cloud_ket_record.dart'; // Keep this import path
// Add explicit imports for the required types
import 'package:flutter_cloud_kit/types/cloud_kit_account_status.dart';
import 'package:flutter_cloud_kit/types/database_scope.dart';
import 'package:flutter_memos/models/server_config.dart';

/// Service to interact with CloudKit for syncing data.
class CloudKitService {
  // IMPORTANT: Replace with your actual container ID from Apple Developer Portal
  // Ensure this matches the one configured in Xcode Capabilities (iOS & macOS)
  // e.g., 'iCloud.com.yourcompany.yourapp'
  static const String _containerId =
      'iCloud.com.erauner.fluttermemos'; // Updated value
  static const String _serverConfigRecordType = 'ServerConfig';
  // Add constants for UserSettings
  static const String _userSettingsRecordType = 'UserSettings';
  // Use a fixed name for the single settings record per user
  static const String _userSettingsRecordName = 'user_settings_singleton';

  final FlutterCloudKit _cloudKit;

  CloudKitService() : _cloudKit = FlutterCloudKit(containerId: _containerId);

  /// Check the iCloud account status.
  Future<CloudKitAccountStatus> initialize() async {
    // Use CloudKitAccountStatus
    // Use correct type CloudKitAccountStatus
    try {
      final status = await _cloudKit.getAccountStatus();
      if (kDebugMode) {
        print('[CloudKitService] Account Status: $status');
      }
      return status;
    } catch (e) {
      if (kDebugMode) {
        print('[CloudKitService] Error getting account status: $e');
      }
      return CloudKitAccountStatus
          .couldNotDetermine; // Use CloudKitAccountStatus enum value
    }
  }

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
        '[CloudKitService][_mapToServerConfig] Mapping recordName: $recordName, data: $recordData',
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
        '[CloudKitService][_mapToServerConfig] Mapped result: ${config.toJson()}',
      ); // Log the resulting object
    }
    return config;
  }

  /// Fetches the user settings record from CloudKit.
  Future<CloudKitRecord?> _fetchUserSettingsRecord() async {
    // Use correct class name CloudKitRecord
    // Changed CloudKitRecord to CloudKetRecord
    try {
      if (kDebugMode) {
        print('[CloudKitService] Getting UserSettings record...');
      }
      // The getRecord method returns the correct CloudKitRecord type
      final CloudKitRecord ckRecord = await _cloudKit.getRecord(
        // Use correct class name CloudKitRecord
        scope: CloudKitDatabaseScope.private,
        recordName: _userSettingsRecordName,
      );
      if (kDebugMode) {
        print('[CloudKitService] Found UserSettings record.');
      }
      return ckRecord;
    } catch (e) {
      // Specifically check if the error means "record not found"
      // The plugin might throw a specific exception type or have an error code.
      // For now, assume any error means it might not exist or is inaccessible.
      if (kDebugMode) {
        print(
          '[CloudKitService] Error getting UserSettings record (may not exist yet): $e',
        );
      }
      return null; // Return null if not found or error
    }
  }

  /// Save or update a ServerConfig in CloudKit.
  Future<bool> saveServerConfig(ServerConfig config) async {
    try {
      final mapData = _serverConfigToMap(config);
      if (kDebugMode) {
        print(
          '[CloudKitService] Saving ServerConfig (ID: ${config.id}) to CloudKit with data: $mapData',
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
          '[CloudKitService] Saved ServerConfig (ID: ${config.id}) successfully.',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error saving ServerConfig (ID: ${config.id}): $e',
        );
      }
      return false;
    }
  }

  /// Retrieve a single ServerConfig from CloudKit by its ID.
  Future<ServerConfig?> getServerConfig(String id) async {
    try {
      if (kDebugMode) {
        print('[CloudKitService] Getting ServerConfig (ID: $id) from CloudKit...');
      }
      // getRecord returns CloudKitRecord (due to dependency typo in filename, but correct class name)
      // Remove unnecessary nullable type annotation '?'
      final CloudKitRecord ckRecord = await _cloudKit.getRecord(
        // Use correct class name CloudKitRecord
        // Changed CloudKitRecord to CloudKetRecord
        scope: CloudKitDatabaseScope.private, // Use CloudKitDatabaseScope enum
        recordName: id,
      );

      // The package might throw an exception if not found.
      // Assuming it throws if not found, and the object is non-null on success.

      if (kDebugMode) {
        print('[CloudKitService] Found ServerConfig (ID: $id).');
      }
      // Access fields using the '.values' property
      return _mapToServerConfig(ckRecord.recordName, ckRecord.values);
    } catch (e) {
      // Handle specific CloudKit errors if needed, e.g., record not found might throw
      if (kDebugMode) {
        // Check if the error indicates "Record not found" specifically if possible
        print('[CloudKitService] Error getting ServerConfig (ID: $id): $e');
      }
      return null; // Return null if record not found or other error
    }
  }

  /// Retrieve a specific setting value from the UserSettings record.
  Future<String?> getSetting(String keyName) async {
    final CloudKitRecord? ckRecord =
        // Use correct class name CloudKitRecord
        await _fetchUserSettingsRecord(); // Changed CloudKitRecord to CloudKetRecord
    // Add null check before accessing properties
    if (ckRecord != null && ckRecord.values.containsKey(keyName)) {
      // Assuming the value was stored as a string
      final value = ckRecord.values[keyName] as String?;
      if (kDebugMode) {
        print(
          '[CloudKitService] GetSetting: Found value for key "$keyName": ${value != null && value.isNotEmpty ? "present" : "empty/null"}',
        );
      }
      return value;
    }
    if (kDebugMode) {
      print(
        '[CloudKitService] GetSetting: Key "$keyName" not found in UserSettings record.',
      );
    }
    return null;
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
        // Changed CloudKitRecord to CloudKetRecord
        scope: CloudKitDatabaseScope.private, // Use CloudKitDatabaseScope enum
        recordType: _serverConfigRecordType,
      );
      if (kDebugMode) {
        print(
          '[CloudKitService] Found ${ckRecords.length} ServerConfig records raw from CloudKit.',
        );
        // Add detailed logging for each record
        for (final CloudKitRecord ckRecord in ckRecords) {
          // Use correct class name CloudKitRecord
          // Changed CloudKitRecord to CloudKetRecord
          print(
            '[CloudKitService][Raw Record] recordName: ${ckRecord.recordName}, values: ${ckRecord.values}',
          );
        }
      }
      // Map using the '.values' property
      return ckRecords
          .map(
            (ckRecord) => _mapToServerConfig(
              ckRecord
                  .recordName, // No null check needed here as ckRecord is from a non-null list
              ckRecord.values, // Use .values
            ),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('[CloudKitService] Error getting all ServerConfigs: $e');
      }
      return []; // Return empty list on error
    }
  }

  /// Save or update a specific setting in the UserSettings record.
  Future<bool> saveSetting(String keyName, String value) async {
    try {
      // Fetch existing settings or start with an empty map
      final CloudKitRecord? ckRecord =
          // Use correct class name CloudKitRecord
          await _fetchUserSettingsRecord(); // Changed CloudKitRecord to CloudKetRecord
      // Ensure the map is mutable and correctly typed
      // Use null-aware operator '?.' to access values only if ckRecord is not null
      final Map<String, String> currentSettings =
          ckRecord?.values.map((key, val) => MapEntry(key, val.toString())) ??
          {}; // Ensure string map and handle null

      // Update the specific setting
      currentSettings[keyName] = value;

      if (kDebugMode) {
        // Be cautious logging sensitive values like API keys
        print(
          '[CloudKitService] Saving UserSettings with updated key "$keyName". Current keys: ${currentSettings.keys.join(', ')}',
        );
      }

      // Save the entire updated map back to the singleton record
      await _cloudKit.saveRecord(
        scope: CloudKitDatabaseScope.private,
        recordType: _userSettingsRecordType,
        recordName: _userSettingsRecordName, // Use fixed name
        record: currentSettings, // Save the full map
      );

      if (kDebugMode) {
        print('[CloudKitService] Saved UserSettings successfully.');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[CloudKitService] Error saving UserSettings for key "$keyName": $e',
        );
      }
      return false;
    }
  }

  /// Delete a ServerConfig from CloudKit by its ID.
  Future<bool> deleteServerConfig(String id) async {
    try {
      if (kDebugMode) {
        print('[CloudKitService] Deleting ServerConfig (ID: $id) from CloudKit...');
      }
      await _cloudKit.deleteRecord(
        scope: CloudKitDatabaseScope.private, // Use CloudKitDatabaseScope
        recordName: id,
      );
      if (kDebugMode) {
        print('[CloudKitService] Deleted ServerConfig (ID: $id) successfully.');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[CloudKitService] Error deleting ServerConfig (ID: $id): $e');
      }
      return false;
    }
  }
}

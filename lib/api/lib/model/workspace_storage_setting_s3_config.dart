//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class WorkspaceStorageSettingS3Config {
  /// Returns a new [WorkspaceStorageSettingS3Config] instance.
  WorkspaceStorageSettingS3Config({
    this.accessKeyId,
    this.accessKeySecret,
    this.endpoint,
    this.region,
    this.bucket,
    this.usePathStyle,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? accessKeyId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? accessKeySecret;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? endpoint;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? region;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? bucket;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? usePathStyle;

  @override
  bool operator ==(Object other) => identical(this, other) || other is WorkspaceStorageSettingS3Config &&
    other.accessKeyId == accessKeyId &&
    other.accessKeySecret == accessKeySecret &&
    other.endpoint == endpoint &&
    other.region == region &&
    other.bucket == bucket &&
    other.usePathStyle == usePathStyle;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (accessKeyId == null ? 0 : accessKeyId!.hashCode) +
    (accessKeySecret == null ? 0 : accessKeySecret!.hashCode) +
    (endpoint == null ? 0 : endpoint!.hashCode) +
    (region == null ? 0 : region!.hashCode) +
    (bucket == null ? 0 : bucket!.hashCode) +
    (usePathStyle == null ? 0 : usePathStyle!.hashCode);

  @override
  String toString() => 'WorkspaceStorageSettingS3Config[accessKeyId=$accessKeyId, accessKeySecret=$accessKeySecret, endpoint=$endpoint, region=$region, bucket=$bucket, usePathStyle=$usePathStyle]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.accessKeyId != null) {
      json[r'accessKeyId'] = this.accessKeyId;
    } else {
      json[r'accessKeyId'] = null;
    }
    if (this.accessKeySecret != null) {
      json[r'accessKeySecret'] = this.accessKeySecret;
    } else {
      json[r'accessKeySecret'] = null;
    }
    if (this.endpoint != null) {
      json[r'endpoint'] = this.endpoint;
    } else {
      json[r'endpoint'] = null;
    }
    if (this.region != null) {
      json[r'region'] = this.region;
    } else {
      json[r'region'] = null;
    }
    if (this.bucket != null) {
      json[r'bucket'] = this.bucket;
    } else {
      json[r'bucket'] = null;
    }
    if (this.usePathStyle != null) {
      json[r'usePathStyle'] = this.usePathStyle;
    } else {
      json[r'usePathStyle'] = null;
    }
    return json;
  }

  /// Returns a new [WorkspaceStorageSettingS3Config] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WorkspaceStorageSettingS3Config? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "WorkspaceStorageSettingS3Config[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "WorkspaceStorageSettingS3Config[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return WorkspaceStorageSettingS3Config(
        accessKeyId: mapValueOfType<String>(json, r'accessKeyId'),
        accessKeySecret: mapValueOfType<String>(json, r'accessKeySecret'),
        endpoint: mapValueOfType<String>(json, r'endpoint'),
        region: mapValueOfType<String>(json, r'region'),
        bucket: mapValueOfType<String>(json, r'bucket'),
        usePathStyle: mapValueOfType<bool>(json, r'usePathStyle'),
      );
    }
    return null;
  }

  static List<WorkspaceStorageSettingS3Config> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkspaceStorageSettingS3Config>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkspaceStorageSettingS3Config.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WorkspaceStorageSettingS3Config> mapFromJson(dynamic json) {
    final map = <String, WorkspaceStorageSettingS3Config>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WorkspaceStorageSettingS3Config.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WorkspaceStorageSettingS3Config-objects as value to a dart map
  static Map<String, List<WorkspaceStorageSettingS3Config>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<WorkspaceStorageSettingS3Config>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WorkspaceStorageSettingS3Config.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


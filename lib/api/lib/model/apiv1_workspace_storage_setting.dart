//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Apiv1WorkspaceStorageSetting {
  /// Returns a new [Apiv1WorkspaceStorageSetting] instance.
  Apiv1WorkspaceStorageSetting({
    this.storageType,
    this.filepathTemplate,
    this.uploadSizeLimitMb,
    this.s3Config,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Apiv1WorkspaceStorageSettingStorageType? storageType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? filepathTemplate;

  /// The max upload size in megabytes.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? uploadSizeLimitMb;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  WorkspaceStorageSettingS3Config? s3Config;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Apiv1WorkspaceStorageSetting &&
    other.storageType == storageType &&
    other.filepathTemplate == filepathTemplate &&
    other.uploadSizeLimitMb == uploadSizeLimitMb &&
    other.s3Config == s3Config;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (storageType == null ? 0 : storageType!.hashCode) +
    (filepathTemplate == null ? 0 : filepathTemplate!.hashCode) +
    (uploadSizeLimitMb == null ? 0 : uploadSizeLimitMb!.hashCode) +
    (s3Config == null ? 0 : s3Config!.hashCode);

  @override
  String toString() => 'Apiv1WorkspaceStorageSetting[storageType=$storageType, filepathTemplate=$filepathTemplate, uploadSizeLimitMb=$uploadSizeLimitMb, s3Config=$s3Config]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.storageType != null) {
      json[r'storageType'] = this.storageType;
    } else {
      json[r'storageType'] = null;
    }
    if (this.filepathTemplate != null) {
      json[r'filepathTemplate'] = this.filepathTemplate;
    } else {
      json[r'filepathTemplate'] = null;
    }
    if (this.uploadSizeLimitMb != null) {
      json[r'uploadSizeLimitMb'] = this.uploadSizeLimitMb;
    } else {
      json[r'uploadSizeLimitMb'] = null;
    }
    if (this.s3Config != null) {
      json[r's3Config'] = this.s3Config;
    } else {
      json[r's3Config'] = null;
    }
    return json;
  }

  /// Returns a new [Apiv1WorkspaceStorageSetting] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Apiv1WorkspaceStorageSetting? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Apiv1WorkspaceStorageSetting[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Apiv1WorkspaceStorageSetting[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Apiv1WorkspaceStorageSetting(
        storageType: Apiv1WorkspaceStorageSettingStorageType.fromJson(json[r'storageType']),
        filepathTemplate: mapValueOfType<String>(json, r'filepathTemplate'),
        uploadSizeLimitMb: mapValueOfType<String>(json, r'uploadSizeLimitMb'),
        s3Config: WorkspaceStorageSettingS3Config.fromJson(json[r's3Config']),
      );
    }
    return null;
  }

  static List<Apiv1WorkspaceStorageSetting> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Apiv1WorkspaceStorageSetting>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Apiv1WorkspaceStorageSetting.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Apiv1WorkspaceStorageSetting> mapFromJson(dynamic json) {
    final map = <String, Apiv1WorkspaceStorageSetting>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Apiv1WorkspaceStorageSetting.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Apiv1WorkspaceStorageSetting-objects as value to a dart map
  static Map<String, List<Apiv1WorkspaceStorageSetting>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Apiv1WorkspaceStorageSetting>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Apiv1WorkspaceStorageSetting.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


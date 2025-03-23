//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class V1WorkspaceProfile {
  /// Returns a new [V1WorkspaceProfile] instance.
  V1WorkspaceProfile({
    this.owner,
    this.version,
    this.mode,
    this.instanceUrl,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? owner;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? version;

  /// mode is the instance mode (e.g. \"prod\", \"dev\" or \"demo\").
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? mode;

  /// instance_url is the URL of the instance.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? instanceUrl;

  @override
  bool operator ==(Object other) => identical(this, other) || other is V1WorkspaceProfile &&
    other.owner == owner &&
    other.version == version &&
    other.mode == mode &&
    other.instanceUrl == instanceUrl;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (owner == null ? 0 : owner!.hashCode) +
    (version == null ? 0 : version!.hashCode) +
    (mode == null ? 0 : mode!.hashCode) +
    (instanceUrl == null ? 0 : instanceUrl!.hashCode);

  @override
  String toString() => 'V1WorkspaceProfile[owner=$owner, version=$version, mode=$mode, instanceUrl=$instanceUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.owner != null) {
      json[r'owner'] = this.owner;
    } else {
      json[r'owner'] = null;
    }
    if (this.version != null) {
      json[r'version'] = this.version;
    } else {
      json[r'version'] = null;
    }
    if (this.mode != null) {
      json[r'mode'] = this.mode;
    } else {
      json[r'mode'] = null;
    }
    if (this.instanceUrl != null) {
      json[r'instanceUrl'] = this.instanceUrl;
    } else {
      json[r'instanceUrl'] = null;
    }
    return json;
  }

  /// Returns a new [V1WorkspaceProfile] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static V1WorkspaceProfile? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "V1WorkspaceProfile[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "V1WorkspaceProfile[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return V1WorkspaceProfile(
        owner: mapValueOfType<String>(json, r'owner'),
        version: mapValueOfType<String>(json, r'version'),
        mode: mapValueOfType<String>(json, r'mode'),
        instanceUrl: mapValueOfType<String>(json, r'instanceUrl'),
      );
    }
    return null;
  }

  static List<V1WorkspaceProfile> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1WorkspaceProfile>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1WorkspaceProfile.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, V1WorkspaceProfile> mapFromJson(dynamic json) {
    final map = <String, V1WorkspaceProfile>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = V1WorkspaceProfile.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of V1WorkspaceProfile-objects as value to a dart map
  static Map<String, List<V1WorkspaceProfile>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<V1WorkspaceProfile>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = V1WorkspaceProfile.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


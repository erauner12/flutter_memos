//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Apiv1WorkspaceSetting {
  /// Returns a new [Apiv1WorkspaceSetting] instance.
  Apiv1WorkspaceSetting({
    this.name,
    this.generalSetting,
    this.storageSetting,
    this.memoRelatedSetting,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Apiv1WorkspaceGeneralSetting? generalSetting;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Apiv1WorkspaceStorageSetting? storageSetting;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Apiv1WorkspaceMemoRelatedSetting? memoRelatedSetting;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Apiv1WorkspaceSetting &&
    other.name == name &&
    other.generalSetting == generalSetting &&
    other.storageSetting == storageSetting &&
    other.memoRelatedSetting == memoRelatedSetting;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (generalSetting == null ? 0 : generalSetting!.hashCode) +
    (storageSetting == null ? 0 : storageSetting!.hashCode) +
    (memoRelatedSetting == null ? 0 : memoRelatedSetting!.hashCode);

  @override
  String toString() => 'Apiv1WorkspaceSetting[name=$name, generalSetting=$generalSetting, storageSetting=$storageSetting, memoRelatedSetting=$memoRelatedSetting]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.generalSetting != null) {
      json[r'generalSetting'] = this.generalSetting;
    } else {
      json[r'generalSetting'] = null;
    }
    if (this.storageSetting != null) {
      json[r'storageSetting'] = this.storageSetting;
    } else {
      json[r'storageSetting'] = null;
    }
    if (this.memoRelatedSetting != null) {
      json[r'memoRelatedSetting'] = this.memoRelatedSetting;
    } else {
      json[r'memoRelatedSetting'] = null;
    }
    return json;
  }

  /// Returns a new [Apiv1WorkspaceSetting] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Apiv1WorkspaceSetting? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Apiv1WorkspaceSetting[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Apiv1WorkspaceSetting[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Apiv1WorkspaceSetting(
        name: mapValueOfType<String>(json, r'name'),
        generalSetting: Apiv1WorkspaceGeneralSetting.fromJson(json[r'generalSetting']),
        storageSetting: Apiv1WorkspaceStorageSetting.fromJson(json[r'storageSetting']),
        memoRelatedSetting: Apiv1WorkspaceMemoRelatedSetting.fromJson(json[r'memoRelatedSetting']),
      );
    }
    return null;
  }

  static List<Apiv1WorkspaceSetting> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Apiv1WorkspaceSetting>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Apiv1WorkspaceSetting.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Apiv1WorkspaceSetting> mapFromJson(dynamic json) {
    final map = <String, Apiv1WorkspaceSetting>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Apiv1WorkspaceSetting.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Apiv1WorkspaceSetting-objects as value to a dart map
  static Map<String, List<Apiv1WorkspaceSetting>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Apiv1WorkspaceSetting>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Apiv1WorkspaceSetting.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


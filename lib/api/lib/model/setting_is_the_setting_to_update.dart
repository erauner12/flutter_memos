//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SettingIsTheSettingToUpdate {
  /// Returns a new [SettingIsTheSettingToUpdate] instance.
  SettingIsTheSettingToUpdate({
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
  bool operator ==(Object other) => identical(this, other) || other is SettingIsTheSettingToUpdate &&
    other.generalSetting == generalSetting &&
    other.storageSetting == storageSetting &&
    other.memoRelatedSetting == memoRelatedSetting;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (generalSetting == null ? 0 : generalSetting!.hashCode) +
    (storageSetting == null ? 0 : storageSetting!.hashCode) +
    (memoRelatedSetting == null ? 0 : memoRelatedSetting!.hashCode);

  @override
  String toString() => 'SettingIsTheSettingToUpdate[generalSetting=$generalSetting, storageSetting=$storageSetting, memoRelatedSetting=$memoRelatedSetting]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
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

  /// Returns a new [SettingIsTheSettingToUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SettingIsTheSettingToUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SettingIsTheSettingToUpdate[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SettingIsTheSettingToUpdate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SettingIsTheSettingToUpdate(
        generalSetting: Apiv1WorkspaceGeneralSetting.fromJson(json[r'generalSetting']),
        storageSetting: Apiv1WorkspaceStorageSetting.fromJson(json[r'storageSetting']),
        memoRelatedSetting: Apiv1WorkspaceMemoRelatedSetting.fromJson(json[r'memoRelatedSetting']),
      );
    }
    return null;
  }

  static List<SettingIsTheSettingToUpdate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SettingIsTheSettingToUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SettingIsTheSettingToUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SettingIsTheSettingToUpdate> mapFromJson(dynamic json) {
    final map = <String, SettingIsTheSettingToUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SettingIsTheSettingToUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SettingIsTheSettingToUpdate-objects as value to a dart map
  static Map<String, List<SettingIsTheSettingToUpdate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SettingIsTheSettingToUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SettingIsTheSettingToUpdate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


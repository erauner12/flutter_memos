//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UserServiceUpdateUserSettingRequest {
  /// Returns a new [UserServiceUpdateUserSettingRequest] instance.
  UserServiceUpdateUserSettingRequest({
    this.locale,
    this.appearance,
    this.memoVisibility,
  });

  /// The preferred locale of the user.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? locale;

  /// The preferred appearance of the user.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? appearance;

  /// The default visibility of the memo.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? memoVisibility;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserServiceUpdateUserSettingRequest &&
    other.locale == locale &&
    other.appearance == appearance &&
    other.memoVisibility == memoVisibility;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (locale == null ? 0 : locale!.hashCode) +
    (appearance == null ? 0 : appearance!.hashCode) +
    (memoVisibility == null ? 0 : memoVisibility!.hashCode);

  @override
  String toString() => 'UserServiceUpdateUserSettingRequest[locale=$locale, appearance=$appearance, memoVisibility=$memoVisibility]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.locale != null) {
      json[r'locale'] = this.locale;
    } else {
      json[r'locale'] = null;
    }
    if (this.appearance != null) {
      json[r'appearance'] = this.appearance;
    } else {
      json[r'appearance'] = null;
    }
    if (this.memoVisibility != null) {
      json[r'memoVisibility'] = this.memoVisibility;
    } else {
      json[r'memoVisibility'] = null;
    }
    return json;
  }

  /// Returns a new [UserServiceUpdateUserSettingRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserServiceUpdateUserSettingRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UserServiceUpdateUserSettingRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UserServiceUpdateUserSettingRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UserServiceUpdateUserSettingRequest(
        locale: mapValueOfType<String>(json, r'locale'),
        appearance: mapValueOfType<String>(json, r'appearance'),
        memoVisibility: mapValueOfType<String>(json, r'memoVisibility'),
      );
    }
    return null;
  }

  static List<UserServiceUpdateUserSettingRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserServiceUpdateUserSettingRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserServiceUpdateUserSettingRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserServiceUpdateUserSettingRequest> mapFromJson(dynamic json) {
    final map = <String, UserServiceUpdateUserSettingRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserServiceUpdateUserSettingRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserServiceUpdateUserSettingRequest-objects as value to a dart map
  static Map<String, List<UserServiceUpdateUserSettingRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UserServiceUpdateUserSettingRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserServiceUpdateUserSettingRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


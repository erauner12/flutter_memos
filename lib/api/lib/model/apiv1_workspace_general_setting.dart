//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Apiv1WorkspaceGeneralSetting {
  /// Returns a new [Apiv1WorkspaceGeneralSetting] instance.
  Apiv1WorkspaceGeneralSetting({
    this.disallowUserRegistration,
    this.disallowPasswordAuth,
    this.additionalScript,
    this.additionalStyle,
    this.customProfile,
    this.weekStartDayOffset,
    this.disallowChangeUsername,
    this.disallowChangeNickname,
  });

  /// disallow_user_registration disallows user registration.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? disallowUserRegistration;

  /// disallow_password_auth disallows password authentication.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? disallowPasswordAuth;

  /// additional_script is the additional script.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? additionalScript;

  /// additional_style is the additional style.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? additionalStyle;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Apiv1WorkspaceCustomProfile? customProfile;

  /// week_start_day_offset is the week start day offset from Sunday. 0: Sunday, 1: Monday, 2: Tuesday, 3: Wednesday, 4: Thursday, 5: Friday, 6: Saturday Default is Sunday.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? weekStartDayOffset;

  /// disallow_change_username disallows changing username.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? disallowChangeUsername;

  /// disallow_change_nickname disallows changing nickname.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? disallowChangeNickname;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Apiv1WorkspaceGeneralSetting &&
    other.disallowUserRegistration == disallowUserRegistration &&
    other.disallowPasswordAuth == disallowPasswordAuth &&
    other.additionalScript == additionalScript &&
    other.additionalStyle == additionalStyle &&
    other.customProfile == customProfile &&
    other.weekStartDayOffset == weekStartDayOffset &&
    other.disallowChangeUsername == disallowChangeUsername &&
    other.disallowChangeNickname == disallowChangeNickname;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (disallowUserRegistration == null ? 0 : disallowUserRegistration!.hashCode) +
    (disallowPasswordAuth == null ? 0 : disallowPasswordAuth!.hashCode) +
    (additionalScript == null ? 0 : additionalScript!.hashCode) +
    (additionalStyle == null ? 0 : additionalStyle!.hashCode) +
    (customProfile == null ? 0 : customProfile!.hashCode) +
    (weekStartDayOffset == null ? 0 : weekStartDayOffset!.hashCode) +
    (disallowChangeUsername == null ? 0 : disallowChangeUsername!.hashCode) +
    (disallowChangeNickname == null ? 0 : disallowChangeNickname!.hashCode);

  @override
  String toString() => 'Apiv1WorkspaceGeneralSetting[disallowUserRegistration=$disallowUserRegistration, disallowPasswordAuth=$disallowPasswordAuth, additionalScript=$additionalScript, additionalStyle=$additionalStyle, customProfile=$customProfile, weekStartDayOffset=$weekStartDayOffset, disallowChangeUsername=$disallowChangeUsername, disallowChangeNickname=$disallowChangeNickname]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.disallowUserRegistration != null) {
      json[r'disallowUserRegistration'] = this.disallowUserRegistration;
    } else {
      json[r'disallowUserRegistration'] = null;
    }
    if (this.disallowPasswordAuth != null) {
      json[r'disallowPasswordAuth'] = this.disallowPasswordAuth;
    } else {
      json[r'disallowPasswordAuth'] = null;
    }
    if (this.additionalScript != null) {
      json[r'additionalScript'] = this.additionalScript;
    } else {
      json[r'additionalScript'] = null;
    }
    if (this.additionalStyle != null) {
      json[r'additionalStyle'] = this.additionalStyle;
    } else {
      json[r'additionalStyle'] = null;
    }
    if (this.customProfile != null) {
      json[r'customProfile'] = this.customProfile;
    } else {
      json[r'customProfile'] = null;
    }
    if (this.weekStartDayOffset != null) {
      json[r'weekStartDayOffset'] = this.weekStartDayOffset;
    } else {
      json[r'weekStartDayOffset'] = null;
    }
    if (this.disallowChangeUsername != null) {
      json[r'disallowChangeUsername'] = this.disallowChangeUsername;
    } else {
      json[r'disallowChangeUsername'] = null;
    }
    if (this.disallowChangeNickname != null) {
      json[r'disallowChangeNickname'] = this.disallowChangeNickname;
    } else {
      json[r'disallowChangeNickname'] = null;
    }
    return json;
  }

  /// Returns a new [Apiv1WorkspaceGeneralSetting] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Apiv1WorkspaceGeneralSetting? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Apiv1WorkspaceGeneralSetting[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Apiv1WorkspaceGeneralSetting[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Apiv1WorkspaceGeneralSetting(
        disallowUserRegistration: mapValueOfType<bool>(json, r'disallowUserRegistration'),
        disallowPasswordAuth: mapValueOfType<bool>(json, r'disallowPasswordAuth'),
        additionalScript: mapValueOfType<String>(json, r'additionalScript'),
        additionalStyle: mapValueOfType<String>(json, r'additionalStyle'),
        customProfile: Apiv1WorkspaceCustomProfile.fromJson(json[r'customProfile']),
        weekStartDayOffset: mapValueOfType<int>(json, r'weekStartDayOffset'),
        disallowChangeUsername: mapValueOfType<bool>(json, r'disallowChangeUsername'),
        disallowChangeNickname: mapValueOfType<bool>(json, r'disallowChangeNickname'),
      );
    }
    return null;
  }

  static List<Apiv1WorkspaceGeneralSetting> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Apiv1WorkspaceGeneralSetting>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Apiv1WorkspaceGeneralSetting.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Apiv1WorkspaceGeneralSetting> mapFromJson(dynamic json) {
    final map = <String, Apiv1WorkspaceGeneralSetting>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Apiv1WorkspaceGeneralSetting.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Apiv1WorkspaceGeneralSetting-objects as value to a dart map
  static Map<String, List<Apiv1WorkspaceGeneralSetting>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Apiv1WorkspaceGeneralSetting>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Apiv1WorkspaceGeneralSetting.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


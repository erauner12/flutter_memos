//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Apiv1WorkspaceCustomProfile {
  /// Returns a new [Apiv1WorkspaceCustomProfile] instance.
  Apiv1WorkspaceCustomProfile({
    this.title,
    this.description,
    this.logoUrl,
    this.locale,
    this.appearance,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? title;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? logoUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? locale;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? appearance;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Apiv1WorkspaceCustomProfile &&
    other.title == title &&
    other.description == description &&
    other.logoUrl == logoUrl &&
    other.locale == locale &&
    other.appearance == appearance;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (title == null ? 0 : title!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (logoUrl == null ? 0 : logoUrl!.hashCode) +
    (locale == null ? 0 : locale!.hashCode) +
    (appearance == null ? 0 : appearance!.hashCode);

  @override
  String toString() => 'Apiv1WorkspaceCustomProfile[title=$title, description=$description, logoUrl=$logoUrl, locale=$locale, appearance=$appearance]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.title != null) {
      json[r'title'] = this.title;
    } else {
      json[r'title'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.logoUrl != null) {
      json[r'logoUrl'] = this.logoUrl;
    } else {
      json[r'logoUrl'] = null;
    }
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
    return json;
  }

  /// Returns a new [Apiv1WorkspaceCustomProfile] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Apiv1WorkspaceCustomProfile? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Apiv1WorkspaceCustomProfile[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Apiv1WorkspaceCustomProfile[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Apiv1WorkspaceCustomProfile(
        title: mapValueOfType<String>(json, r'title'),
        description: mapValueOfType<String>(json, r'description'),
        logoUrl: mapValueOfType<String>(json, r'logoUrl'),
        locale: mapValueOfType<String>(json, r'locale'),
        appearance: mapValueOfType<String>(json, r'appearance'),
      );
    }
    return null;
  }

  static List<Apiv1WorkspaceCustomProfile> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Apiv1WorkspaceCustomProfile>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Apiv1WorkspaceCustomProfile.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Apiv1WorkspaceCustomProfile> mapFromJson(dynamic json) {
    final map = <String, Apiv1WorkspaceCustomProfile>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Apiv1WorkspaceCustomProfile.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Apiv1WorkspaceCustomProfile-objects as value to a dart map
  static Map<String, List<Apiv1WorkspaceCustomProfile>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Apiv1WorkspaceCustomProfile>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Apiv1WorkspaceCustomProfile.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


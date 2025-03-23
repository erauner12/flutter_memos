//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TheIdentityProviderToUpdate {
  /// Returns a new [TheIdentityProviderToUpdate] instance.
  TheIdentityProviderToUpdate({
    this.type,
    this.title,
    this.identifierFilter,
    this.config,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Apiv1IdentityProviderType? type;

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
  String? identifierFilter;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Apiv1IdentityProviderConfig? config;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TheIdentityProviderToUpdate &&
    other.type == type &&
    other.title == title &&
    other.identifierFilter == identifierFilter &&
    other.config == config;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type == null ? 0 : type!.hashCode) +
    (title == null ? 0 : title!.hashCode) +
    (identifierFilter == null ? 0 : identifierFilter!.hashCode) +
    (config == null ? 0 : config!.hashCode);

  @override
  String toString() => 'TheIdentityProviderToUpdate[type=$type, title=$title, identifierFilter=$identifierFilter, config=$config]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.title != null) {
      json[r'title'] = this.title;
    } else {
      json[r'title'] = null;
    }
    if (this.identifierFilter != null) {
      json[r'identifierFilter'] = this.identifierFilter;
    } else {
      json[r'identifierFilter'] = null;
    }
    if (this.config != null) {
      json[r'config'] = this.config;
    } else {
      json[r'config'] = null;
    }
    return json;
  }

  /// Returns a new [TheIdentityProviderToUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TheIdentityProviderToUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TheIdentityProviderToUpdate[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TheIdentityProviderToUpdate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TheIdentityProviderToUpdate(
        type: Apiv1IdentityProviderType.fromJson(json[r'type']),
        title: mapValueOfType<String>(json, r'title'),
        identifierFilter: mapValueOfType<String>(json, r'identifierFilter'),
        config: Apiv1IdentityProviderConfig.fromJson(json[r'config']),
      );
    }
    return null;
  }

  static List<TheIdentityProviderToUpdate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TheIdentityProviderToUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TheIdentityProviderToUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TheIdentityProviderToUpdate> mapFromJson(dynamic json) {
    final map = <String, TheIdentityProviderToUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TheIdentityProviderToUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TheIdentityProviderToUpdate-objects as value to a dart map
  static Map<String, List<TheIdentityProviderToUpdate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TheIdentityProviderToUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TheIdentityProviderToUpdate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


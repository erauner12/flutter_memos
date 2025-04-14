//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PublicSiteInfo200Response {
  /// Returns a new [PublicSiteInfo200Response] instance.
  PublicSiteInfo200Response({
    required this.id,
    this.name,
    this.image,
    this.description,
    this.role,
  });

  num id;

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
  String? image;

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
  String? role;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PublicSiteInfo200Response &&
    other.id == id &&
    other.name == name &&
    other.image == image &&
    other.description == description &&
    other.role == role;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (image == null ? 0 : image!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (role == null ? 0 : role!.hashCode);

  @override
  String toString() => 'PublicSiteInfo200Response[id=$id, name=$name, image=$image, description=$description, role=$role]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.image != null) {
      json[r'image'] = this.image;
    } else {
      json[r'image'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.role != null) {
      json[r'role'] = this.role;
    } else {
      json[r'role'] = null;
    }
    return json;
  }

  /// Returns a new [PublicSiteInfo200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PublicSiteInfo200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PublicSiteInfo200Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PublicSiteInfo200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PublicSiteInfo200Response(
        id: num.parse('${json[r'id']}'),
        name: mapValueOfType<String>(json, r'name'),
        image: mapValueOfType<String>(json, r'image'),
        description: mapValueOfType<String>(json, r'description'),
        role: mapValueOfType<String>(json, r'role'),
      );
    }
    return null;
  }

  static List<PublicSiteInfo200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PublicSiteInfo200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PublicSiteInfo200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PublicSiteInfo200Response> mapFromJson(dynamic json) {
    final map = <String, PublicSiteInfo200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PublicSiteInfo200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PublicSiteInfo200Response-objects as value to a dart map
  static Map<String, List<PublicSiteInfo200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PublicSiteInfo200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PublicSiteInfo200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
  };
}


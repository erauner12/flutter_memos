//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PublicHubList200ResponseInner {
  /// Returns a new [PublicHubList200ResponseInner] instance.
  PublicHubList200ResponseInner({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
  });

  String id;

  String name;

  String image;

  String description;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PublicHubList200ResponseInner &&
    other.id == id &&
    other.name == name &&
    other.image == image &&
    other.description == description;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (image.hashCode) +
    (description.hashCode);

  @override
  String toString() => 'PublicHubList200ResponseInner[id=$id, name=$name, image=$image, description=$description]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'image'] = this.image;
      json[r'description'] = this.description;
    return json;
  }

  /// Returns a new [PublicHubList200ResponseInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PublicHubList200ResponseInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PublicHubList200ResponseInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PublicHubList200ResponseInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PublicHubList200ResponseInner(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        image: mapValueOfType<String>(json, r'image')!,
        description: mapValueOfType<String>(json, r'description')!,
      );
    }
    return null;
  }

  static List<PublicHubList200ResponseInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PublicHubList200ResponseInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PublicHubList200ResponseInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PublicHubList200ResponseInner> mapFromJson(dynamic json) {
    final map = <String, PublicHubList200ResponseInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PublicHubList200ResponseInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PublicHubList200ResponseInner-objects as value to a dart map
  static Map<String, List<PublicHubList200ResponseInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PublicHubList200ResponseInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PublicHubList200ResponseInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'image',
    'description',
  };
}


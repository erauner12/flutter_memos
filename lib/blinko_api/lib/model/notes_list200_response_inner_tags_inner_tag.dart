//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesList200ResponseInnerTagsInnerTag {
  /// Returns a new [NotesList200ResponseInnerTagsInnerTag] instance.
  NotesList200ResponseInnerTagsInnerTag({
    required this.id,
    required this.name,
    required this.icon,
    required this.parent,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  int id;

  String name;

  String icon;

  int parent;

  int sortOrder;

  String createdAt;

  String updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesList200ResponseInnerTagsInnerTag &&
    other.id == id &&
    other.name == name &&
    other.icon == icon &&
    other.parent == parent &&
    other.sortOrder == sortOrder &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (icon.hashCode) +
    (parent.hashCode) +
    (sortOrder.hashCode) +
    (createdAt.hashCode) +
    (updatedAt.hashCode);

  @override
  String toString() => 'NotesList200ResponseInnerTagsInnerTag[id=$id, name=$name, icon=$icon, parent=$parent, sortOrder=$sortOrder, createdAt=$createdAt, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'icon'] = this.icon;
      json[r'parent'] = this.parent;
      json[r'sortOrder'] = this.sortOrder;
      json[r'createdAt'] = this.createdAt;
      json[r'updatedAt'] = this.updatedAt;
    return json;
  }

  /// Returns a new [NotesList200ResponseInnerTagsInnerTag] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesList200ResponseInnerTagsInnerTag? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesList200ResponseInnerTagsInnerTag[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesList200ResponseInnerTagsInnerTag[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesList200ResponseInnerTagsInnerTag(
        id: mapValueOfType<int>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        icon: mapValueOfType<String>(json, r'icon')!,
        parent: mapValueOfType<int>(json, r'parent')!,
        sortOrder: mapValueOfType<int>(json, r'sortOrder')!,
        createdAt: mapValueOfType<String>(json, r'createdAt')!,
        updatedAt: mapValueOfType<String>(json, r'updatedAt')!,
      );
    }
    return null;
  }

  static List<NotesList200ResponseInnerTagsInnerTag> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesList200ResponseInnerTagsInnerTag>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesList200ResponseInnerTagsInnerTag.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesList200ResponseInnerTagsInnerTag> mapFromJson(dynamic json) {
    final map = <String, NotesList200ResponseInnerTagsInnerTag>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesList200ResponseInnerTagsInnerTag.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesList200ResponseInnerTagsInnerTag-objects as value to a dart map
  static Map<String, List<NotesList200ResponseInnerTagsInnerTag>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesList200ResponseInnerTagsInnerTag>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesList200ResponseInnerTagsInnerTag.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'icon',
    'parent',
    'sortOrder',
    'createdAt',
    'updatedAt',
  };
}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TagsUpdateTagNameRequest {
  /// Returns a new [TagsUpdateTagNameRequest] instance.
  TagsUpdateTagNameRequest({
    required this.oldName,
    required this.newName,
    required this.id,
  });

  String oldName;

  String newName;

  num id;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TagsUpdateTagNameRequest &&
    other.oldName == oldName &&
    other.newName == newName &&
    other.id == id;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (oldName.hashCode) +
    (newName.hashCode) +
    (id.hashCode);

  @override
  String toString() => 'TagsUpdateTagNameRequest[oldName=$oldName, newName=$newName, id=$id]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'oldName'] = this.oldName;
      json[r'newName'] = this.newName;
      json[r'id'] = this.id;
    return json;
  }

  /// Returns a new [TagsUpdateTagNameRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TagsUpdateTagNameRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TagsUpdateTagNameRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TagsUpdateTagNameRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TagsUpdateTagNameRequest(
        oldName: mapValueOfType<String>(json, r'oldName')!,
        newName: mapValueOfType<String>(json, r'newName')!,
        id: num.parse('${json[r'id']}'),
      );
    }
    return null;
  }

  static List<TagsUpdateTagNameRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TagsUpdateTagNameRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TagsUpdateTagNameRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TagsUpdateTagNameRequest> mapFromJson(dynamic json) {
    final map = <String, TagsUpdateTagNameRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TagsUpdateTagNameRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TagsUpdateTagNameRequest-objects as value to a dart map
  static Map<String, List<TagsUpdateTagNameRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TagsUpdateTagNameRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TagsUpdateTagNameRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'oldName',
    'newName',
    'id',
  };
}


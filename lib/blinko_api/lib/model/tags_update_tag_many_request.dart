//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TagsUpdateTagManyRequest {
  /// Returns a new [TagsUpdateTagManyRequest] instance.
  TagsUpdateTagManyRequest({
    this.ids = const [],
    required this.tag,
  });

  List<num> ids;

  String tag;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TagsUpdateTagManyRequest &&
    _deepEquality.equals(other.ids, ids) &&
    other.tag == tag;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (ids.hashCode) +
    (tag.hashCode);

  @override
  String toString() => 'TagsUpdateTagManyRequest[ids=$ids, tag=$tag]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'ids'] = this.ids;
      json[r'tag'] = this.tag;
    return json;
  }

  /// Returns a new [TagsUpdateTagManyRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TagsUpdateTagManyRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TagsUpdateTagManyRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TagsUpdateTagManyRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TagsUpdateTagManyRequest(
        ids: json[r'ids'] is Iterable
            ? (json[r'ids'] as Iterable).cast<num>().toList(growable: false)
            : const [],
        tag: mapValueOfType<String>(json, r'tag')!,
      );
    }
    return null;
  }

  static List<TagsUpdateTagManyRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TagsUpdateTagManyRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TagsUpdateTagManyRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TagsUpdateTagManyRequest> mapFromJson(dynamic json) {
    final map = <String, TagsUpdateTagManyRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TagsUpdateTagManyRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TagsUpdateTagManyRequest-objects as value to a dart map
  static Map<String, List<TagsUpdateTagManyRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TagsUpdateTagManyRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TagsUpdateTagManyRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ids',
    'tag',
  };
}


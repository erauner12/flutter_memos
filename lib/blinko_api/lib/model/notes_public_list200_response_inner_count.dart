//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesPublicList200ResponseInnerCount {
  /// Returns a new [NotesPublicList200ResponseInnerCount] instance.
  NotesPublicList200ResponseInnerCount({
    required this.comments,
  });

  num comments;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesPublicList200ResponseInnerCount &&
    other.comments == comments;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (comments.hashCode);

  @override
  String toString() => 'NotesPublicList200ResponseInnerCount[comments=$comments]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'comments'] = this.comments;
    return json;
  }

  /// Returns a new [NotesPublicList200ResponseInnerCount] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesPublicList200ResponseInnerCount? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesPublicList200ResponseInnerCount[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesPublicList200ResponseInnerCount[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesPublicList200ResponseInnerCount(
        comments: num.parse('${json[r'comments']}'),
      );
    }
    return null;
  }

  static List<NotesPublicList200ResponseInnerCount> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesPublicList200ResponseInnerCount>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesPublicList200ResponseInnerCount.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesPublicList200ResponseInnerCount> mapFromJson(dynamic json) {
    final map = <String, NotesPublicList200ResponseInnerCount>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesPublicList200ResponseInnerCount.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesPublicList200ResponseInnerCount-objects as value to a dart map
  static Map<String, List<NotesPublicList200ResponseInnerCount>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesPublicList200ResponseInnerCount>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesPublicList200ResponseInnerCount.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'comments',
  };
}


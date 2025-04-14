//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesListByIdsRequest {
  /// Returns a new [NotesListByIdsRequest] instance.
  NotesListByIdsRequest({
    this.ids = const [],
  });

  List<num> ids;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesListByIdsRequest &&
    _deepEquality.equals(other.ids, ids);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (ids.hashCode);

  @override
  String toString() => 'NotesListByIdsRequest[ids=$ids]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'ids'] = this.ids;
    return json;
  }

  /// Returns a new [NotesListByIdsRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesListByIdsRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesListByIdsRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesListByIdsRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesListByIdsRequest(
        ids: json[r'ids'] is Iterable
            ? (json[r'ids'] as Iterable).cast<num>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<NotesListByIdsRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesListByIdsRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesListByIdsRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesListByIdsRequest> mapFromJson(dynamic json) {
    final map = <String, NotesListByIdsRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesListByIdsRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesListByIdsRequest-objects as value to a dart map
  static Map<String, List<NotesListByIdsRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesListByIdsRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesListByIdsRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ids',
  };
}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesAddReferenceRequest {
  /// Returns a new [NotesAddReferenceRequest] instance.
  NotesAddReferenceRequest({
    required this.fromNoteId,
    required this.toNoteId,
  });

  num fromNoteId;

  num toNoteId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesAddReferenceRequest &&
    other.fromNoteId == fromNoteId &&
    other.toNoteId == toNoteId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (fromNoteId.hashCode) +
    (toNoteId.hashCode);

  @override
  String toString() => 'NotesAddReferenceRequest[fromNoteId=$fromNoteId, toNoteId=$toNoteId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'fromNoteId'] = this.fromNoteId;
      json[r'toNoteId'] = this.toNoteId;
    return json;
  }

  /// Returns a new [NotesAddReferenceRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesAddReferenceRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesAddReferenceRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesAddReferenceRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesAddReferenceRequest(
        fromNoteId: num.parse('${json[r'fromNoteId']}'),
        toNoteId: num.parse('${json[r'toNoteId']}'),
      );
    }
    return null;
  }

  static List<NotesAddReferenceRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesAddReferenceRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesAddReferenceRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesAddReferenceRequest> mapFromJson(dynamic json) {
    final map = <String, NotesAddReferenceRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesAddReferenceRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesAddReferenceRequest-objects as value to a dart map
  static Map<String, List<NotesAddReferenceRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesAddReferenceRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesAddReferenceRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'fromNoteId',
    'toNoteId',
  };
}


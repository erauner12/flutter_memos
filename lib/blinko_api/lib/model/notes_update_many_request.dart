//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesUpdateManyRequest {
  /// Returns a new [NotesUpdateManyRequest] instance.
  NotesUpdateManyRequest({
    this.type,
    this.isArchived,
    this.isRecycle,
    this.ids = const [],
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  NotesListRequestType? type;

  bool? isArchived;

  bool? isRecycle;

  List<num> ids;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesUpdateManyRequest &&
    other.type == type &&
    other.isArchived == isArchived &&
    other.isRecycle == isRecycle &&
    _deepEquality.equals(other.ids, ids);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type == null ? 0 : type!.hashCode) +
    (isArchived == null ? 0 : isArchived!.hashCode) +
    (isRecycle == null ? 0 : isRecycle!.hashCode) +
    (ids.hashCode);

  @override
  String toString() => 'NotesUpdateManyRequest[type=$type, isArchived=$isArchived, isRecycle=$isRecycle, ids=$ids]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.isArchived != null) {
      json[r'isArchived'] = this.isArchived;
    } else {
      json[r'isArchived'] = null;
    }
    if (this.isRecycle != null) {
      json[r'isRecycle'] = this.isRecycle;
    } else {
      json[r'isRecycle'] = null;
    }
      json[r'ids'] = this.ids;
    return json;
  }

  /// Returns a new [NotesUpdateManyRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesUpdateManyRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesUpdateManyRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesUpdateManyRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesUpdateManyRequest(
        type: NotesListRequestType.fromJson(json[r'type']),
        isArchived: mapValueOfType<bool>(json, r'isArchived'),
        isRecycle: mapValueOfType<bool>(json, r'isRecycle'),
        ids: json[r'ids'] is Iterable
            ? (json[r'ids'] as Iterable).cast<num>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<NotesUpdateManyRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesUpdateManyRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesUpdateManyRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesUpdateManyRequest> mapFromJson(dynamic json) {
    final map = <String, NotesUpdateManyRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesUpdateManyRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesUpdateManyRequest-objects as value to a dart map
  static Map<String, List<NotesUpdateManyRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesUpdateManyRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesUpdateManyRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ids',
  };
}


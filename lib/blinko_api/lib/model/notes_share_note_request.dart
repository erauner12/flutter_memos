//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesShareNoteRequest {
  /// Returns a new [NotesShareNoteRequest] instance.
  NotesShareNoteRequest({
    required this.id,
    this.isCancel = false,
    this.password,
    this.expireAt,
  });

  num id;

  bool isCancel;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? password;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? expireAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesShareNoteRequest &&
    other.id == id &&
    other.isCancel == isCancel &&
    other.password == password &&
    other.expireAt == expireAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (isCancel.hashCode) +
    (password == null ? 0 : password!.hashCode) +
    (expireAt == null ? 0 : expireAt!.hashCode);

  @override
  String toString() => 'NotesShareNoteRequest[id=$id, isCancel=$isCancel, password=$password, expireAt=$expireAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'isCancel'] = this.isCancel;
    if (this.password != null) {
      json[r'password'] = this.password;
    } else {
      json[r'password'] = null;
    }
    if (this.expireAt != null) {
      json[r'expireAt'] = this.expireAt;
    } else {
      json[r'expireAt'] = null;
    }
    return json;
  }

  /// Returns a new [NotesShareNoteRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesShareNoteRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesShareNoteRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesShareNoteRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesShareNoteRequest(
        id: num.parse('${json[r'id']}'),
        isCancel: mapValueOfType<bool>(json, r'isCancel') ?? false,
        password: mapValueOfType<String>(json, r'password'),
        expireAt: mapValueOfType<String>(json, r'expireAt'),
      );
    }
    return null;
  }

  static List<NotesShareNoteRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesShareNoteRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesShareNoteRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesShareNoteRequest> mapFromJson(dynamic json) {
    final map = <String, NotesShareNoteRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesShareNoteRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesShareNoteRequest-objects as value to a dart map
  static Map<String, List<NotesShareNoteRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesShareNoteRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesShareNoteRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
  };
}


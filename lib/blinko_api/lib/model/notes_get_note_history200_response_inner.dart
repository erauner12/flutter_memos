//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesGetNoteHistory200ResponseInner {
  /// Returns a new [NotesGetNoteHistory200ResponseInner] instance.
  NotesGetNoteHistory200ResponseInner({
    required this.id,
    required this.content,
    required this.noteId,
    required this.createdAt,
    this.version,
    required this.accountId,
  });

  int id;

  String content;

  int noteId;

  String createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? version;

  int? accountId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesGetNoteHistory200ResponseInner &&
    other.id == id &&
    other.content == content &&
    other.noteId == noteId &&
    other.createdAt == createdAt &&
    other.version == version &&
    other.accountId == accountId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (content.hashCode) +
    (noteId.hashCode) +
    (createdAt.hashCode) +
    (version == null ? 0 : version!.hashCode) +
    (accountId == null ? 0 : accountId!.hashCode);

  @override
  String toString() => 'NotesGetNoteHistory200ResponseInner[id=$id, content=$content, noteId=$noteId, createdAt=$createdAt, version=$version, accountId=$accountId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'content'] = this.content;
      json[r'noteId'] = this.noteId;
      json[r'createdAt'] = this.createdAt;
    if (this.version != null) {
      json[r'version'] = this.version;
    } else {
      json[r'version'] = null;
    }
    if (this.accountId != null) {
      json[r'accountId'] = this.accountId;
    } else {
      json[r'accountId'] = null;
    }
    return json;
  }

  /// Returns a new [NotesGetNoteHistory200ResponseInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesGetNoteHistory200ResponseInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesGetNoteHistory200ResponseInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesGetNoteHistory200ResponseInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesGetNoteHistory200ResponseInner(
        id: mapValueOfType<int>(json, r'id')!,
        content: mapValueOfType<String>(json, r'content')!,
        noteId: mapValueOfType<int>(json, r'noteId')!,
        createdAt: mapValueOfType<String>(json, r'createdAt')!,
        version: mapValueOfType<int>(json, r'version'),
        accountId: mapValueOfType<int>(json, r'accountId'),
      );
    }
    return null;
  }

  static List<NotesGetNoteHistory200ResponseInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesGetNoteHistory200ResponseInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesGetNoteHistory200ResponseInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesGetNoteHistory200ResponseInner> mapFromJson(dynamic json) {
    final map = <String, NotesGetNoteHistory200ResponseInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesGetNoteHistory200ResponseInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesGetNoteHistory200ResponseInner-objects as value to a dart map
  static Map<String, List<NotesGetNoteHistory200ResponseInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesGetNoteHistory200ResponseInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesGetNoteHistory200ResponseInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'content',
    'noteId',
    'createdAt',
    'accountId',
  };
}


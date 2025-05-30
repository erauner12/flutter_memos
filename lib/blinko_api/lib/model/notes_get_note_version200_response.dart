//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesGetNoteVersion200Response {
  /// Returns a new [NotesGetNoteVersion200Response] instance.
  NotesGetNoteVersion200Response({
    required this.content,
    this.metadata,
    required this.version,
    required this.createdAt,
  });

  String content;

  Object? metadata;

  num version;

  String createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesGetNoteVersion200Response &&
    other.content == content &&
    other.metadata == metadata &&
    other.version == version &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (content.hashCode) +
    (metadata == null ? 0 : metadata!.hashCode) +
    (version.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'NotesGetNoteVersion200Response[content=$content, metadata=$metadata, version=$version, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'content'] = this.content;
    if (this.metadata != null) {
      json[r'metadata'] = this.metadata;
    } else {
      json[r'metadata'] = null;
    }
      json[r'version'] = this.version;
      json[r'createdAt'] = this.createdAt;
    return json;
  }

  /// Returns a new [NotesGetNoteVersion200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesGetNoteVersion200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesGetNoteVersion200Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesGetNoteVersion200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesGetNoteVersion200Response(
        content: mapValueOfType<String>(json, r'content')!,
        metadata: mapValueOfType<Object>(json, r'metadata'),
        version: num.parse('${json[r'version']}'),
        createdAt: mapValueOfType<String>(json, r'createdAt')!,
      );
    }
    return null;
  }

  static List<NotesGetNoteVersion200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesGetNoteVersion200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesGetNoteVersion200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesGetNoteVersion200Response> mapFromJson(dynamic json) {
    final map = <String, NotesGetNoteVersion200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesGetNoteVersion200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesGetNoteVersion200Response-objects as value to a dart map
  static Map<String, List<NotesGetNoteVersion200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesGetNoteVersion200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesGetNoteVersion200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'content',
    'version',
    'createdAt',
  };
}


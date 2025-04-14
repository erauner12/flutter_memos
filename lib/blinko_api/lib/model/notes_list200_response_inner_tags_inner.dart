//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesList200ResponseInnerTagsInner {
  /// Returns a new [NotesList200ResponseInnerTagsInner] instance.
  NotesList200ResponseInnerTagsInner({
    required this.id,
    required this.noteId,
    required this.tagId,
    required this.tag,
  });

  int id;

  int noteId;

  int tagId;

  NotesList200ResponseInnerTagsInnerTag tag;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesList200ResponseInnerTagsInner &&
    other.id == id &&
    other.noteId == noteId &&
    other.tagId == tagId &&
    other.tag == tag;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (noteId.hashCode) +
    (tagId.hashCode) +
    (tag.hashCode);

  @override
  String toString() => 'NotesList200ResponseInnerTagsInner[id=$id, noteId=$noteId, tagId=$tagId, tag=$tag]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'noteId'] = this.noteId;
      json[r'tagId'] = this.tagId;
      json[r'tag'] = this.tag;
    return json;
  }

  /// Returns a new [NotesList200ResponseInnerTagsInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesList200ResponseInnerTagsInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesList200ResponseInnerTagsInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesList200ResponseInnerTagsInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesList200ResponseInnerTagsInner(
        id: mapValueOfType<int>(json, r'id')!,
        noteId: mapValueOfType<int>(json, r'noteId')!,
        tagId: mapValueOfType<int>(json, r'tagId')!,
        tag: NotesList200ResponseInnerTagsInnerTag.fromJson(json[r'tag'])!,
      );
    }
    return null;
  }

  static List<NotesList200ResponseInnerTagsInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesList200ResponseInnerTagsInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesList200ResponseInnerTagsInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesList200ResponseInnerTagsInner> mapFromJson(dynamic json) {
    final map = <String, NotesList200ResponseInnerTagsInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesList200ResponseInnerTagsInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesList200ResponseInnerTagsInner-objects as value to a dart map
  static Map<String, List<NotesList200ResponseInnerTagsInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesList200ResponseInnerTagsInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesList200ResponseInnerTagsInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'noteId',
    'tagId',
    'tag',
  };
}


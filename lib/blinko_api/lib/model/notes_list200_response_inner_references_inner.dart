//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesList200ResponseInnerReferencesInner {
  /// Returns a new [NotesList200ResponseInnerReferencesInner] instance.
  NotesList200ResponseInnerReferencesInner({
    required this.toNoteId,
    this.toNote,
  });

  num toNoteId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  NotesList200ResponseInnerReferencesInnerToNote? toNote;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesList200ResponseInnerReferencesInner &&
    other.toNoteId == toNoteId &&
    other.toNote == toNote;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (toNoteId.hashCode) +
    (toNote == null ? 0 : toNote!.hashCode);

  @override
  String toString() => 'NotesList200ResponseInnerReferencesInner[toNoteId=$toNoteId, toNote=$toNote]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'toNoteId'] = this.toNoteId;
    if (this.toNote != null) {
      json[r'toNote'] = this.toNote;
    } else {
      json[r'toNote'] = null;
    }
    return json;
  }

  /// Returns a new [NotesList200ResponseInnerReferencesInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesList200ResponseInnerReferencesInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesList200ResponseInnerReferencesInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesList200ResponseInnerReferencesInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesList200ResponseInnerReferencesInner(
        toNoteId: num.parse('${json[r'toNoteId']}'),
        toNote: NotesList200ResponseInnerReferencesInnerToNote.fromJson(json[r'toNote']),
      );
    }
    return null;
  }

  static List<NotesList200ResponseInnerReferencesInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesList200ResponseInnerReferencesInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesList200ResponseInnerReferencesInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesList200ResponseInnerReferencesInner> mapFromJson(dynamic json) {
    final map = <String, NotesList200ResponseInnerReferencesInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesList200ResponseInnerReferencesInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesList200ResponseInnerReferencesInner-objects as value to a dart map
  static Map<String, List<NotesList200ResponseInnerReferencesInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesList200ResponseInnerReferencesInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesList200ResponseInnerReferencesInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'toNoteId',
  };
}


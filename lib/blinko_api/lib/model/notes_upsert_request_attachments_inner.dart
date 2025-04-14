//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesUpsertRequestAttachmentsInner {
  /// Returns a new [NotesUpsertRequestAttachmentsInner] instance.
  NotesUpsertRequestAttachmentsInner({
    required this.name,
    required this.path,
    required this.size,
    required this.type,
  });

  String name;

  String path;

  NotesUpsertRequestAttachmentsInnerSize size;

  String type;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesUpsertRequestAttachmentsInner &&
    other.name == name &&
    other.path == path &&
    other.size == size &&
    other.type == type;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (path.hashCode) +
    (size.hashCode) +
    (type.hashCode);

  @override
  String toString() => 'NotesUpsertRequestAttachmentsInner[name=$name, path=$path, size=$size, type=$type]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'path'] = this.path;
      json[r'size'] = this.size;
      json[r'type'] = this.type;
    return json;
  }

  /// Returns a new [NotesUpsertRequestAttachmentsInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesUpsertRequestAttachmentsInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesUpsertRequestAttachmentsInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesUpsertRequestAttachmentsInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesUpsertRequestAttachmentsInner(
        name: mapValueOfType<String>(json, r'name')!,
        path: mapValueOfType<String>(json, r'path')!,
        size: NotesUpsertRequestAttachmentsInnerSize.fromJson(json[r'size'])!,
        type: mapValueOfType<String>(json, r'type')!,
      );
    }
    return null;
  }

  static List<NotesUpsertRequestAttachmentsInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesUpsertRequestAttachmentsInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesUpsertRequestAttachmentsInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesUpsertRequestAttachmentsInner> mapFromJson(dynamic json) {
    final map = <String, NotesUpsertRequestAttachmentsInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesUpsertRequestAttachmentsInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesUpsertRequestAttachmentsInner-objects as value to a dart map
  static Map<String, List<NotesUpsertRequestAttachmentsInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesUpsertRequestAttachmentsInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesUpsertRequestAttachmentsInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'path',
    'size',
    'type',
  };
}


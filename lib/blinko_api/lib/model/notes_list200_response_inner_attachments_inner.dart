//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesList200ResponseInnerAttachmentsInner {
  /// Returns a new [NotesList200ResponseInnerAttachmentsInner] instance.
  NotesList200ResponseInnerAttachmentsInner({
    required this.id,
    required this.isShare,
    required this.sharePassword,
    required this.name,
    required this.path,
    required this.size,
    required this.noteId,
    this.accountId, // Changed to optional
    required this.createdAt,
    required this.sortOrder,
    required this.updatedAt,
    required this.type,
    this.depth,
    this.perfixPath,
  });

  int id;

  bool isShare;

  String sharePassword;

  String name;

  String path;

  NotesList200ResponseInnerAttachmentsInnerSize? size;

  int? noteId;

  int? accountId; // Changed type to nullable int?

  String createdAt;

  int sortOrder;

  String updatedAt;

  String type;

  Object? depth;

  Object? perfixPath;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesList200ResponseInnerAttachmentsInner &&
    other.id == id &&
    other.isShare == isShare &&
    other.sharePassword == sharePassword &&
    other.name == name &&
    other.path == path &&
    other.size == size &&
    other.noteId == noteId &&
          other.accountId == accountId && // Compare nullable accountId
    other.createdAt == createdAt &&
    other.sortOrder == sortOrder &&
    other.updatedAt == updatedAt &&
    other.type == type &&
    other.depth == depth &&
    other.perfixPath == perfixPath;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (isShare.hashCode) +
    (sharePassword.hashCode) +
    (name.hashCode) +
    (path.hashCode) +
    (size == null ? 0 : size!.hashCode) +
    (noteId == null ? 0 : noteId!.hashCode) +
      (accountId == null ? 0 : accountId!.hashCode) + // Handle null accountId
    (createdAt.hashCode) +
    (sortOrder.hashCode) +
    (updatedAt.hashCode) +
    (type.hashCode) +
    (depth == null ? 0 : depth!.hashCode) +
    (perfixPath == null ? 0 : perfixPath!.hashCode);

  @override
  String toString() => 'NotesList200ResponseInnerAttachmentsInner[id=$id, isShare=$isShare, sharePassword=$sharePassword, name=$name, path=$path, size=$size, noteId=$noteId, accountId=$accountId, createdAt=$createdAt, sortOrder=$sortOrder, updatedAt=$updatedAt, type=$type, depth=$depth, perfixPath=$perfixPath]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'isShare'] = this.isShare;
      json[r'sharePassword'] = this.sharePassword;
      json[r'name'] = this.name;
      json[r'path'] = this.path;
    if (this.size != null) {
      json[r'size'] = this.size;
    } else {
      json[r'size'] = null;
    }
    if (this.noteId != null) {
      json[r'noteId'] = this.noteId;
    } else {
      json[r'noteId'] = null;
    }
    if (this.accountId != null) {
      json[r'accountId'] = this.accountId; // Serialize nullable accountId
    } else {
      json[r'accountId'] = null;
    }
      json[r'createdAt'] = this.createdAt;
      json[r'sortOrder'] = this.sortOrder;
      json[r'updatedAt'] = this.updatedAt;
      json[r'type'] = this.type;
    if (this.depth != null) {
      json[r'depth'] = this.depth;
    } else {
      json[r'depth'] = null;
    }
    if (this.perfixPath != null) {
      json[r'perfixPath'] = this.perfixPath;
    } else {
      json[r'perfixPath'] = null;
    }
    return json;
  }

  /// Returns a new [NotesList200ResponseInnerAttachmentsInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesList200ResponseInnerAttachmentsInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesList200ResponseInnerAttachmentsInner[$key]" is missing from JSON.');
          // Allow null for keys not in requiredKeys anymore (like accountId)
          if (requiredKeys.contains(key)) {
            assert(json[key] != null,
                'Required key "NotesList200ResponseInnerAttachmentsInner[$key]" has a null value in JSON.');
          }
        });
        return true;
      }());

      return NotesList200ResponseInnerAttachmentsInner(
        id: mapValueOfType<int>(json, r'id')!,
        isShare: mapValueOfType<bool>(json, r'isShare')!,
        sharePassword: mapValueOfType<String>(json, r'sharePassword')!,
        name: mapValueOfType<String>(json, r'name')!,
        path: mapValueOfType<String>(json, r'path')!,
        size: NotesList200ResponseInnerAttachmentsInnerSize.fromJson(json[r'size']),
        noteId: mapValueOfType<int>(json, r'noteId'),
        accountId:
            mapValueOfType<int>(json, r'accountId'), // Parse nullable accountId
        createdAt: mapValueOfType<String>(json, r'createdAt')!,
        sortOrder: mapValueOfType<int>(json, r'sortOrder')!,
        updatedAt: mapValueOfType<String>(json, r'updatedAt')!,
        type: mapValueOfType<String>(json, r'type')!,
        depth: mapValueOfType<Object>(json, r'depth'),
        perfixPath: mapValueOfType<Object>(json, r'perfixPath'),
      );
    }
    return null;
  }

  static List<NotesList200ResponseInnerAttachmentsInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesList200ResponseInnerAttachmentsInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesList200ResponseInnerAttachmentsInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesList200ResponseInnerAttachmentsInner> mapFromJson(dynamic json) {
    final map = <String, NotesList200ResponseInnerAttachmentsInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesList200ResponseInnerAttachmentsInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesList200ResponseInnerAttachmentsInner-objects as value to a dart map
  static Map<String, List<NotesList200ResponseInnerAttachmentsInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesList200ResponseInnerAttachmentsInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesList200ResponseInnerAttachmentsInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'isShare',
    'sharePassword',
    'name',
    'path',
    'size',
    'noteId',
    // 'accountId', // Removed accountId from required keys
    'createdAt',
    'sortOrder',
    'updatedAt',
    'type',
  };
}

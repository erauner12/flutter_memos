//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesUpsertRequest {
  /// Returns a new [NotesUpsertRequest] instance.
  NotesUpsertRequest({
    this.content,
    this.type,
    this.attachments = const [],
    this.id,
    this.isArchived,
    this.isTop,
    this.isShare,
    this.isRecycle,
    this.references = const [],
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  String? content;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  NotesListRequestType? type;

  List<NotesUpsertRequestAttachmentsInner> attachments;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? id;

  bool? isArchived;

  bool? isTop;

  bool? isShare;

  bool? isRecycle;

  List<num> references;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? updatedAt;

  Object? metadata;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesUpsertRequest &&
    other.content == content &&
    other.type == type &&
    _deepEquality.equals(other.attachments, attachments) &&
    other.id == id &&
    other.isArchived == isArchived &&
    other.isTop == isTop &&
    other.isShare == isShare &&
    other.isRecycle == isRecycle &&
    _deepEquality.equals(other.references, references) &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt &&
    other.metadata == metadata;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (content == null ? 0 : content!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (attachments.hashCode) +
    (id == null ? 0 : id!.hashCode) +
    (isArchived == null ? 0 : isArchived!.hashCode) +
    (isTop == null ? 0 : isTop!.hashCode) +
    (isShare == null ? 0 : isShare!.hashCode) +
    (isRecycle == null ? 0 : isRecycle!.hashCode) +
    (references.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode) +
    (updatedAt == null ? 0 : updatedAt!.hashCode) +
    (metadata == null ? 0 : metadata!.hashCode);

  @override
  String toString() => 'NotesUpsertRequest[content=$content, type=$type, attachments=$attachments, id=$id, isArchived=$isArchived, isTop=$isTop, isShare=$isShare, isRecycle=$isRecycle, references=$references, createdAt=$createdAt, updatedAt=$updatedAt, metadata=$metadata]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.content != null) {
      json[r'content'] = this.content;
    } else {
      json[r'content'] = null;
    }
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
      json[r'attachments'] = this.attachments;
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.isArchived != null) {
      json[r'isArchived'] = this.isArchived;
    } else {
      json[r'isArchived'] = null;
    }
    if (this.isTop != null) {
      json[r'isTop'] = this.isTop;
    } else {
      json[r'isTop'] = null;
    }
    if (this.isShare != null) {
      json[r'isShare'] = this.isShare;
    } else {
      json[r'isShare'] = null;
    }
    if (this.isRecycle != null) {
      json[r'isRecycle'] = this.isRecycle;
    } else {
      json[r'isRecycle'] = null;
    }
      json[r'references'] = this.references;
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt;
    } else {
      json[r'createdAt'] = null;
    }
    if (this.updatedAt != null) {
      json[r'updatedAt'] = this.updatedAt;
    } else {
      json[r'updatedAt'] = null;
    }
    if (this.metadata != null) {
      json[r'metadata'] = this.metadata;
    } else {
      json[r'metadata'] = null;
    }
    return json;
  }

  /// Returns a new [NotesUpsertRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesUpsertRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesUpsertRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesUpsertRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesUpsertRequest(
        content: mapValueOfType<String>(json, r'content'),
        type: NotesListRequestType.fromJson(json[r'type']),
        attachments: NotesUpsertRequestAttachmentsInner.listFromJson(json[r'attachments']),
        id: num.parse('${json[r'id']}'),
        isArchived: mapValueOfType<bool>(json, r'isArchived'),
        isTop: mapValueOfType<bool>(json, r'isTop'),
        isShare: mapValueOfType<bool>(json, r'isShare'),
        isRecycle: mapValueOfType<bool>(json, r'isRecycle'),
        references: json[r'references'] is Iterable
            ? (json[r'references'] as Iterable).cast<num>().toList(growable: false)
            : const [],
        createdAt: mapValueOfType<String>(json, r'createdAt'),
        updatedAt: mapValueOfType<String>(json, r'updatedAt'),
        metadata: mapValueOfType<Object>(json, r'metadata'),
      );
    }
    return null;
  }

  static List<NotesUpsertRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesUpsertRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesUpsertRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesUpsertRequest> mapFromJson(dynamic json) {
    final map = <String, NotesUpsertRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesUpsertRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesUpsertRequest-objects as value to a dart map
  static Map<String, List<NotesUpsertRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesUpsertRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesUpsertRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


//
// AUTO-GENERATED FILE, DO NOT MODIFY! (Manually extended for 'typeVal')
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

    /// Manually added field to store the integer 'type' for the request.
    this.typeVal,
  });

  String? content;

  ///
  /// Please note: This property is auto-generated but doesn't map to an int in the generated code.
  /// We keep it for backward compatibility, though it is typically not used.
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

  /// Manually added field to store the integer 'type' (0 for cache, 1 for vault, etc.)
  int? typeVal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotesUpsertRequest &&
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
          other.metadata == metadata &&
          other.typeVal == typeVal;

  @override
  int get hashCode {
    final listEquality = const DeepCollectionEquality();
    return (content == null ? 0 : content!.hashCode) +
        (type == null ? 0 : type!.hashCode) +
        (listEquality.hash(attachments)) +
        (id == null ? 0 : id!.hashCode) +
        (isArchived == null ? 0 : isArchived!.hashCode) +
        (isTop == null ? 0 : isTop!.hashCode) +
        (isShare == null ? 0 : isShare!.hashCode) +
        (isRecycle == null ? 0 : isRecycle!.hashCode) +
        (listEquality.hash(references)) +
        (createdAt == null ? 0 : createdAt!.hashCode) +
        (updatedAt == null ? 0 : updatedAt!.hashCode) +
        (metadata == null ? 0 : metadata!.hashCode) +
        (typeVal == null ? 0 : typeVal!.hashCode);
  }

  @override
  String toString() =>
      'NotesUpsertRequest[content=$content, type=$type, attachments=$attachments, id=$id, '
      'isArchived=$isArchived, isTop=$isTop, isShare=$isShare, isRecycle=$isRecycle, '
      'references=$references, createdAt=$createdAt, updatedAt=$updatedAt, metadata=$metadata, '
      'typeVal=$typeVal]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (this.content != null) {
      json[r'content'] = this.content;
    }
    if (this.type != null) {
      json[r'typeObj'] =
          this.type; // keep the original "type" object in a different field
    }
    json[r'attachments'] = this.attachments;
    if (this.id != null) {
      json[r'id'] = this.id;
    }
    if (this.isArchived != null) {
      json[r'isArchived'] = this.isArchived;
    }
    if (this.isTop != null) {
      json[r'isTop'] = this.isTop;
    }
    if (this.isShare != null) {
      json[r'isShare'] = this.isShare;
    }
    if (this.isRecycle != null) {
      json[r'isRecycle'] = this.isRecycle;
    }
    json[r'references'] = this.references;
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt;
    }
    if (this.updatedAt != null) {
      json[r'updatedAt'] = this.updatedAt;
    }
    if (this.metadata != null) {
      json[r'metadata'] = this.metadata;
    }

    // Our manually added field: if it exists, place it under "type" in JSON
    if (this.typeVal != null) {
      json[r'type'] = this.typeVal;
    }

    return json;
  }

  /// Returns a new [NotesUpsertRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  static NotesUpsertRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      return NotesUpsertRequest(
        content: mapValueOfType<String>(json, r'content'),
        type: NotesListRequestType.fromJson(json[r'typeObj']),
        attachments: NotesUpsertRequestAttachmentsInner.listFromJson(json[r'attachments']),
        id: json[r'id'] == null ? null : num.parse('${json[r'id']}'),
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
        typeVal: mapValueOfType<int>(json, r'type'),
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
      json = json.cast<String, dynamic>();
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
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesUpsertRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  static const requiredKeys = <String>{};

  static final _deepEquality = const DeepCollectionEquality();
}

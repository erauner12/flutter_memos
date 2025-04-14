//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesDetail200Response {
  /// Returns a new [NotesDetail200Response] instance.
  NotesDetail200Response({
    required this.id,
    required this.type,
    required this.content,
    required this.isArchived,
    required this.isRecycle,
    required this.isShare,
    required this.isTop,
    required this.isReviewed,
    required this.sharePassword,
    this.shareEncryptedUrl,
    this.shareExpiryDate,
    this.shareMaxView,
    this.shareViewCount,
    this.metadata,
    required this.accountId,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
    this.tags = const [],
    this.references = const [],
    this.referencedBy = const [],
    required this.count,
  });

  int id;

  int type;

  String content;

  bool isArchived;

  bool isRecycle;

  bool isShare;

  bool isTop;

  bool isReviewed;

  String sharePassword;

  String? shareEncryptedUrl;

  String? shareExpiryDate;

  num? shareMaxView;

  num? shareViewCount;

  Object? metadata;

  int? accountId;

  String createdAt;

  String updatedAt;

  List<NotesList200ResponseInnerAttachmentsInner> attachments;

  List<NotesList200ResponseInnerTagsInner> tags;

  List<NotesList200ResponseInnerReferencesInner> references;

  List<NotesList200ResponseInnerReferencedByInner> referencedBy;

  NotesList200ResponseInnerCount count;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesDetail200Response &&
    other.id == id &&
    other.type == type &&
    other.content == content &&
    other.isArchived == isArchived &&
    other.isRecycle == isRecycle &&
    other.isShare == isShare &&
    other.isTop == isTop &&
    other.isReviewed == isReviewed &&
    other.sharePassword == sharePassword &&
    other.shareEncryptedUrl == shareEncryptedUrl &&
    other.shareExpiryDate == shareExpiryDate &&
    other.shareMaxView == shareMaxView &&
    other.shareViewCount == shareViewCount &&
    other.metadata == metadata &&
    other.accountId == accountId &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt &&
    _deepEquality.equals(other.attachments, attachments) &&
    _deepEquality.equals(other.tags, tags) &&
    _deepEquality.equals(other.references, references) &&
    _deepEquality.equals(other.referencedBy, referencedBy) &&
    other.count == count;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (type.hashCode) +
    (content.hashCode) +
    (isArchived.hashCode) +
    (isRecycle.hashCode) +
    (isShare.hashCode) +
    (isTop.hashCode) +
    (isReviewed.hashCode) +
    (sharePassword.hashCode) +
    (shareEncryptedUrl == null ? 0 : shareEncryptedUrl!.hashCode) +
    (shareExpiryDate == null ? 0 : shareExpiryDate!.hashCode) +
    (shareMaxView == null ? 0 : shareMaxView!.hashCode) +
    (shareViewCount == null ? 0 : shareViewCount!.hashCode) +
    (metadata == null ? 0 : metadata!.hashCode) +
    (accountId == null ? 0 : accountId!.hashCode) +
    (createdAt.hashCode) +
    (updatedAt.hashCode) +
    (attachments.hashCode) +
    (tags.hashCode) +
    (references.hashCode) +
    (referencedBy.hashCode) +
    (count.hashCode);

  @override
  String toString() => 'NotesDetail200Response[id=$id, type=$type, content=$content, isArchived=$isArchived, isRecycle=$isRecycle, isShare=$isShare, isTop=$isTop, isReviewed=$isReviewed, sharePassword=$sharePassword, shareEncryptedUrl=$shareEncryptedUrl, shareExpiryDate=$shareExpiryDate, shareMaxView=$shareMaxView, shareViewCount=$shareViewCount, metadata=$metadata, accountId=$accountId, createdAt=$createdAt, updatedAt=$updatedAt, attachments=$attachments, tags=$tags, references=$references, referencedBy=$referencedBy, count=$count]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'type'] = this.type;
      json[r'content'] = this.content;
      json[r'isArchived'] = this.isArchived;
      json[r'isRecycle'] = this.isRecycle;
      json[r'isShare'] = this.isShare;
      json[r'isTop'] = this.isTop;
      json[r'isReviewed'] = this.isReviewed;
      json[r'sharePassword'] = this.sharePassword;
    if (this.shareEncryptedUrl != null) {
      json[r'shareEncryptedUrl'] = this.shareEncryptedUrl;
    } else {
      json[r'shareEncryptedUrl'] = null;
    }
    if (this.shareExpiryDate != null) {
      json[r'shareExpiryDate'] = this.shareExpiryDate;
    } else {
      json[r'shareExpiryDate'] = null;
    }
    if (this.shareMaxView != null) {
      json[r'shareMaxView'] = this.shareMaxView;
    } else {
      json[r'shareMaxView'] = null;
    }
    if (this.shareViewCount != null) {
      json[r'shareViewCount'] = this.shareViewCount;
    } else {
      json[r'shareViewCount'] = null;
    }
    if (this.metadata != null) {
      json[r'metadata'] = this.metadata;
    } else {
      json[r'metadata'] = null;
    }
    if (this.accountId != null) {
      json[r'accountId'] = this.accountId;
    } else {
      json[r'accountId'] = null;
    }
      json[r'createdAt'] = this.createdAt;
      json[r'updatedAt'] = this.updatedAt;
      json[r'attachments'] = this.attachments;
      json[r'tags'] = this.tags;
      json[r'references'] = this.references;
      json[r'referencedBy'] = this.referencedBy;
      json[r'_count'] = this.count;
    return json;
  }

  /// Returns a new [NotesDetail200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesDetail200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesDetail200Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesDetail200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesDetail200Response(
        id: mapValueOfType<int>(json, r'id')!,
        type: mapValueOfType<int>(json, r'type')!,
        content: mapValueOfType<String>(json, r'content')!,
        isArchived: mapValueOfType<bool>(json, r'isArchived')!,
        isRecycle: mapValueOfType<bool>(json, r'isRecycle')!,
        isShare: mapValueOfType<bool>(json, r'isShare')!,
        isTop: mapValueOfType<bool>(json, r'isTop')!,
        isReviewed: mapValueOfType<bool>(json, r'isReviewed')!,
        sharePassword: mapValueOfType<String>(json, r'sharePassword')!,
        shareEncryptedUrl: mapValueOfType<String>(json, r'shareEncryptedUrl'),
        shareExpiryDate: mapValueOfType<String>(json, r'shareExpiryDate'),
        shareMaxView: json[r'shareMaxView'] == null
            ? null
            : num.parse('${json[r'shareMaxView']}'),
        shareViewCount: json[r'shareViewCount'] == null
            ? null
            : num.parse('${json[r'shareViewCount']}'),
        metadata: mapValueOfType<Object>(json, r'metadata'),
        accountId: mapValueOfType<int>(json, r'accountId'),
        createdAt: mapValueOfType<String>(json, r'createdAt')!,
        updatedAt: mapValueOfType<String>(json, r'updatedAt')!,
        attachments: NotesList200ResponseInnerAttachmentsInner.listFromJson(json[r'attachments']),
        tags: NotesList200ResponseInnerTagsInner.listFromJson(json[r'tags']),
        references: NotesList200ResponseInnerReferencesInner.listFromJson(json[r'references']),
        referencedBy: NotesList200ResponseInnerReferencedByInner.listFromJson(json[r'referencedBy']),
        count: NotesList200ResponseInnerCount.fromJson(json[r'_count'])!,
      );
    }
    return null;
  }

  static List<NotesDetail200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesDetail200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesDetail200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesDetail200Response> mapFromJson(dynamic json) {
    final map = <String, NotesDetail200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesDetail200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesDetail200Response-objects as value to a dart map
  static Map<String, List<NotesDetail200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesDetail200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesDetail200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'type',
    'content',
    'isArchived',
    'isRecycle',
    'isShare',
    'isTop',
    'isReviewed',
    'sharePassword',
    'accountId',
    'createdAt',
    'updatedAt',
    'attachments',
    'tags',
    '_count',
  };
}


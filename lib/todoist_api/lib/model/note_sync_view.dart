//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NoteSyncView {
  /// Returns a new [NoteSyncView] instance.
  NoteSyncView({
    required this.id,
    required this.postedUid,
    this.content = '',
    this.fileAttachment = const {},
    this.uidsToNotify = const [],
    required this.isDeleted,
    required this.postedAt,
    this.reactions = const {},
  });

  String id;

  String? postedUid;

  String content;

  Map<String, NoteSyncViewFileAttachmentValue>? fileAttachment;

  List<String>? uidsToNotify;

  bool isDeleted;

  String? postedAt;

  Map<String, List<String>>? reactions;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NoteSyncView &&
    other.id == id &&
    other.postedUid == postedUid &&
    other.content == content &&
    _deepEquality.equals(other.fileAttachment, fileAttachment) &&
    _deepEquality.equals(other.uidsToNotify, uidsToNotify) &&
    other.isDeleted == isDeleted &&
    other.postedAt == postedAt &&
    _deepEquality.equals(other.reactions, reactions);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (postedUid == null ? 0 : postedUid!.hashCode) +
    (content.hashCode) +
    (fileAttachment == null ? 0 : fileAttachment!.hashCode) +
    (uidsToNotify == null ? 0 : uidsToNotify!.hashCode) +
    (isDeleted.hashCode) +
    (postedAt == null ? 0 : postedAt!.hashCode) +
    (reactions == null ? 0 : reactions!.hashCode);

  @override
  String toString() => 'NoteSyncView[id=$id, postedUid=$postedUid, content=$content, fileAttachment=$fileAttachment, uidsToNotify=$uidsToNotify, isDeleted=$isDeleted, postedAt=$postedAt, reactions=$reactions]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
    if (this.postedUid != null) {
      json[r'posted_uid'] = this.postedUid;
    } else {
      json[r'posted_uid'] = null;
    }
      json[r'content'] = this.content;
    if (this.fileAttachment != null) {
      json[r'file_attachment'] = this.fileAttachment;
    } else {
      json[r'file_attachment'] = null;
    }
    if (this.uidsToNotify != null) {
      json[r'uids_to_notify'] = this.uidsToNotify;
    } else {
      json[r'uids_to_notify'] = null;
    }
      json[r'is_deleted'] = this.isDeleted;
    if (this.postedAt != null) {
      json[r'posted_at'] = this.postedAt;
    } else {
      json[r'posted_at'] = null;
    }
    if (this.reactions != null) {
      json[r'reactions'] = this.reactions;
    } else {
      json[r'reactions'] = null;
    }
    return json;
  }

  /// Returns a new [NoteSyncView] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NoteSyncView? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NoteSyncView[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NoteSyncView[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NoteSyncView(
        id: mapValueOfType<String>(json, r'id')!,
        postedUid: mapValueOfType<String>(json, r'posted_uid'),
        content: mapValueOfType<String>(json, r'content') ?? '',
        fileAttachment: NoteSyncViewFileAttachmentValue.mapFromJson(json[r'file_attachment']),
        uidsToNotify: json[r'uids_to_notify'] is Iterable
            ? (json[r'uids_to_notify'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        isDeleted: mapValueOfType<bool>(json, r'is_deleted')!,
        postedAt: mapValueOfType<String>(json, r'posted_at'),
        reactions: json[r'reactions'] == null
          ? const {}
            : mapCastOfType<String, List>(json, r'reactions'),
      );
    }
    return null;
  }

  static List<NoteSyncView> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NoteSyncView>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NoteSyncView.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NoteSyncView> mapFromJson(dynamic json) {
    final map = <String, NoteSyncView>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NoteSyncView.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NoteSyncView-objects as value to a dart map
  static Map<String, List<NoteSyncView>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NoteSyncView>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NoteSyncView.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'posted_uid',
    'file_attachment',
    'uids_to_notify',
    'is_deleted',
    'posted_at',
    'reactions',
  };
}


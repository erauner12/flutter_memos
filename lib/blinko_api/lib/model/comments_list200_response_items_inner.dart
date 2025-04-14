//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CommentsList200ResponseItemsInner {
  /// Returns a new [CommentsList200ResponseItemsInner] instance.
  CommentsList200ResponseItemsInner({
    required this.id,
    required this.content,
    required this.accountId,
    required this.guestName,
    required this.guestIP,
    required this.guestUA,
    required this.noteId,
    required this.parentId,
    required this.createdAt,
    required this.updatedAt,
    required this.account,
    required this.note,
    this.replies = const [],
  });

  int id;

  String content;

  int? accountId;

  String? guestName;

  String? guestIP;

  String? guestUA;

  int noteId;

  int? parentId;

  String createdAt;

  String updatedAt;

  CommentsList200ResponseItemsInnerAccount? account;

  CommentsList200ResponseItemsInnerNote? note;

  List<CommentsList200ResponseItemsInnerRepliesInner> replies;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CommentsList200ResponseItemsInner &&
    other.id == id &&
    other.content == content &&
    other.accountId == accountId &&
    other.guestName == guestName &&
    other.guestIP == guestIP &&
    other.guestUA == guestUA &&
    other.noteId == noteId &&
    other.parentId == parentId &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt &&
    other.account == account &&
    other.note == note &&
    _deepEquality.equals(other.replies, replies);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (content.hashCode) +
    (accountId == null ? 0 : accountId!.hashCode) +
    (guestName == null ? 0 : guestName!.hashCode) +
    (guestIP == null ? 0 : guestIP!.hashCode) +
    (guestUA == null ? 0 : guestUA!.hashCode) +
    (noteId.hashCode) +
    (parentId == null ? 0 : parentId!.hashCode) +
    (createdAt.hashCode) +
    (updatedAt.hashCode) +
    (account == null ? 0 : account!.hashCode) +
    (note == null ? 0 : note!.hashCode) +
    (replies.hashCode);

  @override
  String toString() => 'CommentsList200ResponseItemsInner[id=$id, content=$content, accountId=$accountId, guestName=$guestName, guestIP=$guestIP, guestUA=$guestUA, noteId=$noteId, parentId=$parentId, createdAt=$createdAt, updatedAt=$updatedAt, account=$account, note=$note, replies=$replies]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'content'] = this.content;
    if (this.accountId != null) {
      json[r'accountId'] = this.accountId;
    } else {
      json[r'accountId'] = null;
    }
    if (this.guestName != null) {
      json[r'guestName'] = this.guestName;
    } else {
      json[r'guestName'] = null;
    }
    if (this.guestIP != null) {
      json[r'guestIP'] = this.guestIP;
    } else {
      json[r'guestIP'] = null;
    }
    if (this.guestUA != null) {
      json[r'guestUA'] = this.guestUA;
    } else {
      json[r'guestUA'] = null;
    }
      json[r'noteId'] = this.noteId;
    if (this.parentId != null) {
      json[r'parentId'] = this.parentId;
    } else {
      json[r'parentId'] = null;
    }
      json[r'createdAt'] = this.createdAt;
      json[r'updatedAt'] = this.updatedAt;
    if (this.account != null) {
      json[r'account'] = this.account;
    } else {
      json[r'account'] = null;
    }
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
      json[r'replies'] = this.replies;
    return json;
  }

  /// Returns a new [CommentsList200ResponseItemsInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CommentsList200ResponseItemsInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CommentsList200ResponseItemsInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CommentsList200ResponseItemsInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CommentsList200ResponseItemsInner(
        id: mapValueOfType<int>(json, r'id')!,
        content: mapValueOfType<String>(json, r'content')!,
        accountId: mapValueOfType<int>(json, r'accountId'),
        guestName: mapValueOfType<String>(json, r'guestName'),
        guestIP: mapValueOfType<String>(json, r'guestIP'),
        guestUA: mapValueOfType<String>(json, r'guestUA'),
        noteId: mapValueOfType<int>(json, r'noteId')!,
        parentId: mapValueOfType<int>(json, r'parentId'),
        createdAt: mapValueOfType<String>(json, r'createdAt')!,
        updatedAt: mapValueOfType<String>(json, r'updatedAt')!,
        account: CommentsList200ResponseItemsInnerAccount.fromJson(json[r'account']),
        note: CommentsList200ResponseItemsInnerNote.fromJson(json[r'note']),
        replies: CommentsList200ResponseItemsInnerRepliesInner.listFromJson(json[r'replies']),
      );
    }
    return null;
  }

  static List<CommentsList200ResponseItemsInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CommentsList200ResponseItemsInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CommentsList200ResponseItemsInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CommentsList200ResponseItemsInner> mapFromJson(dynamic json) {
    final map = <String, CommentsList200ResponseItemsInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CommentsList200ResponseItemsInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CommentsList200ResponseItemsInner-objects as value to a dart map
  static Map<String, List<CommentsList200ResponseItemsInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CommentsList200ResponseItemsInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CommentsList200ResponseItemsInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'content',
    'accountId',
    'guestName',
    'guestIP',
    'guestUA',
    'noteId',
    'parentId',
    'createdAt',
    'updatedAt',
    'account',
    'note',
  };
}


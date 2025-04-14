//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotificationsList200ResponseInner {
  /// Returns a new [NotificationsList200ResponseInner] instance.
  NotificationsList200ResponseInner({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.metadata,
    required this.isRead,
    required this.accountId,
    required this.createdAt,
    required this.updatedAt,
  });

  int id;

  NotificationsList200ResponseInnerType type;

  String title;

  String content;

  Object? metadata;

  bool isRead;

  int accountId;

  String createdAt;

  String updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotificationsList200ResponseInner &&
    other.id == id &&
    other.type == type &&
    other.title == title &&
    other.content == content &&
    other.metadata == metadata &&
    other.isRead == isRead &&
    other.accountId == accountId &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (type.hashCode) +
    (title.hashCode) +
    (content.hashCode) +
    (metadata == null ? 0 : metadata!.hashCode) +
    (isRead.hashCode) +
    (accountId.hashCode) +
    (createdAt.hashCode) +
    (updatedAt.hashCode);

  @override
  String toString() => 'NotificationsList200ResponseInner[id=$id, type=$type, title=$title, content=$content, metadata=$metadata, isRead=$isRead, accountId=$accountId, createdAt=$createdAt, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'type'] = this.type;
      json[r'title'] = this.title;
      json[r'content'] = this.content;
    if (this.metadata != null) {
      json[r'metadata'] = this.metadata;
    } else {
      json[r'metadata'] = null;
    }
      json[r'isRead'] = this.isRead;
      json[r'accountId'] = this.accountId;
      json[r'createdAt'] = this.createdAt;
      json[r'updatedAt'] = this.updatedAt;
    return json;
  }

  /// Returns a new [NotificationsList200ResponseInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationsList200ResponseInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotificationsList200ResponseInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotificationsList200ResponseInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotificationsList200ResponseInner(
        id: mapValueOfType<int>(json, r'id')!,
        type: NotificationsList200ResponseInnerType.fromJson(json[r'type'])!,
        title: mapValueOfType<String>(json, r'title')!,
        content: mapValueOfType<String>(json, r'content')!,
        metadata: mapValueOfType<Object>(json, r'metadata'),
        isRead: mapValueOfType<bool>(json, r'isRead')!,
        accountId: mapValueOfType<int>(json, r'accountId')!,
        createdAt: mapValueOfType<String>(json, r'createdAt')!,
        updatedAt: mapValueOfType<String>(json, r'updatedAt')!,
      );
    }
    return null;
  }

  static List<NotificationsList200ResponseInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationsList200ResponseInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationsList200ResponseInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationsList200ResponseInner> mapFromJson(dynamic json) {
    final map = <String, NotificationsList200ResponseInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationsList200ResponseInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationsList200ResponseInner-objects as value to a dart map
  static Map<String, List<NotificationsList200ResponseInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotificationsList200ResponseInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotificationsList200ResponseInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'type',
    'title',
    'content',
    'isRead',
    'accountId',
    'createdAt',
    'updatedAt',
  };
}


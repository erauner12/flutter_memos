//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class V1Inbox {
  /// Returns a new [V1Inbox] instance.
  V1Inbox({
    this.name,
    this.sender,
    this.receiver,
    this.status,
    this.createTime,
    this.type,
    this.activityId,
  });

  /// The name of the inbox. Format: inboxes/{id}, id is the system generated auto-incremented id.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? sender;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? receiver;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  V1InboxStatus? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  V1InboxType? type;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? activityId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is V1Inbox &&
    other.name == name &&
    other.sender == sender &&
    other.receiver == receiver &&
    other.status == status &&
    other.createTime == createTime &&
    other.type == type &&
    other.activityId == activityId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (sender == null ? 0 : sender!.hashCode) +
    (receiver == null ? 0 : receiver!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (createTime == null ? 0 : createTime!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (activityId == null ? 0 : activityId!.hashCode);

  @override
  String toString() => 'V1Inbox[name=$name, sender=$sender, receiver=$receiver, status=$status, createTime=$createTime, type=$type, activityId=$activityId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.sender != null) {
      json[r'sender'] = this.sender;
    } else {
      json[r'sender'] = null;
    }
    if (this.receiver != null) {
      json[r'receiver'] = this.receiver;
    } else {
      json[r'receiver'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.createTime != null) {
      json[r'createTime'] = this.createTime!.toUtc().toIso8601String();
    } else {
      json[r'createTime'] = null;
    }
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.activityId != null) {
      json[r'activityId'] = this.activityId;
    } else {
      json[r'activityId'] = null;
    }
    return json;
  }

  /// Returns a new [V1Inbox] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static V1Inbox? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "V1Inbox[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "V1Inbox[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return V1Inbox(
        name: mapValueOfType<String>(json, r'name'),
        sender: mapValueOfType<String>(json, r'sender'),
        receiver: mapValueOfType<String>(json, r'receiver'),
        status: V1InboxStatus.fromJson(json[r'status']),
        createTime: mapDateTime(json, r'createTime', r''),
        type: V1InboxType.fromJson(json[r'type']),
        activityId: mapValueOfType<int>(json, r'activityId'),
      );
    }
    return null;
  }

  static List<V1Inbox> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1Inbox>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1Inbox.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, V1Inbox> mapFromJson(dynamic json) {
    final map = <String, V1Inbox>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = V1Inbox.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of V1Inbox-objects as value to a dart map
  static Map<String, List<V1Inbox>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<V1Inbox>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = V1Inbox.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


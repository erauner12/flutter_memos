//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class InboxServiceUpdateInboxRequest {
  /// Returns a new [InboxServiceUpdateInboxRequest] instance.
  InboxServiceUpdateInboxRequest({
    this.sender,
    this.receiver,
    this.status,
    this.createTime,
    this.type,
    this.activityId,
  });

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
  bool operator ==(Object other) => identical(this, other) || other is InboxServiceUpdateInboxRequest &&
    other.sender == sender &&
    other.receiver == receiver &&
    other.status == status &&
    other.createTime == createTime &&
    other.type == type &&
    other.activityId == activityId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (sender == null ? 0 : sender!.hashCode) +
    (receiver == null ? 0 : receiver!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (createTime == null ? 0 : createTime!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (activityId == null ? 0 : activityId!.hashCode);

  @override
  String toString() => 'InboxServiceUpdateInboxRequest[sender=$sender, receiver=$receiver, status=$status, createTime=$createTime, type=$type, activityId=$activityId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
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

  /// Returns a new [InboxServiceUpdateInboxRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InboxServiceUpdateInboxRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "InboxServiceUpdateInboxRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "InboxServiceUpdateInboxRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return InboxServiceUpdateInboxRequest(
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

  static List<InboxServiceUpdateInboxRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InboxServiceUpdateInboxRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InboxServiceUpdateInboxRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InboxServiceUpdateInboxRequest> mapFromJson(dynamic json) {
    final map = <String, InboxServiceUpdateInboxRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InboxServiceUpdateInboxRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InboxServiceUpdateInboxRequest-objects as value to a dart map
  static Map<String, List<InboxServiceUpdateInboxRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InboxServiceUpdateInboxRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InboxServiceUpdateInboxRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


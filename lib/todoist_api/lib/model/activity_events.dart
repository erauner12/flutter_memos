//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ActivityEvents {
  /// Returns a new [ActivityEvents] instance.
  ActivityEvents({
    required this.objectType,
    required this.objectId,
    required this.v2ObjectId,
    required this.eventType,
    required this.eventDate,
    this.id,
    this.parentProjectId,
    this.v2ParentProjectId,
    this.parentItemId,
    this.v2ParentItemId,
    this.initiatorId,
    this.extraDataId,
    this.extraData = const {},
  });

  String objectType;

  String objectId;

  String v2ObjectId;

  String eventType;

  DateTime eventDate;

  int? id;

  String? parentProjectId;

  String? v2ParentProjectId;

  String? parentItemId;

  String? v2ParentItemId;

  /// The ID of the user who is responsible for the event, which only makes sense in shared projects, items and notes, and is null for non-shared objects
  String? initiatorId;

  int? extraDataId;

  Map<String, Object>? extraData;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ActivityEvents &&
    other.objectType == objectType &&
    other.objectId == objectId &&
    other.v2ObjectId == v2ObjectId &&
    other.eventType == eventType &&
    other.eventDate == eventDate &&
    other.id == id &&
    other.parentProjectId == parentProjectId &&
    other.v2ParentProjectId == v2ParentProjectId &&
    other.parentItemId == parentItemId &&
    other.v2ParentItemId == v2ParentItemId &&
    other.initiatorId == initiatorId &&
    other.extraDataId == extraDataId &&
    _deepEquality.equals(other.extraData, extraData);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (objectType.hashCode) +
    (objectId.hashCode) +
    (v2ObjectId.hashCode) +
    (eventType.hashCode) +
    (eventDate.hashCode) +
    (id == null ? 0 : id!.hashCode) +
    (parentProjectId == null ? 0 : parentProjectId!.hashCode) +
    (v2ParentProjectId == null ? 0 : v2ParentProjectId!.hashCode) +
    (parentItemId == null ? 0 : parentItemId!.hashCode) +
    (v2ParentItemId == null ? 0 : v2ParentItemId!.hashCode) +
    (initiatorId == null ? 0 : initiatorId!.hashCode) +
    (extraDataId == null ? 0 : extraDataId!.hashCode) +
    (extraData == null ? 0 : extraData!.hashCode);

  @override
  String toString() => 'ActivityEvents[objectType=$objectType, objectId=$objectId, v2ObjectId=$v2ObjectId, eventType=$eventType, eventDate=$eventDate, id=$id, parentProjectId=$parentProjectId, v2ParentProjectId=$v2ParentProjectId, parentItemId=$parentItemId, v2ParentItemId=$v2ParentItemId, initiatorId=$initiatorId, extraDataId=$extraDataId, extraData=$extraData]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'object_type'] = this.objectType;
      json[r'object_id'] = this.objectId;
      json[r'v2_object_id'] = this.v2ObjectId;
      json[r'event_type'] = this.eventType;
      json[r'event_date'] = this.eventDate.toUtc().toIso8601String();
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.parentProjectId != null) {
      json[r'parent_project_id'] = this.parentProjectId;
    } else {
      json[r'parent_project_id'] = null;
    }
    if (this.v2ParentProjectId != null) {
      json[r'v2_parent_project_id'] = this.v2ParentProjectId;
    } else {
      json[r'v2_parent_project_id'] = null;
    }
    if (this.parentItemId != null) {
      json[r'parent_item_id'] = this.parentItemId;
    } else {
      json[r'parent_item_id'] = null;
    }
    if (this.v2ParentItemId != null) {
      json[r'v2_parent_item_id'] = this.v2ParentItemId;
    } else {
      json[r'v2_parent_item_id'] = null;
    }
    if (this.initiatorId != null) {
      json[r'initiator_id'] = this.initiatorId;
    } else {
      json[r'initiator_id'] = null;
    }
    if (this.extraDataId != null) {
      json[r'extra_data_id'] = this.extraDataId;
    } else {
      json[r'extra_data_id'] = null;
    }
    if (this.extraData != null) {
      json[r'extra_data'] = this.extraData;
    } else {
      json[r'extra_data'] = null;
    }
    return json;
  }

  /// Returns a new [ActivityEvents] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ActivityEvents? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ActivityEvents[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ActivityEvents[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ActivityEvents(
        objectType: mapValueOfType<String>(json, r'object_type')!,
        objectId: mapValueOfType<String>(json, r'object_id')!,
        v2ObjectId: mapValueOfType<String>(json, r'v2_object_id')!,
        eventType: mapValueOfType<String>(json, r'event_type')!,
        eventDate: mapDateTime(json, r'event_date', r'')!,
        id: mapValueOfType<int>(json, r'id'),
        parentProjectId: mapValueOfType<String>(json, r'parent_project_id'),
        v2ParentProjectId: mapValueOfType<String>(json, r'v2_parent_project_id'),
        parentItemId: mapValueOfType<String>(json, r'parent_item_id'),
        v2ParentItemId: mapValueOfType<String>(json, r'v2_parent_item_id'),
        initiatorId: mapValueOfType<String>(json, r'initiator_id'),
        extraDataId: mapValueOfType<int>(json, r'extra_data_id'),
        extraData: mapCastOfType<String, Object>(json, r'extra_data') ?? const {},
      );
    }
    return null;
  }

  static List<ActivityEvents> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ActivityEvents>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ActivityEvents.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ActivityEvents> mapFromJson(dynamic json) {
    final map = <String, ActivityEvents>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ActivityEvents.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ActivityEvents-objects as value to a dart map
  static Map<String, List<ActivityEvents>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ActivityEvents>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ActivityEvents.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'object_type',
    'object_id',
    'v2_object_id',
    'event_type',
    'event_date',
  };
}


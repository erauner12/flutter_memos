//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class V1Activity {
  /// Returns a new [V1Activity] instance.
  V1Activity({
    this.name,
    this.creator,
    this.type,
    this.level,
    this.createTime,
    this.payload,
  });

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
  String? creator;

  /// The type of the activity.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? type;

  /// The level of the activity.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? level;

  /// The create time of the activity.
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
  Apiv1ActivityPayload? payload;

  @override
  bool operator ==(Object other) => identical(this, other) || other is V1Activity &&
    other.name == name &&
    other.creator == creator &&
    other.type == type &&
    other.level == level &&
    other.createTime == createTime &&
    other.payload == payload;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (creator == null ? 0 : creator!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (level == null ? 0 : level!.hashCode) +
    (createTime == null ? 0 : createTime!.hashCode) +
    (payload == null ? 0 : payload!.hashCode);

  @override
  String toString() => 'V1Activity[name=$name, creator=$creator, type=$type, level=$level, createTime=$createTime, payload=$payload]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.creator != null) {
      json[r'creator'] = this.creator;
    } else {
      json[r'creator'] = null;
    }
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.level != null) {
      json[r'level'] = this.level;
    } else {
      json[r'level'] = null;
    }
    if (this.createTime != null) {
      json[r'createTime'] = this.createTime!.toUtc().toIso8601String();
    } else {
      json[r'createTime'] = null;
    }
    if (this.payload != null) {
      json[r'payload'] = this.payload;
    } else {
      json[r'payload'] = null;
    }
    return json;
  }

  /// Returns a new [V1Activity] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static V1Activity? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "V1Activity[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "V1Activity[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return V1Activity(
        name: mapValueOfType<String>(json, r'name'),
        creator: mapValueOfType<String>(json, r'creator'),
        type: mapValueOfType<String>(json, r'type'),
        level: mapValueOfType<String>(json, r'level'),
        createTime: mapDateTime(json, r'createTime', r''),
        payload: Apiv1ActivityPayload.fromJson(json[r'payload']),
      );
    }
    return null;
  }

  static List<V1Activity> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1Activity>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1Activity.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, V1Activity> mapFromJson(dynamic json) {
    final map = <String, V1Activity>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = V1Activity.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of V1Activity-objects as value to a dart map
  static Map<String, List<V1Activity>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<V1Activity>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = V1Activity.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


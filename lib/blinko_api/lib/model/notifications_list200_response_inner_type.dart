// @dart=2.18
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotificationsList200ResponseInnerType {
  /// Returns a new [NotificationsList200ResponseInnerType] instance.
  NotificationsList200ResponseInnerType({
    this.dummyField, // Add a dummy field
  });

  String? dummyField; // Add a dummy field

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotificationsList200ResponseInnerType &&
    other.dummyField == dummyField; // Compare dummy field

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (dummyField == null ? 0 : dummyField!.hashCode); // Hash dummy field

  @override
  String toString() => 'NotificationsList200ResponseInnerType[dummyField=$dummyField]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.dummyField != null) {
      json[r'dummyField'] = this.dummyField;
    } else {
      json[r'dummyField'] = null;
    }
    return json;
  }

  /// Returns a new [NotificationsList200ResponseInnerType] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationsList200ResponseInnerType? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          // Allow dummyField to be missing
          if (key != 'dummyField') {
            assert(json.containsKey(key), 'Required key "NotificationsList200ResponseInnerType[$key]" is missing from JSON.');
            assert(json[key] != null, 'Required key "NotificationsList200ResponseInnerType[$key]" has a null value in JSON.');
          }
        });
        return true;
      }());

      return NotificationsList200ResponseInnerType(
        dummyField: mapValueOfType<String>(json, r'dummyField'),
      );
    }
    return null;
  }

  static List<NotificationsList200ResponseInnerType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationsList200ResponseInnerType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationsList200ResponseInnerType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationsList200ResponseInnerType> mapFromJson(dynamic json) {
    final map = <String, NotificationsList200ResponseInnerType>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationsList200ResponseInnerType.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationsList200ResponseInnerType-objects as value to a dart map
  static Map<String, List<NotificationsList200ResponseInnerType>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotificationsList200ResponseInnerType>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotificationsList200ResponseInnerType.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
     // No required keys for this dummy implementation
  };
}
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class IDMapping {
  /// Returns a new [IDMapping] instance.
  IDMapping({
    required this.oldId,
    required this.newId,
  });

  String? oldId;

  String? newId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is IDMapping &&
    other.oldId == oldId &&
    other.newId == newId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (oldId == null ? 0 : oldId!.hashCode) +
    (newId == null ? 0 : newId!.hashCode);

  @override
  String toString() => 'IDMapping[oldId=$oldId, newId=$newId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.oldId != null) {
      json[r'old_id'] = this.oldId;
    } else {
      json[r'old_id'] = null;
    }
    if (this.newId != null) {
      json[r'new_id'] = this.newId;
    } else {
      json[r'new_id'] = null;
    }
    return json;
  }

  /// Returns a new [IDMapping] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static IDMapping? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "IDMapping[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "IDMapping[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return IDMapping(
        oldId: mapValueOfType<String>(json, r'old_id'),
        newId: mapValueOfType<String>(json, r'new_id'),
      );
    }
    return null;
  }

  static List<IDMapping> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <IDMapping>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IDMapping.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, IDMapping> mapFromJson(dynamic json) {
    final map = <String, IDMapping>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = IDMapping.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of IDMapping-objects as value to a dart map
  static Map<String, List<IDMapping>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<IDMapping>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = IDMapping.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'old_id',
    'new_id',
  };
}


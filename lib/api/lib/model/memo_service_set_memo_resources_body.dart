//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MemoServiceSetMemoResourcesBody {
  /// Returns a new [MemoServiceSetMemoResourcesBody] instance.
  MemoServiceSetMemoResourcesBody({
    this.resources = const [],
  });

  List<V1Resource> resources;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MemoServiceSetMemoResourcesBody &&
    _deepEquality.equals(other.resources, resources);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (resources.hashCode);

  @override
  String toString() => 'MemoServiceSetMemoResourcesBody[resources=$resources]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'resources'] = this.resources;
    return json;
  }

  /// Returns a new [MemoServiceSetMemoResourcesBody] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MemoServiceSetMemoResourcesBody? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "MemoServiceSetMemoResourcesBody[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "MemoServiceSetMemoResourcesBody[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MemoServiceSetMemoResourcesBody(
        resources: V1Resource.listFromJson(json[r'resources']),
      );
    }
    return null;
  }

  static List<MemoServiceSetMemoResourcesBody> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MemoServiceSetMemoResourcesBody>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MemoServiceSetMemoResourcesBody.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MemoServiceSetMemoResourcesBody> mapFromJson(dynamic json) {
    final map = <String, MemoServiceSetMemoResourcesBody>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MemoServiceSetMemoResourcesBody.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MemoServiceSetMemoResourcesBody-objects as value to a dart map
  static Map<String, List<MemoServiceSetMemoResourcesBody>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MemoServiceSetMemoResourcesBody>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MemoServiceSetMemoResourcesBody.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


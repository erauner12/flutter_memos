//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UsersLinkAccountRequest {
  /// Returns a new [UsersLinkAccountRequest] instance.
  UsersLinkAccountRequest({
    required this.id,
    required this.originalPassword,
  });

  num id;

  String originalPassword;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UsersLinkAccountRequest &&
    other.id == id &&
    other.originalPassword == originalPassword;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (originalPassword.hashCode);

  @override
  String toString() => 'UsersLinkAccountRequest[id=$id, originalPassword=$originalPassword]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'originalPassword'] = this.originalPassword;
    return json;
  }

  /// Returns a new [UsersLinkAccountRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UsersLinkAccountRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UsersLinkAccountRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UsersLinkAccountRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UsersLinkAccountRequest(
        id: num.parse('${json[r'id']}'),
        originalPassword: mapValueOfType<String>(json, r'originalPassword')!,
      );
    }
    return null;
  }

  static List<UsersLinkAccountRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UsersLinkAccountRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UsersLinkAccountRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UsersLinkAccountRequest> mapFromJson(dynamic json) {
    final map = <String, UsersLinkAccountRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UsersLinkAccountRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UsersLinkAccountRequest-objects as value to a dart map
  static Map<String, List<UsersLinkAccountRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UsersLinkAccountRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UsersLinkAccountRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'originalPassword',
  };
}


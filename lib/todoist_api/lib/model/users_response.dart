//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UsersResponse {
  /// Returns a new [UsersResponse] instance.
  UsersResponse({
    required this.hasMore,
    this.nextCursor,
    this.workspaceUsers = const [],
  });

  bool hasMore;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? nextCursor;

  List<MemberView> workspaceUsers;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UsersResponse &&
    other.hasMore == hasMore &&
    other.nextCursor == nextCursor &&
    _deepEquality.equals(other.workspaceUsers, workspaceUsers);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (hasMore.hashCode) +
    (nextCursor == null ? 0 : nextCursor!.hashCode) +
    (workspaceUsers.hashCode);

  @override
  String toString() => 'UsersResponse[hasMore=$hasMore, nextCursor=$nextCursor, workspaceUsers=$workspaceUsers]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'has_more'] = this.hasMore;
    if (this.nextCursor != null) {
      json[r'next_cursor'] = this.nextCursor;
    } else {
      json[r'next_cursor'] = null;
    }
      json[r'workspace_users'] = this.workspaceUsers;
    return json;
  }

  /// Returns a new [UsersResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UsersResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UsersResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UsersResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UsersResponse(
        hasMore: mapValueOfType<bool>(json, r'has_more')!,
        nextCursor: mapValueOfType<String>(json, r'next_cursor'),
        workspaceUsers: MemberView.listFromJson(json[r'workspace_users']),
      );
    }
    return null;
  }

  static List<UsersResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UsersResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UsersResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UsersResponse> mapFromJson(dynamic json) {
    final map = <String, UsersResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UsersResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UsersResponse-objects as value to a dart map
  static Map<String, List<UsersResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UsersResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UsersResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'has_more',
    'workspace_users',
  };
}


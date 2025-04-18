//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TodoistAppsAppPlatformControllersAccessTokenBody {
  /// Returns a new [TodoistAppsAppPlatformControllersAccessTokenBody] instance.
  TodoistAppsAppPlatformControllersAccessTokenBody({
    required this.clientId,
    required this.clientSecret,
    required this.scope,
  });

  /// The unique Client ID of the Todoist application that you registered
  String clientId;

  /// The unique Client Secret of the Todoist application that you registered
  String clientSecret;

  /// Scopes of the OAuth token. Please refer to the [Authorization](#tag/Authorization) guide for the detailed list of available scopes.
  String scope;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TodoistAppsAppPlatformControllersAccessTokenBody &&
    other.clientId == clientId &&
    other.clientSecret == clientSecret &&
    other.scope == scope;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (clientId.hashCode) +
    (clientSecret.hashCode) +
    (scope.hashCode);

  @override
  String toString() => 'TodoistAppsAppPlatformControllersAccessTokenBody[clientId=$clientId, clientSecret=$clientSecret, scope=$scope]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'client_id'] = this.clientId;
      json[r'client_secret'] = this.clientSecret;
      json[r'scope'] = this.scope;
    return json;
  }

  /// Returns a new [TodoistAppsAppPlatformControllersAccessTokenBody] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TodoistAppsAppPlatformControllersAccessTokenBody? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TodoistAppsAppPlatformControllersAccessTokenBody[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TodoistAppsAppPlatformControllersAccessTokenBody[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TodoistAppsAppPlatformControllersAccessTokenBody(
        clientId: mapValueOfType<String>(json, r'client_id')!,
        clientSecret: mapValueOfType<String>(json, r'client_secret')!,
        scope: mapValueOfType<String>(json, r'scope')!,
      );
    }
    return null;
  }

  static List<TodoistAppsAppPlatformControllersAccessTokenBody> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TodoistAppsAppPlatformControllersAccessTokenBody>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TodoistAppsAppPlatformControllersAccessTokenBody.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TodoistAppsAppPlatformControllersAccessTokenBody> mapFromJson(dynamic json) {
    final map = <String, TodoistAppsAppPlatformControllersAccessTokenBody>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TodoistAppsAppPlatformControllersAccessTokenBody.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TodoistAppsAppPlatformControllersAccessTokenBody-objects as value to a dart map
  static Map<String, List<TodoistAppsAppPlatformControllersAccessTokenBody>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TodoistAppsAppPlatformControllersAccessTokenBody>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TodoistAppsAppPlatformControllersAccessTokenBody.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'client_id',
    'client_secret',
    'scope',
  };
}


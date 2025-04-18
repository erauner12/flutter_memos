//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BackupResponse {
  /// Returns a new [BackupResponse] instance.
  BackupResponse({
    required this.version,
    required this.url,
  });

  /// Date and time of the backup version
  String version;

  /// Backup URL
  String url;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BackupResponse &&
    other.version == version &&
    other.url == url;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (version.hashCode) +
    (url.hashCode);

  @override
  String toString() => 'BackupResponse[version=$version, url=$url]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'version'] = this.version;
      json[r'url'] = this.url;
    return json;
  }

  /// Returns a new [BackupResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BackupResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "BackupResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "BackupResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BackupResponse(
        version: mapValueOfType<String>(json, r'version')!,
        url: mapValueOfType<String>(json, r'url')!,
      );
    }
    return null;
  }

  static List<BackupResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BackupResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BackupResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BackupResponse> mapFromJson(dynamic json) {
    final map = <String, BackupResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BackupResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BackupResponse-objects as value to a dart map
  static Map<String, List<BackupResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BackupResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BackupResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'version',
    'url',
  };
}


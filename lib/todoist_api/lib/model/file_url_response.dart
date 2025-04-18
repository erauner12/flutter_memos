//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FileURLResponse {
  /// Returns a new [FileURLResponse] instance.
  FileURLResponse({
    required this.fileName,
    required this.fileUrl,
  });

  String fileName;

  String fileUrl;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FileURLResponse &&
    other.fileName == fileName &&
    other.fileUrl == fileUrl;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (fileName.hashCode) +
    (fileUrl.hashCode);

  @override
  String toString() => 'FileURLResponse[fileName=$fileName, fileUrl=$fileUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'file_name'] = this.fileName;
      json[r'file_url'] = this.fileUrl;
    return json;
  }

  /// Returns a new [FileURLResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FileURLResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "FileURLResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "FileURLResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FileURLResponse(
        fileName: mapValueOfType<String>(json, r'file_name')!,
        fileUrl: mapValueOfType<String>(json, r'file_url')!,
      );
    }
    return null;
  }

  static List<FileURLResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FileURLResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FileURLResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FileURLResponse> mapFromJson(dynamic json) {
    final map = <String, FileURLResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FileURLResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FileURLResponse-objects as value to a dart map
  static Map<String, List<FileURLResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FileURLResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FileURLResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'file_name',
    'file_url',
  };
}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ResourceServiceUpdateResourceRequest {
  /// Returns a new [ResourceServiceUpdateResourceRequest] instance.
  ResourceServiceUpdateResourceRequest({
    this.createTime,
    this.filename,
    this.content,
    this.externalLink,
    this.type,
    this.size,
    this.memo,
  });

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
  String? filename;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? content;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? externalLink;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? type;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? size;

  /// The related memo. Refer to `Memo.name`.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? memo;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ResourceServiceUpdateResourceRequest &&
    other.createTime == createTime &&
    other.filename == filename &&
    other.content == content &&
    other.externalLink == externalLink &&
    other.type == type &&
    other.size == size &&
    other.memo == memo;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (createTime == null ? 0 : createTime!.hashCode) +
    (filename == null ? 0 : filename!.hashCode) +
    (content == null ? 0 : content!.hashCode) +
    (externalLink == null ? 0 : externalLink!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (size == null ? 0 : size!.hashCode) +
    (memo == null ? 0 : memo!.hashCode);

  @override
  String toString() => 'ResourceServiceUpdateResourceRequest[createTime=$createTime, filename=$filename, content=$content, externalLink=$externalLink, type=$type, size=$size, memo=$memo]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.createTime != null) {
      json[r'createTime'] = this.createTime!.toUtc().toIso8601String();
    } else {
      json[r'createTime'] = null;
    }
    if (this.filename != null) {
      json[r'filename'] = this.filename;
    } else {
      json[r'filename'] = null;
    }
    if (this.content != null) {
      json[r'content'] = this.content;
    } else {
      json[r'content'] = null;
    }
    if (this.externalLink != null) {
      json[r'externalLink'] = this.externalLink;
    } else {
      json[r'externalLink'] = null;
    }
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.size != null) {
      json[r'size'] = this.size;
    } else {
      json[r'size'] = null;
    }
    if (this.memo != null) {
      json[r'memo'] = this.memo;
    } else {
      json[r'memo'] = null;
    }
    return json;
  }

  /// Returns a new [ResourceServiceUpdateResourceRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ResourceServiceUpdateResourceRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ResourceServiceUpdateResourceRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ResourceServiceUpdateResourceRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ResourceServiceUpdateResourceRequest(
        createTime: mapDateTime(json, r'createTime', r''),
        filename: mapValueOfType<String>(json, r'filename'),
        content: mapValueOfType<String>(json, r'content'),
        externalLink: mapValueOfType<String>(json, r'externalLink'),
        type: mapValueOfType<String>(json, r'type'),
        size: mapValueOfType<String>(json, r'size'),
        memo: mapValueOfType<String>(json, r'memo'),
      );
    }
    return null;
  }

  static List<ResourceServiceUpdateResourceRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResourceServiceUpdateResourceRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResourceServiceUpdateResourceRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ResourceServiceUpdateResourceRequest> mapFromJson(dynamic json) {
    final map = <String, ResourceServiceUpdateResourceRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ResourceServiceUpdateResourceRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ResourceServiceUpdateResourceRequest-objects as value to a dart map
  static Map<String, List<ResourceServiceUpdateResourceRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ResourceServiceUpdateResourceRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ResourceServiceUpdateResourceRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


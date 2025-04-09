//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateCommentAttachmentParameter {
  /// Returns a new [CreateCommentAttachmentParameter] instance.
  CreateCommentAttachmentParameter({
    this.resourceType,
    this.fileUrl,
    this.fileType,
    this.fileName,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? resourceType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? fileUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? fileType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? fileName;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateCommentAttachmentParameter &&
    other.resourceType == resourceType &&
    other.fileUrl == fileUrl &&
    other.fileType == fileType &&
    other.fileName == fileName;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (resourceType == null ? 0 : resourceType!.hashCode) +
    (fileUrl == null ? 0 : fileUrl!.hashCode) +
    (fileType == null ? 0 : fileType!.hashCode) +
    (fileName == null ? 0 : fileName!.hashCode);

  @override
  String toString() => 'CreateCommentAttachmentParameter[resourceType=$resourceType, fileUrl=$fileUrl, fileType=$fileType, fileName=$fileName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.resourceType != null) {
      json[r'resource_type'] = this.resourceType;
    } else {
      json[r'resource_type'] = null;
    }
    if (this.fileUrl != null) {
      json[r'file_url'] = this.fileUrl;
    } else {
      json[r'file_url'] = null;
    }
    if (this.fileType != null) {
      json[r'file_type'] = this.fileType;
    } else {
      json[r'file_type'] = null;
    }
    if (this.fileName != null) {
      json[r'file_name'] = this.fileName;
    } else {
      json[r'file_name'] = null;
    }
    return json;
  }

  /// Returns a new [CreateCommentAttachmentParameter] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateCommentAttachmentParameter? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CreateCommentAttachmentParameter[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CreateCommentAttachmentParameter[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CreateCommentAttachmentParameter(
        resourceType: mapValueOfType<String>(json, r'resource_type'),
        fileUrl: mapValueOfType<String>(json, r'file_url'),
        fileType: mapValueOfType<String>(json, r'file_type'),
        fileName: mapValueOfType<String>(json, r'file_name'),
      );
    }
    return null;
  }

  static List<CreateCommentAttachmentParameter> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateCommentAttachmentParameter>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateCommentAttachmentParameter.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateCommentAttachmentParameter> mapFromJson(dynamic json) {
    final map = <String, CreateCommentAttachmentParameter>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateCommentAttachmentParameter.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateCommentAttachmentParameter-objects as value to a dart map
  static Map<String, List<CreateCommentAttachmentParameter>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateCommentAttachmentParameter>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateCommentAttachmentParameter.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


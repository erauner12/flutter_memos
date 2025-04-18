//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ExposedCollaboratorSyncView {
  /// Returns a new [ExposedCollaboratorSyncView] instance.
  ExposedCollaboratorSyncView({
    required this.id,
    required this.fullName,
    required this.email,
    required this.timezone,
    required this.imageId,
    this.isDeleted,
  });

  String id;

  String fullName;

  String email;

  String timezone;

  String? imageId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isDeleted;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ExposedCollaboratorSyncView &&
    other.id == id &&
    other.fullName == fullName &&
    other.email == email &&
    other.timezone == timezone &&
    other.imageId == imageId &&
    other.isDeleted == isDeleted;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (fullName.hashCode) +
    (email.hashCode) +
    (timezone.hashCode) +
    (imageId == null ? 0 : imageId!.hashCode) +
    (isDeleted == null ? 0 : isDeleted!.hashCode);

  @override
  String toString() => 'ExposedCollaboratorSyncView[id=$id, fullName=$fullName, email=$email, timezone=$timezone, imageId=$imageId, isDeleted=$isDeleted]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'full_name'] = this.fullName;
      json[r'email'] = this.email;
      json[r'timezone'] = this.timezone;
    if (this.imageId != null) {
      json[r'image_id'] = this.imageId;
    } else {
      json[r'image_id'] = null;
    }
    if (this.isDeleted != null) {
      json[r'is_deleted'] = this.isDeleted;
    } else {
      json[r'is_deleted'] = null;
    }
    return json;
  }

  /// Returns a new [ExposedCollaboratorSyncView] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ExposedCollaboratorSyncView? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ExposedCollaboratorSyncView[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ExposedCollaboratorSyncView[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ExposedCollaboratorSyncView(
        id: mapValueOfType<String>(json, r'id')!,
        fullName: mapValueOfType<String>(json, r'full_name')!,
        email: mapValueOfType<String>(json, r'email')!,
        timezone: mapValueOfType<String>(json, r'timezone')!,
        imageId: mapValueOfType<String>(json, r'image_id'),
        isDeleted: mapValueOfType<bool>(json, r'is_deleted'),
      );
    }
    return null;
  }

  static List<ExposedCollaboratorSyncView> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ExposedCollaboratorSyncView>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ExposedCollaboratorSyncView.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ExposedCollaboratorSyncView> mapFromJson(dynamic json) {
    final map = <String, ExposedCollaboratorSyncView>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ExposedCollaboratorSyncView.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ExposedCollaboratorSyncView-objects as value to a dart map
  static Map<String, List<ExposedCollaboratorSyncView>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ExposedCollaboratorSyncView>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ExposedCollaboratorSyncView.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'full_name',
    'email',
    'timezone',
    'image_id',
  };
}


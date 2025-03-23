//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Apiv1ActivityPayload {
  /// Returns a new [Apiv1ActivityPayload] instance.
  Apiv1ActivityPayload({
    this.memoComment,
    this.versionUpdate,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Apiv1ActivityMemoCommentPayload? memoComment;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Apiv1ActivityVersionUpdatePayload? versionUpdate;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Apiv1ActivityPayload &&
    other.memoComment == memoComment &&
    other.versionUpdate == versionUpdate;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (memoComment == null ? 0 : memoComment!.hashCode) +
    (versionUpdate == null ? 0 : versionUpdate!.hashCode);

  @override
  String toString() => 'Apiv1ActivityPayload[memoComment=$memoComment, versionUpdate=$versionUpdate]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.memoComment != null) {
      json[r'memoComment'] = this.memoComment;
    } else {
      json[r'memoComment'] = null;
    }
    if (this.versionUpdate != null) {
      json[r'versionUpdate'] = this.versionUpdate;
    } else {
      json[r'versionUpdate'] = null;
    }
    return json;
  }

  /// Returns a new [Apiv1ActivityPayload] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Apiv1ActivityPayload? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Apiv1ActivityPayload[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Apiv1ActivityPayload[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Apiv1ActivityPayload(
        memoComment: Apiv1ActivityMemoCommentPayload.fromJson(json[r'memoComment']),
        versionUpdate: Apiv1ActivityVersionUpdatePayload.fromJson(json[r'versionUpdate']),
      );
    }
    return null;
  }

  static List<Apiv1ActivityPayload> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Apiv1ActivityPayload>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Apiv1ActivityPayload.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Apiv1ActivityPayload> mapFromJson(dynamic json) {
    final map = <String, Apiv1ActivityPayload>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Apiv1ActivityPayload.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Apiv1ActivityPayload-objects as value to a dart map
  static Map<String, List<Apiv1ActivityPayload>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Apiv1ActivityPayload>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Apiv1ActivityPayload.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


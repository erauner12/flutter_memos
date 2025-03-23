//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Apiv1ActivityMemoCommentPayload {
  /// Returns a new [Apiv1ActivityMemoCommentPayload] instance.
  Apiv1ActivityMemoCommentPayload({
    this.memo,
    this.relatedMemo,
  });

  /// The memo name of comment. Refer to `Memo.name`.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? memo;

  /// The name of related memo.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? relatedMemo;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Apiv1ActivityMemoCommentPayload &&
    other.memo == memo &&
    other.relatedMemo == relatedMemo;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (memo == null ? 0 : memo!.hashCode) +
    (relatedMemo == null ? 0 : relatedMemo!.hashCode);

  @override
  String toString() => 'Apiv1ActivityMemoCommentPayload[memo=$memo, relatedMemo=$relatedMemo]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.memo != null) {
      json[r'memo'] = this.memo;
    } else {
      json[r'memo'] = null;
    }
    if (this.relatedMemo != null) {
      json[r'relatedMemo'] = this.relatedMemo;
    } else {
      json[r'relatedMemo'] = null;
    }
    return json;
  }

  /// Returns a new [Apiv1ActivityMemoCommentPayload] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Apiv1ActivityMemoCommentPayload? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Apiv1ActivityMemoCommentPayload[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Apiv1ActivityMemoCommentPayload[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Apiv1ActivityMemoCommentPayload(
        memo: mapValueOfType<String>(json, r'memo'),
        relatedMemo: mapValueOfType<String>(json, r'relatedMemo'),
      );
    }
    return null;
  }

  static List<Apiv1ActivityMemoCommentPayload> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Apiv1ActivityMemoCommentPayload>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Apiv1ActivityMemoCommentPayload.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Apiv1ActivityMemoCommentPayload> mapFromJson(dynamic json) {
    final map = <String, Apiv1ActivityMemoCommentPayload>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Apiv1ActivityMemoCommentPayload.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Apiv1ActivityMemoCommentPayload-objects as value to a dart map
  static Map<String, List<Apiv1ActivityMemoCommentPayload>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Apiv1ActivityMemoCommentPayload>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Apiv1ActivityMemoCommentPayload.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


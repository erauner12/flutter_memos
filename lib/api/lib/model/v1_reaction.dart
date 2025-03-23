//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class V1Reaction {
  /// Returns a new [V1Reaction] instance.
  V1Reaction({
    this.id,
    this.creator,
    this.contentId,
    this.reactionType,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? id;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? creator;

  /// The content identifier. For memo, it should be the `Memo.name`.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? contentId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? reactionType;

  @override
  bool operator ==(Object other) => identical(this, other) || other is V1Reaction &&
    other.id == id &&
    other.creator == creator &&
    other.contentId == contentId &&
    other.reactionType == reactionType;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (creator == null ? 0 : creator!.hashCode) +
    (contentId == null ? 0 : contentId!.hashCode) +
    (reactionType == null ? 0 : reactionType!.hashCode);

  @override
  String toString() => 'V1Reaction[id=$id, creator=$creator, contentId=$contentId, reactionType=$reactionType]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.creator != null) {
      json[r'creator'] = this.creator;
    } else {
      json[r'creator'] = null;
    }
    if (this.contentId != null) {
      json[r'contentId'] = this.contentId;
    } else {
      json[r'contentId'] = null;
    }
    if (this.reactionType != null) {
      json[r'reactionType'] = this.reactionType;
    } else {
      json[r'reactionType'] = null;
    }
    return json;
  }

  /// Returns a new [V1Reaction] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static V1Reaction? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "V1Reaction[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "V1Reaction[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return V1Reaction(
        id: mapValueOfType<int>(json, r'id'),
        creator: mapValueOfType<String>(json, r'creator'),
        contentId: mapValueOfType<String>(json, r'contentId'),
        reactionType: mapValueOfType<String>(json, r'reactionType'),
      );
    }
    return null;
  }

  static List<V1Reaction> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1Reaction>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1Reaction.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, V1Reaction> mapFromJson(dynamic json) {
    final map = <String, V1Reaction>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = V1Reaction.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of V1Reaction-objects as value to a dart map
  static Map<String, List<V1Reaction>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<V1Reaction>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = V1Reaction.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


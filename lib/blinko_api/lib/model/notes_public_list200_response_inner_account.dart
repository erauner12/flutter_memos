//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesPublicList200ResponseInnerAccount {
  /// Returns a new [NotesPublicList200ResponseInnerAccount] instance.
  NotesPublicList200ResponseInnerAccount({
    this.image,
    this.nickname,
    this.name,
    this.id,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? image;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? nickname;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? id;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesPublicList200ResponseInnerAccount &&
    other.image == image &&
    other.nickname == nickname &&
    other.name == name &&
    other.id == id;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (image == null ? 0 : image!.hashCode) +
    (nickname == null ? 0 : nickname!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (id == null ? 0 : id!.hashCode);

  @override
  String toString() => 'NotesPublicList200ResponseInnerAccount[image=$image, nickname=$nickname, name=$name, id=$id]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.image != null) {
      json[r'image'] = this.image;
    } else {
      json[r'image'] = null;
    }
    if (this.nickname != null) {
      json[r'nickname'] = this.nickname;
    } else {
      json[r'nickname'] = null;
    }
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    return json;
  }

  /// Returns a new [NotesPublicList200ResponseInnerAccount] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesPublicList200ResponseInnerAccount? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesPublicList200ResponseInnerAccount[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesPublicList200ResponseInnerAccount[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesPublicList200ResponseInnerAccount(
        image: mapValueOfType<String>(json, r'image'),
        nickname: mapValueOfType<String>(json, r'nickname'),
        name: mapValueOfType<String>(json, r'name'),
        id: num.parse('${json[r'id']}'),
      );
    }
    return null;
  }

  static List<NotesPublicList200ResponseInnerAccount> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesPublicList200ResponseInnerAccount>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesPublicList200ResponseInnerAccount.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesPublicList200ResponseInnerAccount> mapFromJson(dynamic json) {
    final map = <String, NotesPublicList200ResponseInnerAccount>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesPublicList200ResponseInnerAccount.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesPublicList200ResponseInnerAccount-objects as value to a dart map
  static Map<String, List<NotesPublicList200ResponseInnerAccount>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesPublicList200ResponseInnerAccount>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesPublicList200ResponseInnerAccount.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


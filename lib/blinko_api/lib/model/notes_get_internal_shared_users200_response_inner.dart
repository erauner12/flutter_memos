//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesGetInternalSharedUsers200ResponseInner {
  /// Returns a new [NotesGetInternalSharedUsers200ResponseInner] instance.
  NotesGetInternalSharedUsers200ResponseInner({
    required this.id,
    required this.name,
    required this.nickname,
    required this.image,
    required this.loginType,
    required this.canEdit,
  });

  num id;

  String name;

  String nickname;

  String image;

  String loginType;

  bool canEdit;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesGetInternalSharedUsers200ResponseInner &&
    other.id == id &&
    other.name == name &&
    other.nickname == nickname &&
    other.image == image &&
    other.loginType == loginType &&
    other.canEdit == canEdit;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (nickname.hashCode) +
    (image.hashCode) +
    (loginType.hashCode) +
    (canEdit.hashCode);

  @override
  String toString() => 'NotesGetInternalSharedUsers200ResponseInner[id=$id, name=$name, nickname=$nickname, image=$image, loginType=$loginType, canEdit=$canEdit]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'nickname'] = this.nickname;
      json[r'image'] = this.image;
      json[r'loginType'] = this.loginType;
      json[r'canEdit'] = this.canEdit;
    return json;
  }

  /// Returns a new [NotesGetInternalSharedUsers200ResponseInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesGetInternalSharedUsers200ResponseInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesGetInternalSharedUsers200ResponseInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesGetInternalSharedUsers200ResponseInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesGetInternalSharedUsers200ResponseInner(
        id: num.parse('${json[r'id']}'),
        name: mapValueOfType<String>(json, r'name')!,
        nickname: mapValueOfType<String>(json, r'nickname')!,
        image: mapValueOfType<String>(json, r'image')!,
        loginType: mapValueOfType<String>(json, r'loginType')!,
        canEdit: mapValueOfType<bool>(json, r'canEdit')!,
      );
    }
    return null;
  }

  static List<NotesGetInternalSharedUsers200ResponseInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesGetInternalSharedUsers200ResponseInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesGetInternalSharedUsers200ResponseInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesGetInternalSharedUsers200ResponseInner> mapFromJson(dynamic json) {
    final map = <String, NotesGetInternalSharedUsers200ResponseInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesGetInternalSharedUsers200ResponseInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesGetInternalSharedUsers200ResponseInner-objects as value to a dart map
  static Map<String, List<NotesGetInternalSharedUsers200ResponseInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesGetInternalSharedUsers200ResponseInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesGetInternalSharedUsers200ResponseInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'nickname',
    'image',
    'loginType',
    'canEdit',
  };
}


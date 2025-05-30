//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesList200ResponseInnerOwner {
  /// Returns a new [NotesList200ResponseInnerOwner] instance.
  NotesList200ResponseInnerOwner({
    required this.id,
    required this.name,
    required this.nickname,
    required this.image,
  });

  num id;

  String name;

  String nickname;

  String image;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesList200ResponseInnerOwner &&
    other.id == id &&
    other.name == name &&
    other.nickname == nickname &&
    other.image == image;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (nickname.hashCode) +
    (image.hashCode);

  @override
  String toString() => 'NotesList200ResponseInnerOwner[id=$id, name=$name, nickname=$nickname, image=$image]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'nickname'] = this.nickname;
      json[r'image'] = this.image;
    return json;
  }

  /// Returns a new [NotesList200ResponseInnerOwner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesList200ResponseInnerOwner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesList200ResponseInnerOwner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesList200ResponseInnerOwner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesList200ResponseInnerOwner(
        id: num.parse('${json[r'id']}'),
        name: mapValueOfType<String>(json, r'name')!,
        nickname: mapValueOfType<String>(json, r'nickname')!,
        image: mapValueOfType<String>(json, r'image')!,
      );
    }
    return null;
  }

  static List<NotesList200ResponseInnerOwner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesList200ResponseInnerOwner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesList200ResponseInnerOwner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesList200ResponseInnerOwner> mapFromJson(dynamic json) {
    final map = <String, NotesList200ResponseInnerOwner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesList200ResponseInnerOwner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesList200ResponseInnerOwner-objects as value to a dart map
  static Map<String, List<NotesList200ResponseInnerOwner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesList200ResponseInnerOwner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesList200ResponseInnerOwner.listFromJson(entry.value, growable: growable,);
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
  };
}


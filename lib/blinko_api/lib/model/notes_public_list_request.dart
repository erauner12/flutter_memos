//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesPublicListRequest {
  /// Returns a new [NotesPublicListRequest] instance.
  NotesPublicListRequest({
    this.page = 1,
    this.size = 30,
    this.searchText = '',
  });

  num page;

  num size;

  String searchText;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesPublicListRequest &&
    other.page == page &&
    other.size == size &&
    other.searchText == searchText;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (page.hashCode) +
    (size.hashCode) +
    (searchText.hashCode);

  @override
  String toString() => 'NotesPublicListRequest[page=$page, size=$size, searchText=$searchText]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'page'] = this.page;
      json[r'size'] = this.size;
      json[r'searchText'] = this.searchText;
    return json;
  }

  /// Returns a new [NotesPublicListRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesPublicListRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesPublicListRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesPublicListRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesPublicListRequest(
        page: num.parse('${json[r'page']}'),
        size: num.parse('${json[r'size']}'),
        searchText: mapValueOfType<String>(json, r'searchText') ?? '',
      );
    }
    return null;
  }

  static List<NotesPublicListRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesPublicListRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesPublicListRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesPublicListRequest> mapFromJson(dynamic json) {
    final map = <String, NotesPublicListRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesPublicListRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesPublicListRequest-objects as value to a dart map
  static Map<String, List<NotesPublicListRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesPublicListRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesPublicListRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


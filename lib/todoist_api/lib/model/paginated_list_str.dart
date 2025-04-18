//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PaginatedListStr {
  /// Returns a new [PaginatedListStr] instance.
  PaginatedListStr({
    this.results = const [],
    required this.nextCursor,
  });

  List<String> results;

  String? nextCursor;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PaginatedListStr &&
    _deepEquality.equals(other.results, results) &&
    other.nextCursor == nextCursor;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (results.hashCode) +
    (nextCursor == null ? 0 : nextCursor!.hashCode);

  @override
  String toString() => 'PaginatedListStr[results=$results, nextCursor=$nextCursor]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'results'] = this.results;
    if (this.nextCursor != null) {
      json[r'next_cursor'] = this.nextCursor;
    } else {
      json[r'next_cursor'] = null;
    }
    return json;
  }

  /// Returns a new [PaginatedListStr] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PaginatedListStr? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PaginatedListStr[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PaginatedListStr[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PaginatedListStr(
        results: json[r'results'] is Iterable
            ? (json[r'results'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        nextCursor: mapValueOfType<String>(json, r'next_cursor'),
      );
    }
    return null;
  }

  static List<PaginatedListStr> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaginatedListStr>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaginatedListStr.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PaginatedListStr> mapFromJson(dynamic json) {
    final map = <String, PaginatedListStr>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PaginatedListStr.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PaginatedListStr-objects as value to a dart map
  static Map<String, List<PaginatedListStr>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PaginatedListStr>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PaginatedListStr.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'results',
    'next_cursor',
  };
}


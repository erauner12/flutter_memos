//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PaginatedListLabelRestView {
  /// Returns a new [PaginatedListLabelRestView] instance.
  PaginatedListLabelRestView({
    this.results = const [],
    required this.nextCursor,
  });

  List<LabelRestView> results;

  String? nextCursor;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PaginatedListLabelRestView &&
    _deepEquality.equals(other.results, results) &&
    other.nextCursor == nextCursor;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (results.hashCode) +
    (nextCursor == null ? 0 : nextCursor!.hashCode);

  @override
  String toString() => 'PaginatedListLabelRestView[results=$results, nextCursor=$nextCursor]';

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

  /// Returns a new [PaginatedListLabelRestView] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PaginatedListLabelRestView? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PaginatedListLabelRestView[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PaginatedListLabelRestView[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PaginatedListLabelRestView(
        results: LabelRestView.listFromJson(json[r'results']),
        nextCursor: mapValueOfType<String>(json, r'next_cursor'),
      );
    }
    return null;
  }

  static List<PaginatedListLabelRestView> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaginatedListLabelRestView>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaginatedListLabelRestView.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PaginatedListLabelRestView> mapFromJson(dynamic json) {
    final map = <String, PaginatedListLabelRestView>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PaginatedListLabelRestView.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PaginatedListLabelRestView-objects as value to a dart map
  static Map<String, List<PaginatedListLabelRestView>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PaginatedListLabelRestView>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PaginatedListLabelRestView.listFromJson(entry.value, growable: growable,);
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


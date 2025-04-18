//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CommentsList200Response {
  /// Returns a new [CommentsList200Response] instance.
  CommentsList200Response({
    required this.total,
    this.items = const [],
  });

  num total;

  List<CommentsList200ResponseItemsInner> items;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CommentsList200Response &&
    other.total == total &&
    _deepEquality.equals(other.items, items);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (total.hashCode) +
    (items.hashCode);

  @override
  String toString() => 'CommentsList200Response[total=$total, items=$items]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'total'] = this.total;
      json[r'items'] = this.items;
    return json;
  }

  /// Returns a new [CommentsList200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CommentsList200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CommentsList200Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CommentsList200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CommentsList200Response(
        total: num.parse('${json[r'total']}'),
        items: CommentsList200ResponseItemsInner.listFromJson(json[r'items']),
      );
    }
    return null;
  }

  static List<CommentsList200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CommentsList200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CommentsList200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CommentsList200Response> mapFromJson(dynamic json) {
    final map = <String, CommentsList200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CommentsList200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CommentsList200Response-objects as value to a dart map
  static Map<String, List<CommentsList200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CommentsList200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CommentsList200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'total',
    'items',
  };
}


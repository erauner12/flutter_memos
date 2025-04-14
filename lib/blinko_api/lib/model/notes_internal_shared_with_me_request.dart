//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesInternalSharedWithMeRequest {
  /// Returns a new [NotesInternalSharedWithMeRequest] instance.
  NotesInternalSharedWithMeRequest({
    this.page = 1,
    this.size = 30,
    this.orderBy = const NotesInternalSharedWithMeRequestOrderByEnum._('desc'),
  });

  num page;

  num size;

  NotesInternalSharedWithMeRequestOrderByEnum orderBy;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesInternalSharedWithMeRequest &&
    other.page == page &&
    other.size == size &&
    other.orderBy == orderBy;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (page.hashCode) +
    (size.hashCode) +
    (orderBy.hashCode);

  @override
  String toString() => 'NotesInternalSharedWithMeRequest[page=$page, size=$size, orderBy=$orderBy]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'page'] = this.page;
      json[r'size'] = this.size;
      json[r'orderBy'] = this.orderBy;
    return json;
  }

  /// Returns a new [NotesInternalSharedWithMeRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesInternalSharedWithMeRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesInternalSharedWithMeRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesInternalSharedWithMeRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesInternalSharedWithMeRequest(
        page: num.parse('${json[r'page']}'),
        size: num.parse('${json[r'size']}'),
        orderBy: NotesInternalSharedWithMeRequestOrderByEnum.fromJson(json[r'orderBy']) ?? 'desc',
      );
    }
    return null;
  }

  static List<NotesInternalSharedWithMeRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesInternalSharedWithMeRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesInternalSharedWithMeRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesInternalSharedWithMeRequest> mapFromJson(dynamic json) {
    final map = <String, NotesInternalSharedWithMeRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesInternalSharedWithMeRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesInternalSharedWithMeRequest-objects as value to a dart map
  static Map<String, List<NotesInternalSharedWithMeRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesInternalSharedWithMeRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesInternalSharedWithMeRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class NotesInternalSharedWithMeRequestOrderByEnum {
  /// Instantiate a new enum with the provided [value].
  const NotesInternalSharedWithMeRequestOrderByEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const asc = NotesInternalSharedWithMeRequestOrderByEnum._(r'asc');
  static const desc = NotesInternalSharedWithMeRequestOrderByEnum._(r'desc');

  /// List of all possible values in this [enum][NotesInternalSharedWithMeRequestOrderByEnum].
  static const values = <NotesInternalSharedWithMeRequestOrderByEnum>[
    asc,
    desc,
  ];

  static NotesInternalSharedWithMeRequestOrderByEnum? fromJson(dynamic value) => NotesInternalSharedWithMeRequestOrderByEnumTypeTransformer().decode(value);

  static List<NotesInternalSharedWithMeRequestOrderByEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesInternalSharedWithMeRequestOrderByEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesInternalSharedWithMeRequestOrderByEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NotesInternalSharedWithMeRequestOrderByEnum] to String,
/// and [decode] dynamic data back to [NotesInternalSharedWithMeRequestOrderByEnum].
class NotesInternalSharedWithMeRequestOrderByEnumTypeTransformer {
  factory NotesInternalSharedWithMeRequestOrderByEnumTypeTransformer() => _instance ??= const NotesInternalSharedWithMeRequestOrderByEnumTypeTransformer._();

  const NotesInternalSharedWithMeRequestOrderByEnumTypeTransformer._();

  String encode(NotesInternalSharedWithMeRequestOrderByEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a NotesInternalSharedWithMeRequestOrderByEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NotesInternalSharedWithMeRequestOrderByEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'asc': return NotesInternalSharedWithMeRequestOrderByEnum.asc;
        case r'desc': return NotesInternalSharedWithMeRequestOrderByEnum.desc;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [NotesInternalSharedWithMeRequestOrderByEnumTypeTransformer] instance.
  static NotesInternalSharedWithMeRequestOrderByEnumTypeTransformer? _instance;
}



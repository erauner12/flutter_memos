//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CommentsListRequest {
  /// Returns a new [CommentsListRequest] instance.
  CommentsListRequest({
    required this.noteId,
    this.page = 1,
    this.size = 20,
    this.orderBy = const CommentsListRequestOrderByEnum._('desc'),
  });

  num noteId;

  num page;

  num size;

  CommentsListRequestOrderByEnum orderBy;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CommentsListRequest &&
    other.noteId == noteId &&
    other.page == page &&
    other.size == size &&
    other.orderBy == orderBy;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (noteId.hashCode) +
    (page.hashCode) +
    (size.hashCode) +
    (orderBy.hashCode);

  @override
  String toString() => 'CommentsListRequest[noteId=$noteId, page=$page, size=$size, orderBy=$orderBy]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'noteId'] = this.noteId;
      json[r'page'] = this.page;
      json[r'size'] = this.size;
      json[r'orderBy'] = this.orderBy;
    return json;
  }

  /// Returns a new [CommentsListRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CommentsListRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CommentsListRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CommentsListRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CommentsListRequest(
        noteId: num.parse('${json[r'noteId']}'),
        page: num.parse('${json[r'page']}'),
        size: num.parse('${json[r'size']}'),
        orderBy: CommentsListRequestOrderByEnum.fromJson(json[r'orderBy']) ?? 'desc',
      );
    }
    return null;
  }

  static List<CommentsListRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CommentsListRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CommentsListRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CommentsListRequest> mapFromJson(dynamic json) {
    final map = <String, CommentsListRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CommentsListRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CommentsListRequest-objects as value to a dart map
  static Map<String, List<CommentsListRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CommentsListRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CommentsListRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'noteId',
  };
}


class CommentsListRequestOrderByEnum {
  /// Instantiate a new enum with the provided [value].
  const CommentsListRequestOrderByEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const asc = CommentsListRequestOrderByEnum._(r'asc');
  static const desc = CommentsListRequestOrderByEnum._(r'desc');

  /// List of all possible values in this [enum][CommentsListRequestOrderByEnum].
  static const values = <CommentsListRequestOrderByEnum>[
    asc,
    desc,
  ];

  static CommentsListRequestOrderByEnum? fromJson(dynamic value) => CommentsListRequestOrderByEnumTypeTransformer().decode(value);

  static List<CommentsListRequestOrderByEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CommentsListRequestOrderByEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CommentsListRequestOrderByEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CommentsListRequestOrderByEnum] to String,
/// and [decode] dynamic data back to [CommentsListRequestOrderByEnum].
class CommentsListRequestOrderByEnumTypeTransformer {
  factory CommentsListRequestOrderByEnumTypeTransformer() => _instance ??= const CommentsListRequestOrderByEnumTypeTransformer._();

  const CommentsListRequestOrderByEnumTypeTransformer._();

  String encode(CommentsListRequestOrderByEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a CommentsListRequestOrderByEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CommentsListRequestOrderByEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'asc': return CommentsListRequestOrderByEnum.asc;
        case r'desc': return CommentsListRequestOrderByEnum.desc;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [CommentsListRequestOrderByEnumTypeTransformer] instance.
  static CommentsListRequestOrderByEnumTypeTransformer? _instance;
}



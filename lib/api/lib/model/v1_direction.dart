//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class V1Direction {
  /// Instantiate a new enum with the provided [value].
  const V1Direction._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const DIRECTION_UNSPECIFIED = V1Direction._(r'DIRECTION_UNSPECIFIED');
  static const ASC = V1Direction._(r'ASC');
  static const DESC = V1Direction._(r'DESC');

  /// List of all possible values in this [enum][V1Direction].
  static const values = <V1Direction>[
    DIRECTION_UNSPECIFIED,
    ASC,
    DESC,
  ];

  static V1Direction? fromJson(dynamic value) => V1DirectionTypeTransformer().decode(value);

  static List<V1Direction> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1Direction>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1Direction.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [V1Direction] to String,
/// and [decode] dynamic data back to [V1Direction].
class V1DirectionTypeTransformer {
  factory V1DirectionTypeTransformer() => _instance ??= const V1DirectionTypeTransformer._();

  const V1DirectionTypeTransformer._();

  String encode(V1Direction data) => data.value;

  /// Decodes a [dynamic value][data] to a V1Direction.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  V1Direction? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'DIRECTION_UNSPECIFIED': return V1Direction.DIRECTION_UNSPECIFIED;
        case r'ASC': return V1Direction.ASC;
        case r'DESC': return V1Direction.DESC;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [V1DirectionTypeTransformer] instance.
  static V1DirectionTypeTransformer? _instance;
}


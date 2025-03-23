//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class V1State {
  /// Instantiate a new enum with the provided [value].
  const V1State._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const STATE_UNSPECIFIED = V1State._(r'STATE_UNSPECIFIED');
  static const NORMAL = V1State._(r'NORMAL');
  static const ARCHIVED = V1State._(r'ARCHIVED');

  /// List of all possible values in this [enum][V1State].
  static const values = <V1State>[
    STATE_UNSPECIFIED,
    NORMAL,
    ARCHIVED,
  ];

  static V1State? fromJson(dynamic value) => V1StateTypeTransformer().decode(value);

  static List<V1State> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1State>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1State.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [V1State] to String,
/// and [decode] dynamic data back to [V1State].
class V1StateTypeTransformer {
  factory V1StateTypeTransformer() => _instance ??= const V1StateTypeTransformer._();

  const V1StateTypeTransformer._();

  String encode(V1State data) => data.value;

  /// Decodes a [dynamic value][data] to a V1State.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  V1State? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'STATE_UNSPECIFIED': return V1State.STATE_UNSPECIFIED;
        case r'NORMAL': return V1State.NORMAL;
        case r'ARCHIVED': return V1State.ARCHIVED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [V1StateTypeTransformer] instance.
  static V1StateTypeTransformer? _instance;
}


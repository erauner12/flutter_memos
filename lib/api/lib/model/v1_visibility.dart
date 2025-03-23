//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class V1Visibility {
  /// Instantiate a new enum with the provided [value].
  const V1Visibility._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const VISIBILITY_UNSPECIFIED = V1Visibility._(r'VISIBILITY_UNSPECIFIED');
  static const PRIVATE = V1Visibility._(r'PRIVATE');
  static const PROTECTED = V1Visibility._(r'PROTECTED');
  static const PUBLIC = V1Visibility._(r'PUBLIC');

  /// List of all possible values in this [enum][V1Visibility].
  static const values = <V1Visibility>[
    VISIBILITY_UNSPECIFIED,
    PRIVATE,
    PROTECTED,
    PUBLIC,
  ];

  static V1Visibility? fromJson(dynamic value) => V1VisibilityTypeTransformer().decode(value);

  static List<V1Visibility> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1Visibility>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1Visibility.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [V1Visibility] to String,
/// and [decode] dynamic data back to [V1Visibility].
class V1VisibilityTypeTransformer {
  factory V1VisibilityTypeTransformer() => _instance ??= const V1VisibilityTypeTransformer._();

  const V1VisibilityTypeTransformer._();

  String encode(V1Visibility data) => data.value;

  /// Decodes a [dynamic value][data] to a V1Visibility.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  V1Visibility? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'VISIBILITY_UNSPECIFIED': return V1Visibility.VISIBILITY_UNSPECIFIED;
        case r'PRIVATE': return V1Visibility.PRIVATE;
        case r'PROTECTED': return V1Visibility.PROTECTED;
        case r'PUBLIC': return V1Visibility.PUBLIC;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [V1VisibilityTypeTransformer] instance.
  static V1VisibilityTypeTransformer? _instance;
}


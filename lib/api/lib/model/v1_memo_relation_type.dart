//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class V1MemoRelationType {
  /// Instantiate a new enum with the provided [value].
  const V1MemoRelationType._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const TYPE_UNSPECIFIED = V1MemoRelationType._(r'TYPE_UNSPECIFIED');
  static const REFERENCE = V1MemoRelationType._(r'REFERENCE');
  static const COMMENT = V1MemoRelationType._(r'COMMENT');

  /// List of all possible values in this [enum][V1MemoRelationType].
  static const values = <V1MemoRelationType>[
    TYPE_UNSPECIFIED,
    REFERENCE,
    COMMENT,
  ];

  static V1MemoRelationType? fromJson(dynamic value) => V1MemoRelationTypeTypeTransformer().decode(value);

  static List<V1MemoRelationType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1MemoRelationType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1MemoRelationType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [V1MemoRelationType] to String,
/// and [decode] dynamic data back to [V1MemoRelationType].
class V1MemoRelationTypeTypeTransformer {
  factory V1MemoRelationTypeTypeTransformer() => _instance ??= const V1MemoRelationTypeTypeTransformer._();

  const V1MemoRelationTypeTypeTransformer._();

  String encode(V1MemoRelationType data) => data.value;

  /// Decodes a [dynamic value][data] to a V1MemoRelationType.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  V1MemoRelationType? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'TYPE_UNSPECIFIED': return V1MemoRelationType.TYPE_UNSPECIFIED;
        case r'REFERENCE': return V1MemoRelationType.REFERENCE;
        case r'COMMENT': return V1MemoRelationType.COMMENT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [V1MemoRelationTypeTypeTransformer] instance.
  static V1MemoRelationTypeTypeTransformer? _instance;
}


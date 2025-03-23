//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class V1InboxType {
  /// Instantiate a new enum with the provided [value].
  const V1InboxType._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const TYPE_UNSPECIFIED = V1InboxType._(r'TYPE_UNSPECIFIED');
  static const MEMO_COMMENT = V1InboxType._(r'MEMO_COMMENT');
  static const VERSION_UPDATE = V1InboxType._(r'VERSION_UPDATE');

  /// List of all possible values in this [enum][V1InboxType].
  static const values = <V1InboxType>[
    TYPE_UNSPECIFIED,
    MEMO_COMMENT,
    VERSION_UPDATE,
  ];

  static V1InboxType? fromJson(dynamic value) => V1InboxTypeTypeTransformer().decode(value);

  static List<V1InboxType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1InboxType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1InboxType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [V1InboxType] to String,
/// and [decode] dynamic data back to [V1InboxType].
class V1InboxTypeTypeTransformer {
  factory V1InboxTypeTypeTransformer() => _instance ??= const V1InboxTypeTypeTransformer._();

  const V1InboxTypeTypeTransformer._();

  String encode(V1InboxType data) => data.value;

  /// Decodes a [dynamic value][data] to a V1InboxType.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  V1InboxType? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'TYPE_UNSPECIFIED': return V1InboxType.TYPE_UNSPECIFIED;
        case r'MEMO_COMMENT': return V1InboxType.MEMO_COMMENT;
        case r'VERSION_UPDATE': return V1InboxType.VERSION_UPDATE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [V1InboxTypeTypeTransformer] instance.
  static V1InboxTypeTypeTransformer? _instance;
}


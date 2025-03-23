//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class V1InboxStatus {
  /// Instantiate a new enum with the provided [value].
  const V1InboxStatus._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const STATUS_UNSPECIFIED = V1InboxStatus._(r'STATUS_UNSPECIFIED');
  static const UNREAD = V1InboxStatus._(r'UNREAD');
  static const ARCHIVED = V1InboxStatus._(r'ARCHIVED');

  /// List of all possible values in this [enum][V1InboxStatus].
  static const values = <V1InboxStatus>[
    STATUS_UNSPECIFIED,
    UNREAD,
    ARCHIVED,
  ];

  static V1InboxStatus? fromJson(dynamic value) => V1InboxStatusTypeTransformer().decode(value);

  static List<V1InboxStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1InboxStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1InboxStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [V1InboxStatus] to String,
/// and [decode] dynamic data back to [V1InboxStatus].
class V1InboxStatusTypeTransformer {
  factory V1InboxStatusTypeTransformer() => _instance ??= const V1InboxStatusTypeTransformer._();

  const V1InboxStatusTypeTransformer._();

  String encode(V1InboxStatus data) => data.value;

  /// Decodes a [dynamic value][data] to a V1InboxStatus.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  V1InboxStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'STATUS_UNSPECIFIED': return V1InboxStatus.STATUS_UNSPECIFIED;
        case r'UNREAD': return V1InboxStatus.UNREAD;
        case r'ARCHIVED': return V1InboxStatus.ARCHIVED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [V1InboxStatusTypeTransformer] instance.
  static V1InboxStatusTypeTransformer? _instance;
}


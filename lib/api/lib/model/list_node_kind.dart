//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ListNodeKind {
  /// Instantiate a new enum with the provided [value].
  const ListNodeKind._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const KIND_UNSPECIFIED = ListNodeKind._(r'KIND_UNSPECIFIED');
  static const ORDERED = ListNodeKind._(r'ORDERED');
  static const UNORDERED = ListNodeKind._(r'UNORDERED');
  static const DESCRIPTION = ListNodeKind._(r'DESCRIPTION');

  /// List of all possible values in this [enum][ListNodeKind].
  static const values = <ListNodeKind>[
    KIND_UNSPECIFIED,
    ORDERED,
    UNORDERED,
    DESCRIPTION,
  ];

  static ListNodeKind? fromJson(dynamic value) => ListNodeKindTypeTransformer().decode(value);

  static List<ListNodeKind> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListNodeKind>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListNodeKind.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ListNodeKind] to String,
/// and [decode] dynamic data back to [ListNodeKind].
class ListNodeKindTypeTransformer {
  factory ListNodeKindTypeTransformer() => _instance ??= const ListNodeKindTypeTransformer._();

  const ListNodeKindTypeTransformer._();

  String encode(ListNodeKind data) => data.value;

  /// Decodes a [dynamic value][data] to a ListNodeKind.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ListNodeKind? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'KIND_UNSPECIFIED': return ListNodeKind.KIND_UNSPECIFIED;
        case r'ORDERED': return ListNodeKind.ORDERED;
        case r'UNORDERED': return ListNodeKind.UNORDERED;
        case r'DESCRIPTION': return ListNodeKind.DESCRIPTION;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ListNodeKindTypeTransformer] instance.
  static ListNodeKindTypeTransformer? _instance;
}


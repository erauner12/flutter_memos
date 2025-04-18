//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// Undefined object  The object is used as a default argument in some constructors to differentiate from `None` which usually means in that context \"reset the value\".  - Use the `parts.util.undefined` singleton for the default variable. - Use `is undefined` to see if value is undefined. - For type hints, use `YourType | Undefined`  Usage example:  ```     from parts.util import Undefined, undefined      def update_item(         id: int,         title: str | Undefined = undefined,         content: str | Undefined = undefined,     ):         pass ```
class Undefined {
  /// Instantiate a new enum with the provided [value].
  const Undefined._(this.value);

  /// The underlying value of this enum member.
  final int value;

  @override
  String toString() => value.toString();

  int toJson() => value;

  static const number0 = Undefined._(0);

  /// List of all possible values in this [enum][Undefined].
  static const values = <Undefined>[
    number0,
  ];

  static Undefined? fromJson(dynamic value) => UndefinedTypeTransformer().decode(value);

  static List<Undefined> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Undefined>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Undefined.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [Undefined] to int,
/// and [decode] dynamic data back to [Undefined].
class UndefinedTypeTransformer {
  factory UndefinedTypeTransformer() => _instance ??= const UndefinedTypeTransformer._();

  const UndefinedTypeTransformer._();

  int encode(Undefined data) => data.value;

  /// Decodes a [dynamic value][data] to a Undefined.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  Undefined? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case 0: return Undefined.number0;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [UndefinedTypeTransformer] instance.
  static UndefinedTypeTransformer? _instance;
}


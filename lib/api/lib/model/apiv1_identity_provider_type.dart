//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class Apiv1IdentityProviderType {
  /// Instantiate a new enum with the provided [value].
  const Apiv1IdentityProviderType._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const TYPE_UNSPECIFIED = Apiv1IdentityProviderType._(r'TYPE_UNSPECIFIED');
  static const oAUTH2 = Apiv1IdentityProviderType._(r'OAUTH2');

  /// List of all possible values in this [enum][Apiv1IdentityProviderType].
  static const values = <Apiv1IdentityProviderType>[
    TYPE_UNSPECIFIED,
    oAUTH2,
  ];

  static Apiv1IdentityProviderType? fromJson(dynamic value) => Apiv1IdentityProviderTypeTypeTransformer().decode(value);

  static List<Apiv1IdentityProviderType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Apiv1IdentityProviderType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Apiv1IdentityProviderType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [Apiv1IdentityProviderType] to String,
/// and [decode] dynamic data back to [Apiv1IdentityProviderType].
class Apiv1IdentityProviderTypeTypeTransformer {
  factory Apiv1IdentityProviderTypeTypeTransformer() => _instance ??= const Apiv1IdentityProviderTypeTypeTransformer._();

  const Apiv1IdentityProviderTypeTypeTransformer._();

  String encode(Apiv1IdentityProviderType data) => data.value;

  /// Decodes a [dynamic value][data] to a Apiv1IdentityProviderType.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  Apiv1IdentityProviderType? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'TYPE_UNSPECIFIED': return Apiv1IdentityProviderType.TYPE_UNSPECIFIED;
        case r'OAUTH2': return Apiv1IdentityProviderType.oAUTH2;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [Apiv1IdentityProviderTypeTypeTransformer] instance.
  static Apiv1IdentityProviderTypeTypeTransformer? _instance;
}


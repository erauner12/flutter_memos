//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

///  - DATABASE: DATABASE is the database storage type.  - LOCAL: LOCAL is the local storage type.  - S3: S3 is the S3 storage type.
class Apiv1WorkspaceStorageSettingStorageType {
  /// Instantiate a new enum with the provided [value].
  const Apiv1WorkspaceStorageSettingStorageType._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const STORAGE_TYPE_UNSPECIFIED = Apiv1WorkspaceStorageSettingStorageType._(r'STORAGE_TYPE_UNSPECIFIED');
  static const DATABASE = Apiv1WorkspaceStorageSettingStorageType._(r'DATABASE');
  static const LOCAL = Apiv1WorkspaceStorageSettingStorageType._(r'LOCAL');
  static const s3 = Apiv1WorkspaceStorageSettingStorageType._(r'S3');

  /// List of all possible values in this [enum][Apiv1WorkspaceStorageSettingStorageType].
  static const values = <Apiv1WorkspaceStorageSettingStorageType>[
    STORAGE_TYPE_UNSPECIFIED,
    DATABASE,
    LOCAL,
    s3,
  ];

  static Apiv1WorkspaceStorageSettingStorageType? fromJson(dynamic value) => Apiv1WorkspaceStorageSettingStorageTypeTypeTransformer().decode(value);

  static List<Apiv1WorkspaceStorageSettingStorageType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Apiv1WorkspaceStorageSettingStorageType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Apiv1WorkspaceStorageSettingStorageType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [Apiv1WorkspaceStorageSettingStorageType] to String,
/// and [decode] dynamic data back to [Apiv1WorkspaceStorageSettingStorageType].
class Apiv1WorkspaceStorageSettingStorageTypeTypeTransformer {
  factory Apiv1WorkspaceStorageSettingStorageTypeTypeTransformer() => _instance ??= const Apiv1WorkspaceStorageSettingStorageTypeTypeTransformer._();

  const Apiv1WorkspaceStorageSettingStorageTypeTypeTransformer._();

  String encode(Apiv1WorkspaceStorageSettingStorageType data) => data.value;

  /// Decodes a [dynamic value][data] to a Apiv1WorkspaceStorageSettingStorageType.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  Apiv1WorkspaceStorageSettingStorageType? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'STORAGE_TYPE_UNSPECIFIED': return Apiv1WorkspaceStorageSettingStorageType.STORAGE_TYPE_UNSPECIFIED;
        case r'DATABASE': return Apiv1WorkspaceStorageSettingStorageType.DATABASE;
        case r'LOCAL': return Apiv1WorkspaceStorageSettingStorageType.LOCAL;
        case r'S3': return Apiv1WorkspaceStorageSettingStorageType.s3;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [Apiv1WorkspaceStorageSettingStorageTypeTypeTransformer] instance.
  static Apiv1WorkspaceStorageSettingStorageTypeTypeTransformer? _instance;
}


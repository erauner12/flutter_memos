//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// User role in the project. For personal project the role should be always \"CREATOR\" User role for projects v1 maybe specified as \"CREATOR\" or \"ADMIN\", because in the past there was no permissions.
class CollaboratorRole {
  /// Instantiate a new enum with the provided [value].
  const CollaboratorRole._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const CREATOR = CollaboratorRole._(r'CREATOR');
  static const ADMIN = CollaboratorRole._(r'ADMIN');
  static const READ_WRITE = CollaboratorRole._(r'READ_WRITE');
  static const READ_AND_COMMENT = CollaboratorRole._(r'READ_AND_COMMENT');
  static const READ_ONLY = CollaboratorRole._(r'READ_ONLY');

  /// List of all possible values in this [enum][CollaboratorRole].
  static const values = <CollaboratorRole>[
    CREATOR,
    ADMIN,
    READ_WRITE,
    READ_AND_COMMENT,
    READ_ONLY,
  ];

  static CollaboratorRole? fromJson(dynamic value) => CollaboratorRoleTypeTransformer().decode(value);

  static List<CollaboratorRole> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CollaboratorRole>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CollaboratorRole.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CollaboratorRole] to String,
/// and [decode] dynamic data back to [CollaboratorRole].
class CollaboratorRoleTypeTransformer {
  factory CollaboratorRoleTypeTransformer() => _instance ??= const CollaboratorRoleTypeTransformer._();

  const CollaboratorRoleTypeTransformer._();

  String encode(CollaboratorRole data) => data.value;

  /// Decodes a [dynamic value][data] to a CollaboratorRole.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CollaboratorRole? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'CREATOR': return CollaboratorRole.CREATOR;
        case r'ADMIN': return CollaboratorRole.ADMIN;
        case r'READ_WRITE': return CollaboratorRole.READ_WRITE;
        case r'READ_AND_COMMENT': return CollaboratorRole.READ_AND_COMMENT;
        case r'READ_ONLY': return CollaboratorRole.READ_ONLY;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [CollaboratorRoleTypeTransformer] instance.
  static CollaboratorRoleTypeTransformer? _instance;
}


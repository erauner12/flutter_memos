//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// Role of the user inside the workspace
class WorkspaceRole {
  /// Instantiate a new enum with the provided [value].
  const WorkspaceRole._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const ADMIN = WorkspaceRole._(r'ADMIN');
  static const MEMBER = WorkspaceRole._(r'MEMBER');
  static const GUEST = WorkspaceRole._(r'GUEST');

  /// List of all possible values in this [enum][WorkspaceRole].
  static const values = <WorkspaceRole>[
    ADMIN,
    MEMBER,
    GUEST,
  ];

  static WorkspaceRole? fromJson(dynamic value) => WorkspaceRoleTypeTransformer().decode(value);

  static List<WorkspaceRole> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkspaceRole>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkspaceRole.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [WorkspaceRole] to String,
/// and [decode] dynamic data back to [WorkspaceRole].
class WorkspaceRoleTypeTransformer {
  factory WorkspaceRoleTypeTransformer() => _instance ??= const WorkspaceRoleTypeTransformer._();

  const WorkspaceRoleTypeTransformer._();

  String encode(WorkspaceRole data) => data.value;

  /// Decodes a [dynamic value][data] to a WorkspaceRole.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  WorkspaceRole? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'ADMIN': return WorkspaceRole.ADMIN;
        case r'MEMBER': return WorkspaceRole.MEMBER;
        case r'GUEST': return WorkspaceRole.GUEST;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [WorkspaceRoleTypeTransformer] instance.
  static WorkspaceRoleTypeTransformer? _instance;
}


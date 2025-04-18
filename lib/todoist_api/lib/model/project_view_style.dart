//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ProjectViewStyle {
  /// Instantiate a new enum with the provided [value].
  const ProjectViewStyle._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const LIST = ProjectViewStyle._(r'LIST');
  static const BOARD = ProjectViewStyle._(r'BOARD');
  static const CALENDAR = ProjectViewStyle._(r'CALENDAR');

  /// List of all possible values in this [enum][ProjectViewStyle].
  static const values = <ProjectViewStyle>[
    LIST,
    BOARD,
    CALENDAR,
  ];

  static ProjectViewStyle? fromJson(dynamic value) => ProjectViewStyleTypeTransformer().decode(value);

  static List<ProjectViewStyle> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ProjectViewStyle>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProjectViewStyle.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ProjectViewStyle] to String,
/// and [decode] dynamic data back to [ProjectViewStyle].
class ProjectViewStyleTypeTransformer {
  factory ProjectViewStyleTypeTransformer() => _instance ??= const ProjectViewStyleTypeTransformer._();

  const ProjectViewStyleTypeTransformer._();

  String encode(ProjectViewStyle data) => data.value;

  /// Decodes a [dynamic value][data] to a ProjectViewStyle.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ProjectViewStyle? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'LIST': return ProjectViewStyle.LIST;
        case r'BOARD': return ProjectViewStyle.BOARD;
        case r'CALENDAR': return ProjectViewStyle.CALENDAR;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ProjectViewStyleTypeTransformer] instance.
  static ProjectViewStyleTypeTransformer? _instance;
}


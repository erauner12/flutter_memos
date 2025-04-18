//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// Project status.  At the moment, this is for workspace projects only.
class ProjectStatus {
  /// Instantiate a new enum with the provided [value].
  const ProjectStatus._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PLANNED = ProjectStatus._(r'PLANNED');
  static const IN_PROGRESS = ProjectStatus._(r'IN_PROGRESS');
  static const PAUSED = ProjectStatus._(r'PAUSED');
  static const COMPLETED = ProjectStatus._(r'COMPLETED');
  static const CANCELED = ProjectStatus._(r'CANCELED');

  /// List of all possible values in this [enum][ProjectStatus].
  static const values = <ProjectStatus>[
    PLANNED,
    IN_PROGRESS,
    PAUSED,
    COMPLETED,
    CANCELED,
  ];

  static ProjectStatus? fromJson(dynamic value) => ProjectStatusTypeTransformer().decode(value);

  static List<ProjectStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ProjectStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProjectStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ProjectStatus] to String,
/// and [decode] dynamic data back to [ProjectStatus].
class ProjectStatusTypeTransformer {
  factory ProjectStatusTypeTransformer() => _instance ??= const ProjectStatusTypeTransformer._();

  const ProjectStatusTypeTransformer._();

  String encode(ProjectStatus data) => data.value;

  /// Decodes a [dynamic value][data] to a ProjectStatus.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ProjectStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PLANNED': return ProjectStatus.PLANNED;
        case r'IN_PROGRESS': return ProjectStatus.IN_PROGRESS;
        case r'PAUSED': return ProjectStatus.PAUSED;
        case r'COMPLETED': return ProjectStatus.COMPLETED;
        case r'CANCELED': return ProjectStatus.CANCELED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ProjectStatusTypeTransformer] instance.
  static ProjectStatusTypeTransformer? _instance;
}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ProjectImportCreateResponseWithObjects {
  /// Returns a new [ProjectImportCreateResponseWithObjects] instance.
  ProjectImportCreateResponseWithObjects({
    required this.status,
    required this.projectId,
    required this.templateType,
    this.projects = const [],
    this.sections = const [],
    this.tasks = const [],
    this.comments = const [],
    this.projectNotes = const [],
  });

  ProjectImportCreateResponseWithObjectsStatusEnum status;

  String projectId;

  String templateType;

  List<Map<String, Object>> projects;

  List<Map<String, Object>> sections;

  List<Map<String, Object>> tasks;

  List<Map<String, Object>> comments;

  List<Map<String, Object>> projectNotes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ProjectImportCreateResponseWithObjects &&
    other.status == status &&
    other.projectId == projectId &&
    other.templateType == templateType &&
    _deepEquality.equals(other.projects, projects) &&
    _deepEquality.equals(other.sections, sections) &&
    _deepEquality.equals(other.tasks, tasks) &&
    _deepEquality.equals(other.comments, comments) &&
    _deepEquality.equals(other.projectNotes, projectNotes);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (status.hashCode) +
    (projectId.hashCode) +
    (templateType.hashCode) +
    (projects.hashCode) +
    (sections.hashCode) +
    (tasks.hashCode) +
    (comments.hashCode) +
    (projectNotes.hashCode);

  @override
  String toString() => 'ProjectImportCreateResponseWithObjects[status=$status, projectId=$projectId, templateType=$templateType, projects=$projects, sections=$sections, tasks=$tasks, comments=$comments, projectNotes=$projectNotes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'status'] = this.status;
      json[r'project_id'] = this.projectId;
      json[r'template_type'] = this.templateType;
      json[r'projects'] = this.projects;
      json[r'sections'] = this.sections;
      json[r'tasks'] = this.tasks;
      json[r'comments'] = this.comments;
      json[r'project_notes'] = this.projectNotes;
    return json;
  }

  /// Returns a new [ProjectImportCreateResponseWithObjects] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProjectImportCreateResponseWithObjects? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ProjectImportCreateResponseWithObjects[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ProjectImportCreateResponseWithObjects[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ProjectImportCreateResponseWithObjects(
        status: ProjectImportCreateResponseWithObjectsStatusEnum.fromJson(json[r'status'])!,
        projectId: mapValueOfType<String>(json, r'project_id')!,
        templateType: mapValueOfType<String>(json, r'template_type')!,
        projects: Map.listFromJson(json[r'projects']),
        sections: Map.listFromJson(json[r'sections']),
        tasks: Map.listFromJson(json[r'tasks']),
        comments: Map.listFromJson(json[r'comments']),
        projectNotes: Map.listFromJson(json[r'project_notes']),
      );
    }
    return null;
  }

  static List<ProjectImportCreateResponseWithObjects> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ProjectImportCreateResponseWithObjects>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProjectImportCreateResponseWithObjects.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProjectImportCreateResponseWithObjects> mapFromJson(dynamic json) {
    final map = <String, ProjectImportCreateResponseWithObjects>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProjectImportCreateResponseWithObjects.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProjectImportCreateResponseWithObjects-objects as value to a dart map
  static Map<String, List<ProjectImportCreateResponseWithObjects>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ProjectImportCreateResponseWithObjects>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProjectImportCreateResponseWithObjects.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'status',
    'project_id',
    'template_type',
    'projects',
    'sections',
    'tasks',
    'comments',
    'project_notes',
  };
}


class ProjectImportCreateResponseWithObjectsStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const ProjectImportCreateResponseWithObjectsStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const ok = ProjectImportCreateResponseWithObjectsStatusEnum._(r'ok');

  /// List of all possible values in this [enum][ProjectImportCreateResponseWithObjectsStatusEnum].
  static const values = <ProjectImportCreateResponseWithObjectsStatusEnum>[
    ok,
  ];

  static ProjectImportCreateResponseWithObjectsStatusEnum? fromJson(dynamic value) => ProjectImportCreateResponseWithObjectsStatusEnumTypeTransformer().decode(value);

  static List<ProjectImportCreateResponseWithObjectsStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ProjectImportCreateResponseWithObjectsStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProjectImportCreateResponseWithObjectsStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ProjectImportCreateResponseWithObjectsStatusEnum] to String,
/// and [decode] dynamic data back to [ProjectImportCreateResponseWithObjectsStatusEnum].
class ProjectImportCreateResponseWithObjectsStatusEnumTypeTransformer {
  factory ProjectImportCreateResponseWithObjectsStatusEnumTypeTransformer() => _instance ??= const ProjectImportCreateResponseWithObjectsStatusEnumTypeTransformer._();

  const ProjectImportCreateResponseWithObjectsStatusEnumTypeTransformer._();

  String encode(ProjectImportCreateResponseWithObjectsStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ProjectImportCreateResponseWithObjectsStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ProjectImportCreateResponseWithObjectsStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'ok': return ProjectImportCreateResponseWithObjectsStatusEnum.ok;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ProjectImportCreateResponseWithObjectsStatusEnumTypeTransformer] instance.
  static ProjectImportCreateResponseWithObjectsStatusEnumTypeTransformer? _instance;
}



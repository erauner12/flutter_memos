//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ProjectImportResponse {
  /// Returns a new [ProjectImportResponse] instance.
  ProjectImportResponse({
    required this.status,
    required this.templateType,
    this.projects = const [],
    this.sections = const [],
    this.tasks = const [],
    this.comments = const [],
    this.projectNotes = const [],
  });

  ProjectImportResponseStatusEnum status;

  String templateType;

  List<Map<String, Object>> projects;

  List<Map<String, Object>> sections;

  List<Map<String, Object>> tasks;

  List<Map<String, Object>> comments;

  List<Map<String, Object>> projectNotes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ProjectImportResponse &&
    other.status == status &&
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
    (templateType.hashCode) +
    (projects.hashCode) +
    (sections.hashCode) +
    (tasks.hashCode) +
    (comments.hashCode) +
    (projectNotes.hashCode);

  @override
  String toString() => 'ProjectImportResponse[status=$status, templateType=$templateType, projects=$projects, sections=$sections, tasks=$tasks, comments=$comments, projectNotes=$projectNotes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'status'] = this.status;
      json[r'template_type'] = this.templateType;
      json[r'projects'] = this.projects;
      json[r'sections'] = this.sections;
      json[r'tasks'] = this.tasks;
      json[r'comments'] = this.comments;
      json[r'project_notes'] = this.projectNotes;
    return json;
  }

  /// Returns a new [ProjectImportResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProjectImportResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ProjectImportResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ProjectImportResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ProjectImportResponse(
        status: ProjectImportResponseStatusEnum.fromJson(json[r'status'])!,
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

  static List<ProjectImportResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ProjectImportResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProjectImportResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProjectImportResponse> mapFromJson(dynamic json) {
    final map = <String, ProjectImportResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProjectImportResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProjectImportResponse-objects as value to a dart map
  static Map<String, List<ProjectImportResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ProjectImportResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProjectImportResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'status',
    'template_type',
    'projects',
    'sections',
    'tasks',
    'comments',
    'project_notes',
  };
}


class ProjectImportResponseStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const ProjectImportResponseStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const ok = ProjectImportResponseStatusEnum._(r'ok');

  /// List of all possible values in this [enum][ProjectImportResponseStatusEnum].
  static const values = <ProjectImportResponseStatusEnum>[
    ok,
  ];

  static ProjectImportResponseStatusEnum? fromJson(dynamic value) => ProjectImportResponseStatusEnumTypeTransformer().decode(value);

  static List<ProjectImportResponseStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ProjectImportResponseStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProjectImportResponseStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ProjectImportResponseStatusEnum] to String,
/// and [decode] dynamic data back to [ProjectImportResponseStatusEnum].
class ProjectImportResponseStatusEnumTypeTransformer {
  factory ProjectImportResponseStatusEnumTypeTransformer() => _instance ??= const ProjectImportResponseStatusEnumTypeTransformer._();

  const ProjectImportResponseStatusEnumTypeTransformer._();

  String encode(ProjectImportResponseStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ProjectImportResponseStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ProjectImportResponseStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'ok': return ProjectImportResponseStatusEnum.ok;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ProjectImportResponseStatusEnumTypeTransformer] instance.
  static ProjectImportResponseStatusEnumTypeTransformer? _instance;
}



//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ProjectsResponse {
  /// Returns a new [ProjectsResponse] instance.
  ProjectsResponse({
    required this.hasMore,
    this.nextCursor,
    this.workspaceProjects = const [],
  });

  bool hasMore;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? nextCursor;

  List<WorkspaceProjectView> workspaceProjects;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ProjectsResponse &&
    other.hasMore == hasMore &&
    other.nextCursor == nextCursor &&
    _deepEquality.equals(other.workspaceProjects, workspaceProjects);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (hasMore.hashCode) +
    (nextCursor == null ? 0 : nextCursor!.hashCode) +
    (workspaceProjects.hashCode);

  @override
  String toString() => 'ProjectsResponse[hasMore=$hasMore, nextCursor=$nextCursor, workspaceProjects=$workspaceProjects]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'has_more'] = this.hasMore;
    if (this.nextCursor != null) {
      json[r'next_cursor'] = this.nextCursor;
    } else {
      json[r'next_cursor'] = null;
    }
      json[r'workspace_projects'] = this.workspaceProjects;
    return json;
  }

  /// Returns a new [ProjectsResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProjectsResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ProjectsResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ProjectsResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ProjectsResponse(
        hasMore: mapValueOfType<bool>(json, r'has_more')!,
        nextCursor: mapValueOfType<String>(json, r'next_cursor'),
        workspaceProjects: WorkspaceProjectView.listFromJson(json[r'workspace_projects']),
      );
    }
    return null;
  }

  static List<ProjectsResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ProjectsResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProjectsResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProjectsResponse> mapFromJson(dynamic json) {
    final map = <String, ProjectsResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProjectsResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProjectsResponse-objects as value to a dart map
  static Map<String, List<ProjectsResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ProjectsResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProjectsResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'has_more',
    'workspace_projects',
  };
}


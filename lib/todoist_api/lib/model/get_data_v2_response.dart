//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GetDataV2Response {
  /// Returns a new [GetDataV2Response] instance.
  GetDataV2Response({
    this.project = const {},
    this.items = const [],
    this.sections = const [],
    this.projectNotes = const [],
    this.collaborators = const [],
    this.collaboratorStates = const [],
    this.folder, // Changed required to optional based on usage
    this.subprojects = const [],
  });

  Map<String, Object>? project;

  List<Map<String, Object>> items;

  List<Map<String, Object>> sections;

  List<Map<String, Object>> projectNotes;

  List<ExposedCollaboratorSyncView> collaborators;

  List<Map<String, Object>> collaboratorStates;

  FolderView? folder; // Made nullable

  List<Map<String, Object>> subprojects;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GetDataV2Response &&
    _deepEquality.equals(other.project, project) &&
    _deepEquality.equals(other.items, items) &&
    _deepEquality.equals(other.sections, sections) &&
    _deepEquality.equals(other.projectNotes, projectNotes) &&
    _deepEquality.equals(other.collaborators, collaborators) &&
    _deepEquality.equals(other.collaboratorStates, collaboratorStates) &&
    other.folder == folder &&
    _deepEquality.equals(other.subprojects, subprojects);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (project == null ? 0 : project!.hashCode) +
    (items.hashCode) +
    (sections.hashCode) +
    (projectNotes.hashCode) +
    (collaborators.hashCode) +
    (collaboratorStates.hashCode) +
    (folder == null ? 0 : folder!.hashCode) +
    (subprojects.hashCode);

  @override
  String toString() =>
      'GetDataV2Response[project=$project, items=${items.length}, sections=${sections.length}, projectNotes=${projectNotes.length}, collaborators=${collaborators.length}, collaboratorStates=${collaboratorStates.length}, folder=$folder, subprojects=${subprojects.length}]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.project != null) {
      json[r'project'] = this.project;
    } else {
      json[r'project'] = null;
    }
      json[r'items'] = this.items;
      json[r'sections'] = this.sections;
      json[r'project_notes'] = this.projectNotes;
    json[r'collaborators'] = this
        .collaborators
        .map((v) => v.toJson())
        .toList(); // Ensure collaborators are serialized
      json[r'collaborator_states'] = this.collaboratorStates;
    if (this.folder != null) {
      json[r'folder'] = this.folder?.toJson(); // Ensure folder is serialized
    } else {
      json[r'folder'] = null;
    }
      json[r'subprojects'] = this.subprojects;
    return json;
  }

  /// Returns a new [GetDataV2Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetDataV2Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          // Allow optional keys like 'folder'
          if (json.containsKey(key)) {
            assert(json[key] != null,
                'Required key "GetDataV2Response[$key]" has a null value in JSON.');
          } else if (!optionalKeys.contains(key)) {
            assert(false,
                'Required key "GetDataV2Response[$key]" is missing from JSON.');
          }
        });
        return true;
      }());

      // Helper function to cast list elements to Map<String, Object>
      List<Map<String, Object>> mapListFromJsonHelper(dynamic listData) {
        if (listData is List) {
          return listData.map((e) => e as Map<String, Object>).toList();
        }
        return [];
      }

      return GetDataV2Response(
        project: mapCastOfType<String, Object>(json, r'project'),
        // Use helper for list casting
        items: mapListFromJsonHelper(json[r'items']),
        sections: mapListFromJsonHelper(json[r'sections']),
        projectNotes: mapListFromJsonHelper(json[r'project_notes']),
        collaborators: ExposedCollaboratorSyncView.listFromJson(
            json[r'collaborators'] ?? []), // Keep specific type here
        collaboratorStates: mapListFromJsonHelper(json[r'collaborator_states']),
        folder: FolderView.fromJson(json[r'folder']), // Keep specific type here
        subprojects: mapListFromJsonHelper(json[r'subprojects']),
      );
    }
    return null;
  }

  static List<GetDataV2Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GetDataV2Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetDataV2Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetDataV2Response> mapFromJson(dynamic json) {
    final map = <String, GetDataV2Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetDataV2Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetDataV2Response-objects as value to a dart map
  static Map<String, List<GetDataV2Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GetDataV2Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetDataV2Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  /// Adjusted based on observed API responses or potential nullability.
  static const requiredKeys = <String>{
    // 'project', // Can be null/missing?
    // 'items', // Can be empty list
    // 'sections', // Can be empty list
    // 'project_notes', // Can be empty list
    // 'collaborators', // Can be empty list
    // 'collaborator_states', // Can be empty list
    // 'folder', // Can be null/missing
    // 'subprojects', // Can be empty list
  };

  /// List of optional keys.
  static const optionalKeys = <String>{
    'project',
    'items',
    'sections',
    'project_notes',
    'collaborators',
    'collaborator_states',
    'folder',
    'subprojects',
  };
}

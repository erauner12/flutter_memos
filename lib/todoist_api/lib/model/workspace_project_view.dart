//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class WorkspaceProjectView {
  /// Returns a new [WorkspaceProjectView] instance.
  WorkspaceProjectView({
    required this.initiatedByUid,
    required this.projectId,
    required this.workspaceId,
    this.folderId,
    this.isInviteOnly,
    this.isArchived = false,
    this.archivedTimestamp = 0,
    this.archivedDate,
    this.isFrozen = false,
    this.name = '',
    this.color,
    this.viewStyle = list,
    this.description = '',
    this.status = ProjectStatus.IN_PROGRESS,
    this.defaultOrder = 0,
    this.v1Id,
    this.role,
  });

  int initiatedByUid;

  String projectId;

  int workspaceId;

  int? folderId;

  bool? isInviteOnly;

  bool isArchived;

  int archivedTimestamp;

  DateTime? archivedDate;

  bool isFrozen;

  String name;

  int? color;

  ProjectViewStyle viewStyle;

  String description;

  ProjectStatus status;

  int defaultOrder;

  int? v1Id;

  Role? role;

  @override
  bool operator ==(Object other) => identical(this, other) || other is WorkspaceProjectView &&
    other.initiatedByUid == initiatedByUid &&
    other.projectId == projectId &&
    other.workspaceId == workspaceId &&
    other.folderId == folderId &&
    other.isInviteOnly == isInviteOnly &&
    other.isArchived == isArchived &&
    other.archivedTimestamp == archivedTimestamp &&
    other.archivedDate == archivedDate &&
    other.isFrozen == isFrozen &&
    other.name == name &&
    other.color == color &&
    other.viewStyle == viewStyle &&
    other.description == description &&
    other.status == status &&
    other.defaultOrder == defaultOrder &&
    other.v1Id == v1Id &&
    other.role == role;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (initiatedByUid.hashCode) +
    (projectId.hashCode) +
    (workspaceId.hashCode) +
    (folderId == null ? 0 : folderId!.hashCode) +
    (isInviteOnly == null ? 0 : isInviteOnly!.hashCode) +
    (isArchived.hashCode) +
    (archivedTimestamp.hashCode) +
    (archivedDate == null ? 0 : archivedDate!.hashCode) +
    (isFrozen.hashCode) +
    (name.hashCode) +
    (color == null ? 0 : color!.hashCode) +
    (viewStyle.hashCode) +
    (description.hashCode) +
    (status.hashCode) +
    (defaultOrder.hashCode) +
    (v1Id == null ? 0 : v1Id!.hashCode) +
    (role == null ? 0 : role!.hashCode);

  @override
  String toString() => 'WorkspaceProjectView[initiatedByUid=$initiatedByUid, projectId=$projectId, workspaceId=$workspaceId, folderId=$folderId, isInviteOnly=$isInviteOnly, isArchived=$isArchived, archivedTimestamp=$archivedTimestamp, archivedDate=$archivedDate, isFrozen=$isFrozen, name=$name, color=$color, viewStyle=$viewStyle, description=$description, status=$status, defaultOrder=$defaultOrder, v1Id=$v1Id, role=$role]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'initiated_by_uid'] = this.initiatedByUid;
      json[r'project_id'] = this.projectId;
      json[r'workspace_id'] = this.workspaceId;
    if (this.folderId != null) {
      json[r'folder_id'] = this.folderId;
    } else {
      json[r'folder_id'] = null;
    }
    if (this.isInviteOnly != null) {
      json[r'is_invite_only'] = this.isInviteOnly;
    } else {
      json[r'is_invite_only'] = null;
    }
      json[r'is_archived'] = this.isArchived;
      json[r'archived_timestamp'] = this.archivedTimestamp;
    if (this.archivedDate != null) {
      json[r'archived_date'] = this.archivedDate!.toUtc().toIso8601String();
    } else {
      json[r'archived_date'] = null;
    }
      json[r'is_frozen'] = this.isFrozen;
      json[r'name'] = this.name;
    if (this.color != null) {
      json[r'color'] = this.color;
    } else {
      json[r'color'] = null;
    }
      json[r'view_style'] = this.viewStyle;
      json[r'description'] = this.description;
      json[r'status'] = this.status;
      json[r'default_order'] = this.defaultOrder;
    if (this.v1Id != null) {
      json[r'_v1_id'] = this.v1Id;
    } else {
      json[r'_v1_id'] = null;
    }
    if (this.role != null) {
      json[r'_role'] = this.role;
    } else {
      json[r'_role'] = null;
    }
    return json;
  }

  /// Returns a new [WorkspaceProjectView] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WorkspaceProjectView? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "WorkspaceProjectView[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "WorkspaceProjectView[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return WorkspaceProjectView(
        initiatedByUid: mapValueOfType<int>(json, r'initiated_by_uid')!,
        projectId: mapValueOfType<String>(json, r'project_id')!,
        workspaceId: mapValueOfType<int>(json, r'workspace_id')!,
        folderId: mapValueOfType<int>(json, r'folder_id'),
        isInviteOnly: mapValueOfType<bool>(json, r'is_invite_only'),
        isArchived: mapValueOfType<bool>(json, r'is_archived') ?? false,
        archivedTimestamp: mapValueOfType<int>(json, r'archived_timestamp') ?? 0,
        archivedDate: mapDateTime(json, r'archived_date', r''),
        isFrozen: mapValueOfType<bool>(json, r'is_frozen') ?? false,
        name: mapValueOfType<String>(json, r'name') ?? '',
        color: mapValueOfType<int>(json, r'color'),
        viewStyle: ProjectViewStyle.fromJson(json[r'view_style']) ?? list,
        description: mapValueOfType<String>(json, r'description') ?? '',
        status: ProjectStatus.fromJson(json[r'status']) ?? ProjectStatus.IN_PROGRESS,
        defaultOrder: mapValueOfType<int>(json, r'default_order') ?? 0,
        v1Id: mapValueOfType<int>(json, r'_v1_id'),
        role: Role.fromJson(json[r'_role']),
      );
    }
    return null;
  }

  static List<WorkspaceProjectView> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkspaceProjectView>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkspaceProjectView.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WorkspaceProjectView> mapFromJson(dynamic json) {
    final map = <String, WorkspaceProjectView>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WorkspaceProjectView.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WorkspaceProjectView-objects as value to a dart map
  static Map<String, List<WorkspaceProjectView>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<WorkspaceProjectView>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WorkspaceProjectView.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'initiated_by_uid',
    'project_id',
    'workspace_id',
  };
}


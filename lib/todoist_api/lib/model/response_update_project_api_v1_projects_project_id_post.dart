//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ResponseUpdateProjectApiV1ProjectsProjectIdPost {
  /// Returns a new [ResponseUpdateProjectApiV1ProjectsProjectIdPost] instance.
  ResponseUpdateProjectApiV1ProjectsProjectIdPost({
    required this.id,
    required this.canAssignTasks,
    required this.childOrder,
    required this.color,
    required this.createdAt,
    required this.isArchived,
    required this.isDeleted,
    required this.isFavorite,
    required this.isFrozen,
    required this.name,
    required this.updatedAt,
    required this.viewStyle,
    required this.defaultOrder,
    required this.description,
    required this.parentId,
    required this.inboxProject,
    required this.isCollapsed,
    required this.isShared,
    required this.collaboratorRoleDefault,
    required this.folderId,
    required this.isInviteOnly,
    required this.isLinkSharingEnabled,
    required this.role,
    required this.status,
    required this.workspaceId,
  });

  String id;

  bool canAssignTasks;

  int childOrder;

  String color;

  String createdAt;

  bool isArchived;

  bool isDeleted;

  bool isFavorite;

  bool isFrozen;

  String name;

  String updatedAt;

  String viewStyle;

  int defaultOrder;

  String description;

  String parentId;

  bool inboxProject;

  bool isCollapsed;

  bool isShared;

  String collaboratorRoleDefault;

  String folderId;

  bool isInviteOnly;

  bool isLinkSharingEnabled;

  String role;

  String status;

  String workspaceId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ResponseUpdateProjectApiV1ProjectsProjectIdPost &&
    other.id == id &&
    other.canAssignTasks == canAssignTasks &&
    other.childOrder == childOrder &&
    other.color == color &&
    other.createdAt == createdAt &&
    other.isArchived == isArchived &&
    other.isDeleted == isDeleted &&
    other.isFavorite == isFavorite &&
    other.isFrozen == isFrozen &&
    other.name == name &&
    other.updatedAt == updatedAt &&
    other.viewStyle == viewStyle &&
    other.defaultOrder == defaultOrder &&
    other.description == description &&
    other.parentId == parentId &&
    other.inboxProject == inboxProject &&
    other.isCollapsed == isCollapsed &&
    other.isShared == isShared &&
    other.collaboratorRoleDefault == collaboratorRoleDefault &&
    other.folderId == folderId &&
    other.isInviteOnly == isInviteOnly &&
    other.isLinkSharingEnabled == isLinkSharingEnabled &&
    other.role == role &&
    other.status == status &&
    other.workspaceId == workspaceId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (canAssignTasks.hashCode) +
    (childOrder.hashCode) +
    (color.hashCode) +
    (createdAt.hashCode) +
    (isArchived.hashCode) +
    (isDeleted.hashCode) +
    (isFavorite.hashCode) +
    (isFrozen.hashCode) +
    (name.hashCode) +
    (updatedAt.hashCode) +
    (viewStyle.hashCode) +
    (defaultOrder.hashCode) +
    (description.hashCode) +
    (parentId.hashCode) +
    (inboxProject.hashCode) +
    (isCollapsed.hashCode) +
    (isShared.hashCode) +
    (collaboratorRoleDefault.hashCode) +
    (folderId.hashCode) +
    (isInviteOnly.hashCode) +
    (isLinkSharingEnabled.hashCode) +
    (role.hashCode) +
    (status.hashCode) +
    (workspaceId.hashCode);

  @override
  String toString() => 'ResponseUpdateProjectApiV1ProjectsProjectIdPost[id=$id, canAssignTasks=$canAssignTasks, childOrder=$childOrder, color=$color, createdAt=$createdAt, isArchived=$isArchived, isDeleted=$isDeleted, isFavorite=$isFavorite, isFrozen=$isFrozen, name=$name, updatedAt=$updatedAt, viewStyle=$viewStyle, defaultOrder=$defaultOrder, description=$description, parentId=$parentId, inboxProject=$inboxProject, isCollapsed=$isCollapsed, isShared=$isShared, collaboratorRoleDefault=$collaboratorRoleDefault, folderId=$folderId, isInviteOnly=$isInviteOnly, isLinkSharingEnabled=$isLinkSharingEnabled, role=$role, status=$status, workspaceId=$workspaceId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'can_assign_tasks'] = this.canAssignTasks;
      json[r'child_order'] = this.childOrder;
      json[r'color'] = this.color;
      json[r'created_at'] = this.createdAt;
      json[r'is_archived'] = this.isArchived;
      json[r'is_deleted'] = this.isDeleted;
      json[r'is_favorite'] = this.isFavorite;
      json[r'is_frozen'] = this.isFrozen;
      json[r'name'] = this.name;
      json[r'updated_at'] = this.updatedAt;
      json[r'view_style'] = this.viewStyle;
      json[r'default_order'] = this.defaultOrder;
      json[r'description'] = this.description;
      json[r'parent_id'] = this.parentId;
      json[r'inbox_project'] = this.inboxProject;
      json[r'is_collapsed'] = this.isCollapsed;
      json[r'is_shared'] = this.isShared;
      json[r'collaborator_role_default'] = this.collaboratorRoleDefault;
      json[r'folder_id'] = this.folderId;
      json[r'is_invite_only'] = this.isInviteOnly;
      json[r'is_link_sharing_enabled'] = this.isLinkSharingEnabled;
      json[r'role'] = this.role;
      json[r'status'] = this.status;
      json[r'workspace_id'] = this.workspaceId;
    return json;
  }

  /// Returns a new [ResponseUpdateProjectApiV1ProjectsProjectIdPost] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ResponseUpdateProjectApiV1ProjectsProjectIdPost? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ResponseUpdateProjectApiV1ProjectsProjectIdPost[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ResponseUpdateProjectApiV1ProjectsProjectIdPost[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ResponseUpdateProjectApiV1ProjectsProjectIdPost(
        id: mapValueOfType<String>(json, r'id')!,
        canAssignTasks: mapValueOfType<bool>(json, r'can_assign_tasks')!,
        childOrder: mapValueOfType<int>(json, r'child_order')!,
        color: mapValueOfType<String>(json, r'color')!,
        createdAt: mapValueOfType<String>(json, r'created_at')!,
        isArchived: mapValueOfType<bool>(json, r'is_archived')!,
        isDeleted: mapValueOfType<bool>(json, r'is_deleted')!,
        isFavorite: mapValueOfType<bool>(json, r'is_favorite')!,
        isFrozen: mapValueOfType<bool>(json, r'is_frozen')!,
        name: mapValueOfType<String>(json, r'name')!,
        updatedAt: mapValueOfType<String>(json, r'updated_at')!,
        viewStyle: mapValueOfType<String>(json, r'view_style')!,
        defaultOrder: mapValueOfType<int>(json, r'default_order')!,
        description: mapValueOfType<String>(json, r'description')!,
        parentId: mapValueOfType<String>(json, r'parent_id')!,
        inboxProject: mapValueOfType<bool>(json, r'inbox_project')!,
        isCollapsed: mapValueOfType<bool>(json, r'is_collapsed')!,
        isShared: mapValueOfType<bool>(json, r'is_shared')!,
        collaboratorRoleDefault: mapValueOfType<String>(json, r'collaborator_role_default')!,
        folderId: mapValueOfType<String>(json, r'folder_id')!,
        isInviteOnly: mapValueOfType<bool>(json, r'is_invite_only')!,
        isLinkSharingEnabled: mapValueOfType<bool>(json, r'is_link_sharing_enabled')!,
        role: mapValueOfType<String>(json, r'role')!,
        status: mapValueOfType<String>(json, r'status')!,
        workspaceId: mapValueOfType<String>(json, r'workspace_id')!,
      );
    }
    return null;
  }

  static List<ResponseUpdateProjectApiV1ProjectsProjectIdPost> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResponseUpdateProjectApiV1ProjectsProjectIdPost>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResponseUpdateProjectApiV1ProjectsProjectIdPost.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ResponseUpdateProjectApiV1ProjectsProjectIdPost> mapFromJson(dynamic json) {
    final map = <String, ResponseUpdateProjectApiV1ProjectsProjectIdPost>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ResponseUpdateProjectApiV1ProjectsProjectIdPost.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ResponseUpdateProjectApiV1ProjectsProjectIdPost-objects as value to a dart map
  static Map<String, List<ResponseUpdateProjectApiV1ProjectsProjectIdPost>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ResponseUpdateProjectApiV1ProjectsProjectIdPost>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ResponseUpdateProjectApiV1ProjectsProjectIdPost.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'can_assign_tasks',
    'child_order',
    'color',
    'created_at',
    'is_archived',
    'is_deleted',
    'is_favorite',
    'is_frozen',
    'name',
    'updated_at',
    'view_style',
    'default_order',
    'description',
    'parent_id',
    'inbox_project',
    'is_collapsed',
    'is_shared',
    'collaborator_role_default',
    'folder_id',
    'is_invite_only',
    'is_link_sharing_enabled',
    'role',
    'status',
    'workspace_id',
  };
}


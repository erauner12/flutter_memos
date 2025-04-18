//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// The type of notification being sent
class NotificationType {
  /// Instantiate a new enum with the provided [value].
  const NotificationType._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const noteAdded = NotificationType._(r'note_added');
  static const itemAssigned = NotificationType._(r'item_assigned');
  static const itemCompleted = NotificationType._(r'item_completed');
  static const itemUncompleted = NotificationType._(r'item_uncompleted');
  static const karmaLevel = NotificationType._(r'karma_level');
  static const shareInvitationSent = NotificationType._(r'share_invitation_sent');
  static const shareInvitationAccepted = NotificationType._(r'share_invitation_accepted');
  static const shareInvitationRejected = NotificationType._(r'share_invitation_rejected');
  static const shareInvitationBlockedByProjectLimit = NotificationType._(r'share_invitation_blocked_by_project_limit');
  static const userLeftProject = NotificationType._(r'user_left_project');
  static const userRemovedFromProject = NotificationType._(r'user_removed_from_project');
  static const teamsWorkspaceUpgraded = NotificationType._(r'teams_workspace_upgraded');
  static const teamsWorkspaceCanceled = NotificationType._(r'teams_workspace_canceled');
  static const teamsWorkspacePaymentFailed = NotificationType._(r'teams_workspace_payment_failed');
  static const workspaceInvitationCreated = NotificationType._(r'workspace_invitation_created');
  static const workspaceInvitationAccepted = NotificationType._(r'workspace_invitation_accepted');
  static const workspaceInvitationRejected = NotificationType._(r'workspace_invitation_rejected');
  static const projectArchived = NotificationType._(r'project_archived');
  static const projectMoved = NotificationType._(r'project_moved');
  static const removedFromWorkspace = NotificationType._(r'removed_from_workspace');
  static const workspaceDeleted = NotificationType._(r'workspace_deleted');
  static const message = NotificationType._(r'message');
  static const workspaceUserJoinedByDomain = NotificationType._(r'workspace_user_joined_by_domain');

  /// List of all possible values in this [enum][NotificationType].
  static const values = <NotificationType>[
    noteAdded,
    itemAssigned,
    itemCompleted,
    itemUncompleted,
    karmaLevel,
    shareInvitationSent,
    shareInvitationAccepted,
    shareInvitationRejected,
    shareInvitationBlockedByProjectLimit,
    userLeftProject,
    userRemovedFromProject,
    teamsWorkspaceUpgraded,
    teamsWorkspaceCanceled,
    teamsWorkspacePaymentFailed,
    workspaceInvitationCreated,
    workspaceInvitationAccepted,
    workspaceInvitationRejected,
    projectArchived,
    projectMoved,
    removedFromWorkspace,
    workspaceDeleted,
    message,
    workspaceUserJoinedByDomain,
  ];

  static NotificationType? fromJson(dynamic value) => NotificationTypeTypeTransformer().decode(value);

  static List<NotificationType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NotificationType] to String,
/// and [decode] dynamic data back to [NotificationType].
class NotificationTypeTypeTransformer {
  factory NotificationTypeTypeTransformer() => _instance ??= const NotificationTypeTypeTransformer._();

  const NotificationTypeTypeTransformer._();

  String encode(NotificationType data) => data.value;

  /// Decodes a [dynamic value][data] to a NotificationType.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NotificationType? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'note_added': return NotificationType.noteAdded;
        case r'item_assigned': return NotificationType.itemAssigned;
        case r'item_completed': return NotificationType.itemCompleted;
        case r'item_uncompleted': return NotificationType.itemUncompleted;
        case r'karma_level': return NotificationType.karmaLevel;
        case r'share_invitation_sent': return NotificationType.shareInvitationSent;
        case r'share_invitation_accepted': return NotificationType.shareInvitationAccepted;
        case r'share_invitation_rejected': return NotificationType.shareInvitationRejected;
        case r'share_invitation_blocked_by_project_limit': return NotificationType.shareInvitationBlockedByProjectLimit;
        case r'user_left_project': return NotificationType.userLeftProject;
        case r'user_removed_from_project': return NotificationType.userRemovedFromProject;
        case r'teams_workspace_upgraded': return NotificationType.teamsWorkspaceUpgraded;
        case r'teams_workspace_canceled': return NotificationType.teamsWorkspaceCanceled;
        case r'teams_workspace_payment_failed': return NotificationType.teamsWorkspacePaymentFailed;
        case r'workspace_invitation_created': return NotificationType.workspaceInvitationCreated;
        case r'workspace_invitation_accepted': return NotificationType.workspaceInvitationAccepted;
        case r'workspace_invitation_rejected': return NotificationType.workspaceInvitationRejected;
        case r'project_archived': return NotificationType.projectArchived;
        case r'project_moved': return NotificationType.projectMoved;
        case r'removed_from_workspace': return NotificationType.removedFromWorkspace;
        case r'workspace_deleted': return NotificationType.workspaceDeleted;
        case r'message': return NotificationType.message;
        case r'workspace_user_joined_by_domain': return NotificationType.workspaceUserJoinedByDomain;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [NotificationTypeTypeTransformer] instance.
  static NotificationTypeTypeTransformer? _instance;
}


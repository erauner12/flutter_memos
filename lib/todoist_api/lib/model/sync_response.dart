//
// PLACEHOLDER FILE - DO NOT MODIFY MANUALLY IF USING CODE GENERATION!
// This file simulates the existence of a SyncResponse model generated from an OpenAPI spec
// based on the documentation for the /sync endpoint.
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SyncResponse {
  /// Returns a new [SyncResponse] instance.
  SyncResponse({
    this.syncToken,
    this.fullSync,
    this.tempIdMapping = const {},
    this.items = const [],
    this.projects = const [],
    this.labels = const [],
    this.notes = const [],
    this.projectNotes = const [],
    this.sections = const [],
    this.filters = const [],
    this.dayOrders = const {},
    this.reminders = const [],
    this.collaborators = const [], // Assuming Collaborator model exists
    this.collaboratorStates = const [], // Assuming CollaboratorState model exists or use Map
    this.liveNotifications = const [], // Assuming LiveNotification model exists or use Map
    this.liveNotificationsLastReadId,
    this.user, // Assuming User model exists or use Map
    this.userSettings, // Assuming UserSettings model exists or use Map
    this.userPlanLimits, // Assuming UserPlanLimits model exists or use Map
    this.activity = const [], // Added activity field
    // Add other fields from documentation as needed (completed_info, stats, etc.)
  });

  /// A new synchronization token. Used by the client in the next sync request to perform an incremental sync.
  ///
  /// Please note: This property should have been non-nullable!
  String? syncToken;

  /// Whether the response contains all data (a full synchronization) or just the incremental updates since the last sync.
  ///
  /// Please note: This property should have been non-nullable!
  bool? fullSync;

  /// Mapping of temporary IDs to permanent IDs for newly created objects in the request.
  Map<String, String> tempIdMapping;

  /// An array of item objects. Use Task model for now, might need a specific SyncItem model.
  List<Task> items;

  /// An array of project objects.
  List<Project> projects;

  /// An array of personal label objects.
  List<Label> labels;

  /// An array of task comments objects.
  List<Comment> notes;

  /// An array of project comments objects.
  List<Comment> projectNotes; // Assuming Comment model can represent project notes too

  /// An array of section objects.
  List<Section> sections;

  /// An array of filter objects. (Model not provided, using Map as placeholder)
  List<Map<String, Object>> filters;

  /// A JSON object specifying the order of items in daily agenda. (Using Map as placeholder)
  Map<String, Object> dayOrders;

  /// An array of reminder objects. (Model not provided, using Map as placeholder)
  List<Map<String, Object>> reminders;

  /// A JSON object containing all collaborators for all shared projects.
  List<Collaborator> collaborators; // Reusing REST Collaborator model

  /// An array specifying the state of each collaborator in each project. (Model not provided, using Map as placeholder)
  List<Map<String, Object>> collaboratorStates;

  /// An array of live_notification objects. (Model not provided, using Map as placeholder)
  List<Map<String, Object>> liveNotifications;

  /// What is the last live notification the user has seen?
  String? liveNotificationsLastReadId;

  /// A user object. (Model not provided, using Map as placeholder)
  Map<String, Object>? user;

  /// A JSON object containing user settings. (Model not provided, using Map as placeholder)
  Map<String, Object>? userSettings;

  /// A JSON object containing user plan limits. (Model not provided, using Map as placeholder)
  Map<String, Object>? userPlanLimits;

  /// An array of activity log event objects.
  List<ActivityEvents> activity; // Added activity field

  // Add other fields like completed_info, stats, locations, notification_settings, workspaces, workspace_users as needed

  @override
  bool operator ==(Object other) => identical(this, other) || other is SyncResponse &&
    other.syncToken == syncToken &&
    other.fullSync == fullSync &&
    _deepEquality.equals(other.tempIdMapping, tempIdMapping) &&
    _deepEquality.equals(other.items, items) &&
    _deepEquality.equals(other.projects, projects) &&
    _deepEquality.equals(other.labels, labels) &&
    _deepEquality.equals(other.notes, notes) &&
    _deepEquality.equals(other.projectNotes, projectNotes) &&
    _deepEquality.equals(other.sections, sections) &&
    _deepEquality.equals(other.filters, filters) &&
    _deepEquality.equals(other.dayOrders, dayOrders) &&
    _deepEquality.equals(other.reminders, reminders) &&
    _deepEquality.equals(other.collaborators, collaborators) &&
    _deepEquality.equals(other.collaboratorStates, collaboratorStates) &&
    _deepEquality.equals(other.liveNotifications, liveNotifications) &&
    other.liveNotificationsLastReadId == liveNotificationsLastReadId &&
    _deepEquality.equals(other.user, user) &&
    _deepEquality.equals(other.userSettings, userSettings) &&
          _deepEquality.equals(other.userPlanLimits, userPlanLimits) &&
          _deepEquality.equals(
              other.activity, activity); // Added activity check

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (syncToken == null ? 0 : syncToken!.hashCode) +
    (fullSync == null ? 0 : fullSync!.hashCode) +
    (tempIdMapping.hashCode) +
    (items.hashCode) +
    (projects.hashCode) +
    (labels.hashCode) +
    (notes.hashCode) +
    (projectNotes.hashCode) +
    (sections.hashCode) +
    (filters.hashCode) +
    (dayOrders.hashCode) +
    (reminders.hashCode) +
    (collaborators.hashCode) +
    (collaboratorStates.hashCode) +
    (liveNotifications.hashCode) +
    (liveNotificationsLastReadId == null ? 0 : liveNotificationsLastReadId!.hashCode) +
    (user == null ? 0 : user!.hashCode) +
    (userSettings == null ? 0 : userSettings!.hashCode) +
      (userPlanLimits == null ? 0 : userPlanLimits!.hashCode) +
      (activity.hashCode); // Added activity hash


  @override
  String toString() =>
      'SyncResponse[syncToken=$syncToken, fullSync=$fullSync, items=${items.length}, projects=${projects.length}, activity=${activity.length}, ...]'; // Added activity count

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.syncToken != null) {
      json[r'sync_token'] = this.syncToken;
    } else {
      json[r'sync_token'] = null;
    }
    if (this.fullSync != null) {
      json[r'full_sync'] = this.fullSync;
    } else {
      json[r'full_sync'] = null;
    }
      json[r'temp_id_mapping'] = this.tempIdMapping;
      json[r'items'] = this.items.map((v) => v.toJson()).toList();
      json[r'projects'] = this.projects.map((v) => v.toJson()).toList();
      json[r'labels'] = this.labels.map((v) => v.toJson()).toList();
      json[r'notes'] = this.notes.map((v) => v.toJson()).toList();
      json[r'project_notes'] = this.projectNotes.map((v) => v.toJson()).toList();
      json[r'sections'] = this.sections.map((v) => v.toJson()).toList();
      json[r'filters'] = this.filters;
      json[r'day_orders'] = this.dayOrders;
      json[r'reminders'] = this.reminders;
      json[r'collaborators'] = this.collaborators.map((v) => v.toJson()).toList();
      json[r'collaborator_states'] = this.collaboratorStates;
      json[r'live_notifications'] = this.liveNotifications;
    if (this.liveNotificationsLastReadId != null) {
      json[r'live_notifications_last_read_id'] = this.liveNotificationsLastReadId;
    } else {
      json[r'live_notifications_last_read_id'] = null;
    }
    if (this.user != null) {
      json[r'user'] = this.user;
    } else {
      json[r'user'] = null;
    }
    if (this.userSettings != null) {
      json[r'user_settings'] = this.userSettings;
    } else {
      json[r'user_settings'] = null;
    }
    if (this.userPlanLimits != null) {
      json[r'user_plan_limits'] = this.userPlanLimits;
    } else {
      json[r'user_plan_limits'] = null;
    }
    json[r'activity'] = this
        .activity
        .map((v) => v.toJson())
        .toList(); // Added activity serialization
    return json;
  }

  /// Returns a new [SyncResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SyncResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          // Allow optional keys like 'activity' to be missing
          if (json.containsKey(key)) {
            assert(json[key] != null,
                'Required key "SyncResponse[$key]" has a null value in JSON.');
          } else if (!optionalKeys.contains(key)) {
            assert(false,
                'Required key "SyncResponse[$key]" is missing from JSON.');
          }
        });
        return true;
      }());

      return SyncResponse(
        syncToken: mapValueOfType<String>(json, r'sync_token'),
        fullSync: mapValueOfType<bool>(json, r'full_sync'),
        tempIdMapping: mapCastOfType<String, String>(json, r'temp_id_mapping') ?? const {},
        items: Task.listFromJson(json[r'items'] ?? []),
        projects: Project.listFromJson(json[r'projects'] ?? []),
        labels: Label.listFromJson(json[r'labels'] ?? []),
        notes: Comment.listFromJson(json[r'notes'] ?? []),
        projectNotes: Comment.listFromJson(json[r'project_notes'] ?? []),
        sections: Section.listFromJson(json[r'sections'] ?? []),
        filters: json[r'filters'] is List ? (json[r'filters'] as List).map((e) => e as Map<String, Object>).toList() : [],
        dayOrders: mapCastOfType<String, Object>(json, r'day_orders') ?? const {},
        reminders: json[r'reminders'] is List ? (json[r'reminders'] as List).map((e) => e as Map<String, Object>).toList() : [],
        collaborators: Collaborator.listFromJson(json[r'collaborators'] ?? []),
        collaboratorStates: json[r'collaborator_states'] is List ? (json[r'collaborator_states'] as List).map((e) => e as Map<String, Object>).toList() : [],
        liveNotifications: json[r'live_notifications'] is List ? (json[r'live_notifications'] as List).map((e) => e as Map<String, Object>).toList() : [],
        liveNotificationsLastReadId: mapValueOfType<String>(json, r'live_notifications_last_read_id'),
        user: mapCastOfType<String, Object>(json, r'user'),
        userSettings: mapCastOfType<String, Object>(json, r'user_settings'),
        userPlanLimits: mapCastOfType<String, Object>(json, r'user_plan_limits'),
        activity: ActivityEvents.listFromJson(
            json[r'activity'] ?? []), // Added activity deserialization
      );
    }
    return null;
  }

  static List<SyncResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SyncResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SyncResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SyncResponse> mapFromJson(dynamic json) {
    final map = <String, SyncResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SyncResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SyncResponse-objects as value to a dart map
  static Map<String, List<SyncResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SyncResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SyncResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  /// NOTE: Based on example, none seem strictly required, but sync_token and full_sync are fundamental.
  static const requiredKeys = <String>{
    // 'sync_token', // Making nullable for robustness
    // 'full_sync', // Making nullable for robustness
  };

  /// The list of optional keys that may be present in a JSON.
  static const optionalKeys = <String>{
    'sync_token',
    'full_sync',
    'temp_id_mapping',
    'items',
    'projects',
    'labels',
    'notes',
    'project_notes',
    'sections',
    'filters',
    'day_orders',
    'reminders',
    'collaborators',
    'collaborator_states',
    'live_notifications',
    'live_notifications_last_read_id',
    'user',
    'user_settings',
    'user_plan_limits',
    'activity', // Added activity to optional keys
  };
}

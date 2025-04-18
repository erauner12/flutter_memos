//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TodoistAppsApiRestCommentsBody1 {
  /// Returns a new [TodoistAppsApiRestCommentsBody1] instance.
  TodoistAppsApiRestCommentsBody1({
    required this.content,
    this.projectId,
    this.taskId,
    this.attachment = const {},
    this.uidsToNotify = const [],
  });

  String content;

  ProjectId5? projectId;

  TaskId3? taskId;

  Map<String, Object>? attachment;

  List<int>? uidsToNotify;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TodoistAppsApiRestCommentsBody1 &&
    other.content == content &&
    other.projectId == projectId &&
    other.taskId == taskId &&
    _deepEquality.equals(other.attachment, attachment) &&
    _deepEquality.equals(other.uidsToNotify, uidsToNotify);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (content.hashCode) +
    (projectId == null ? 0 : projectId!.hashCode) +
    (taskId == null ? 0 : taskId!.hashCode) +
    (attachment == null ? 0 : attachment!.hashCode) +
    (uidsToNotify == null ? 0 : uidsToNotify!.hashCode);

  @override
  String toString() => 'TodoistAppsApiRestCommentsBody1[content=$content, projectId=$projectId, taskId=$taskId, attachment=$attachment, uidsToNotify=$uidsToNotify]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'content'] = this.content;
    if (this.projectId != null) {
      json[r'project_id'] = this.projectId;
    } else {
      json[r'project_id'] = null;
    }
    if (this.taskId != null) {
      json[r'task_id'] = this.taskId;
    } else {
      json[r'task_id'] = null;
    }
    if (this.attachment != null) {
      json[r'attachment'] = this.attachment;
    } else {
      json[r'attachment'] = null;
    }
    if (this.uidsToNotify != null) {
      json[r'uids_to_notify'] = this.uidsToNotify;
    } else {
      json[r'uids_to_notify'] = null;
    }
    return json;
  }

  /// Returns a new [TodoistAppsApiRestCommentsBody1] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TodoistAppsApiRestCommentsBody1? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TodoistAppsApiRestCommentsBody1[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TodoistAppsApiRestCommentsBody1[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TodoistAppsApiRestCommentsBody1(
        content: mapValueOfType<String>(json, r'content')!,
        projectId: ProjectId5.fromJson(json[r'project_id']),
        taskId: TaskId3.fromJson(json[r'task_id']),
        attachment: mapCastOfType<String, Object>(json, r'attachment') ?? const {},
        uidsToNotify: json[r'uids_to_notify'] is Iterable
            ? (json[r'uids_to_notify'] as Iterable).cast<int>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<TodoistAppsApiRestCommentsBody1> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TodoistAppsApiRestCommentsBody1>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TodoistAppsApiRestCommentsBody1.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TodoistAppsApiRestCommentsBody1> mapFromJson(dynamic json) {
    final map = <String, TodoistAppsApiRestCommentsBody1>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TodoistAppsApiRestCommentsBody1.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TodoistAppsApiRestCommentsBody1-objects as value to a dart map
  static Map<String, List<TodoistAppsApiRestCommentsBody1>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TodoistAppsApiRestCommentsBody1>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TodoistAppsApiRestCommentsBody1.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'content',
  };
}


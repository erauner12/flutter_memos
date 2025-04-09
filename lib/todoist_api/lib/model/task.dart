//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Task {
  /// Returns a new [Task] instance.
  Task({
    this.id,
    this.projectId,
    this.sectionId,
    this.content,
    this.description,
    this.isCompleted,
    this.labels = const [],
    this.parentId,
    this.order,
    this.priority,
    this.due,
    this.url,
    this.commentCount,
    this.createdAt,
    this.creatorId,
    this.assigneeId,
    this.assignerId,
    this.duration,
  });

  /// Task ID.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? id;

  /// Task's project ID (read-only).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? projectId;

  /// ID of section task belongs to (read-only, will be null when the task has no parent section).
  String? sectionId;

  /// Task content. This value may contain markdown-formatted text and hyperlinks. Details on markdown support can be found in the Text Formatting article in the Help Center.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? content;

  /// A description for the task. This value may contain markdown-formatted text and hyperlinks. Details on markdown support can be found in the Text Formatting article in the Help Center.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  /// Flag to mark completed tasks.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isCompleted;

  List<String> labels;

  /// ID of parent task (read-only, will be null for top-level tasks).
  String? parentId;

  /// Position under the same parent or project for top-level tasks (read-only).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? order;

  /// Task priority from 1 (normal, default value) to 4 (urgent).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? priority;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  TaskDue? due;

  /// URL to access this task in the Todoist web or mobile applications (read-only).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? url;

  /// Number of task comments (read-only).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? commentCount;

  /// The date when the task was created (read-only).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? createdAt;

  /// The ID of the user who created the task (read-only).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? creatorId;

  /// The responsible user ID (will be null if the task is unassigned).
  String? assigneeId;

  /// The ID of the user who assigned the task (read-only, will be null if the task is unassigned).
  String? assignerId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  TaskDuration? duration;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Task &&
    other.id == id &&
    other.projectId == projectId &&
    other.sectionId == sectionId &&
    other.content == content &&
    other.description == description &&
    other.isCompleted == isCompleted &&
    _deepEquality.equals(other.labels, labels) &&
    other.parentId == parentId &&
    other.order == order &&
    other.priority == priority &&
    other.due == due &&
    other.url == url &&
    other.commentCount == commentCount &&
    other.createdAt == createdAt &&
    other.creatorId == creatorId &&
    other.assigneeId == assigneeId &&
    other.assignerId == assignerId &&
    other.duration == duration;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (projectId == null ? 0 : projectId!.hashCode) +
    (sectionId == null ? 0 : sectionId!.hashCode) +
    (content == null ? 0 : content!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (isCompleted == null ? 0 : isCompleted!.hashCode) +
    (labels.hashCode) +
    (parentId == null ? 0 : parentId!.hashCode) +
    (order == null ? 0 : order!.hashCode) +
    (priority == null ? 0 : priority!.hashCode) +
    (due == null ? 0 : due!.hashCode) +
    (url == null ? 0 : url!.hashCode) +
    (commentCount == null ? 0 : commentCount!.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode) +
    (creatorId == null ? 0 : creatorId!.hashCode) +
    (assigneeId == null ? 0 : assigneeId!.hashCode) +
    (assignerId == null ? 0 : assignerId!.hashCode) +
    (duration == null ? 0 : duration!.hashCode);

  @override
  String toString() => 'Task[id=$id, projectId=$projectId, sectionId=$sectionId, content=$content, description=$description, isCompleted=$isCompleted, labels=$labels, parentId=$parentId, order=$order, priority=$priority, due=$due, url=$url, commentCount=$commentCount, createdAt=$createdAt, creatorId=$creatorId, assigneeId=$assigneeId, assignerId=$assignerId, duration=$duration]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.projectId != null) {
      json[r'project_id'] = this.projectId;
    } else {
      json[r'project_id'] = null;
    }
    if (this.sectionId != null) {
      json[r'section_id'] = this.sectionId;
    } else {
      json[r'section_id'] = null;
    }
    if (this.content != null) {
      json[r'content'] = this.content;
    } else {
      json[r'content'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.isCompleted != null) {
      json[r'is_completed'] = this.isCompleted;
    } else {
      json[r'is_completed'] = null;
    }
      json[r'labels'] = this.labels;
    if (this.parentId != null) {
      json[r'parent_id'] = this.parentId;
    } else {
      json[r'parent_id'] = null;
    }
    if (this.order != null) {
      json[r'order'] = this.order;
    } else {
      json[r'order'] = null;
    }
    if (this.priority != null) {
      json[r'priority'] = this.priority;
    } else {
      json[r'priority'] = null;
    }
    if (this.due != null) {
      json[r'due'] = this.due;
    } else {
      json[r'due'] = null;
    }
    if (this.url != null) {
      json[r'url'] = this.url;
    } else {
      json[r'url'] = null;
    }
    if (this.commentCount != null) {
      json[r'comment_count'] = this.commentCount;
    } else {
      json[r'comment_count'] = null;
    }
    if (this.createdAt != null) {
      json[r'created_at'] = this.createdAt;
    } else {
      json[r'created_at'] = null;
    }
    if (this.creatorId != null) {
      json[r'creator_id'] = this.creatorId;
    } else {
      json[r'creator_id'] = null;
    }
    if (this.assigneeId != null) {
      json[r'assignee_id'] = this.assigneeId;
    } else {
      json[r'assignee_id'] = null;
    }
    if (this.assignerId != null) {
      json[r'assigner_id'] = this.assignerId;
    } else {
      json[r'assigner_id'] = null;
    }
    if (this.duration != null) {
      json[r'duration'] = this.duration;
    } else {
      json[r'duration'] = null;
    }
    return json;
  }

  /// Returns a new [Task] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Task? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Task[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Task[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Task(
        id: mapValueOfType<String>(json, r'id'),
        projectId: mapValueOfType<String>(json, r'project_id'),
        sectionId: mapValueOfType<String>(json, r'section_id'),
        content: mapValueOfType<String>(json, r'content'),
        description: mapValueOfType<String>(json, r'description'),
        isCompleted: mapValueOfType<bool>(json, r'is_completed'),
        labels: json[r'labels'] is Iterable
            ? (json[r'labels'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        parentId: mapValueOfType<String>(json, r'parent_id'),
        order: mapValueOfType<int>(json, r'order'),
        priority: mapValueOfType<int>(json, r'priority'),
        due: TaskDue.fromJson(json[r'due']),
        url: mapValueOfType<String>(json, r'url'),
        commentCount: mapValueOfType<int>(json, r'comment_count'),
        createdAt: mapValueOfType<String>(json, r'created_at'),
        creatorId: mapValueOfType<String>(json, r'creator_id'),
        assigneeId: mapValueOfType<String>(json, r'assignee_id'),
        assignerId: mapValueOfType<String>(json, r'assigner_id'),
        duration: TaskDuration.fromJson(json[r'duration']),
      );
    }
    return null;
  }

  static List<Task> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Task>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Task.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Task> mapFromJson(dynamic json) {
    final map = <String, Task>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Task.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Task-objects as value to a dart map
  static Map<String, List<Task>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Task>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Task.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


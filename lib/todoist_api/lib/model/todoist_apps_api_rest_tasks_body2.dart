//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TodoistAppsApiRestTasksBody2 {
  /// Returns a new [TodoistAppsApiRestTasksBody2] instance.
  TodoistAppsApiRestTasksBody2({
    this.content,
    this.description,
    this.labels,
    this.priority,
    this.dueString,
    this.dueDate,
    this.dueDatetime,
    this.dueLang,
    this.assigneeId,
    this.duration,
    this.durationUnit,
    this.deadlineDate,
    this.deadlineLang,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Content? content;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Description? description;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Labels? labels;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Priority? priority;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DueString? dueString;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DueDate? dueDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DueDatetime? dueDatetime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DueLang? dueLang;

  AssigneeId? assigneeId;

  Duration? duration;

  DurationUnit? durationUnit;

  DeadlineDate? deadlineDate;

  DeadlineLang? deadlineLang;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TodoistAppsApiRestTasksBody2 &&
    other.content == content &&
    other.description == description &&
    other.labels == labels &&
    other.priority == priority &&
    other.dueString == dueString &&
    other.dueDate == dueDate &&
    other.dueDatetime == dueDatetime &&
    other.dueLang == dueLang &&
    other.assigneeId == assigneeId &&
    other.duration == duration &&
    other.durationUnit == durationUnit &&
    other.deadlineDate == deadlineDate &&
    other.deadlineLang == deadlineLang;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (content == null ? 0 : content!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (labels == null ? 0 : labels!.hashCode) +
    (priority == null ? 0 : priority!.hashCode) +
    (dueString == null ? 0 : dueString!.hashCode) +
    (dueDate == null ? 0 : dueDate!.hashCode) +
    (dueDatetime == null ? 0 : dueDatetime!.hashCode) +
    (dueLang == null ? 0 : dueLang!.hashCode) +
    (assigneeId == null ? 0 : assigneeId!.hashCode) +
    (duration == null ? 0 : duration!.hashCode) +
    (durationUnit == null ? 0 : durationUnit!.hashCode) +
    (deadlineDate == null ? 0 : deadlineDate!.hashCode) +
    (deadlineLang == null ? 0 : deadlineLang!.hashCode);

  @override
  String toString() => 'TodoistAppsApiRestTasksBody2[content=$content, description=$description, labels=$labels, priority=$priority, dueString=$dueString, dueDate=$dueDate, dueDatetime=$dueDatetime, dueLang=$dueLang, assigneeId=$assigneeId, duration=$duration, durationUnit=$durationUnit, deadlineDate=$deadlineDate, deadlineLang=$deadlineLang]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
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
    if (this.labels != null) {
      json[r'labels'] = this.labels;
    } else {
      json[r'labels'] = null;
    }
    if (this.priority != null) {
      json[r'priority'] = this.priority;
    } else {
      json[r'priority'] = null;
    }
    if (this.dueString != null) {
      json[r'due_string'] = this.dueString;
    } else {
      json[r'due_string'] = null;
    }
    if (this.dueDate != null) {
      json[r'due_date'] = this.dueDate;
    } else {
      json[r'due_date'] = null;
    }
    if (this.dueDatetime != null) {
      json[r'due_datetime'] = this.dueDatetime;
    } else {
      json[r'due_datetime'] = null;
    }
    if (this.dueLang != null) {
      json[r'due_lang'] = this.dueLang;
    } else {
      json[r'due_lang'] = null;
    }
    if (this.assigneeId != null) {
      json[r'assignee_id'] = this.assigneeId;
    } else {
      json[r'assignee_id'] = null;
    }
    if (this.duration != null) {
      json[r'duration'] = this.duration;
    } else {
      json[r'duration'] = null;
    }
    if (this.durationUnit != null) {
      json[r'duration_unit'] = this.durationUnit;
    } else {
      json[r'duration_unit'] = null;
    }
    if (this.deadlineDate != null) {
      json[r'deadline_date'] = this.deadlineDate;
    } else {
      json[r'deadline_date'] = null;
    }
    if (this.deadlineLang != null) {
      json[r'deadline_lang'] = this.deadlineLang;
    } else {
      json[r'deadline_lang'] = null;
    }
    return json;
  }

  /// Returns a new [TodoistAppsApiRestTasksBody2] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TodoistAppsApiRestTasksBody2? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TodoistAppsApiRestTasksBody2[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TodoistAppsApiRestTasksBody2[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TodoistAppsApiRestTasksBody2(
        content: Content.fromJson(json[r'content']),
        description: Description.fromJson(json[r'description']),
        labels: Labels.fromJson(json[r'labels']),
        priority: Priority.fromJson(json[r'priority']),
        dueString: DueString.fromJson(json[r'due_string']),
        dueDate: DueDate.fromJson(json[r'due_date']),
        dueDatetime: DueDatetime.fromJson(json[r'due_datetime']),
        dueLang: DueLang.fromJson(json[r'due_lang']),
        assigneeId: AssigneeId.fromJson(json[r'assignee_id']),
        duration: Duration.fromJson(json[r'duration']),
        durationUnit: DurationUnit.fromJson(json[r'duration_unit']),
        deadlineDate: DeadlineDate.fromJson(json[r'deadline_date']),
        deadlineLang: DeadlineLang.fromJson(json[r'deadline_lang']),
      );
    }
    return null;
  }

  static List<TodoistAppsApiRestTasksBody2> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TodoistAppsApiRestTasksBody2>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TodoistAppsApiRestTasksBody2.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TodoistAppsApiRestTasksBody2> mapFromJson(dynamic json) {
    final map = <String, TodoistAppsApiRestTasksBody2>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TodoistAppsApiRestTasksBody2.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TodoistAppsApiRestTasksBody2-objects as value to a dart map
  static Map<String, List<TodoistAppsApiRestTasksBody2>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TodoistAppsApiRestTasksBody2>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TodoistAppsApiRestTasksBody2.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


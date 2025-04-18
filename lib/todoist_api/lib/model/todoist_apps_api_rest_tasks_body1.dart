//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TodoistAppsApiRestTasksBody1 {
  /// Returns a new [TodoistAppsApiRestTasksBody1] instance.
  TodoistAppsApiRestTasksBody1({
    required this.content,
    this.description,
    this.projectId,
    this.sectionId,
    this.parentId,
    this.order,
    this.labels = const [],
    this.priority,
    this.assigneeId,
    this.dueString,
    this.dueDate,
    this.dueDatetime,
    this.dueLang,
    this.duration,
    this.durationUnit,
    this.deadlineDate,
    this.deadlineLang,
  });

  String content;

  String? description;

  ProjectId2? projectId;

  SectionId4? sectionId;

  ParentId? parentId;

  /// Minimum value: -2147483648
  /// Maximum value: 2147483647
  int? order;

  List<String>? labels;

  int? priority;

  int? assigneeId;

  String? dueString;

  String? dueDate;

  String? dueDatetime;

  String? dueLang;

  int? duration;

  String? durationUnit;

  String? deadlineDate;

  String? deadlineLang;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TodoistAppsApiRestTasksBody1 &&
    other.content == content &&
    other.description == description &&
    other.projectId == projectId &&
    other.sectionId == sectionId &&
    other.parentId == parentId &&
    other.order == order &&
    _deepEquality.equals(other.labels, labels) &&
    other.priority == priority &&
    other.assigneeId == assigneeId &&
    other.dueString == dueString &&
    other.dueDate == dueDate &&
    other.dueDatetime == dueDatetime &&
    other.dueLang == dueLang &&
    other.duration == duration &&
    other.durationUnit == durationUnit &&
    other.deadlineDate == deadlineDate &&
    other.deadlineLang == deadlineLang;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (content.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (projectId == null ? 0 : projectId!.hashCode) +
    (sectionId == null ? 0 : sectionId!.hashCode) +
    (parentId == null ? 0 : parentId!.hashCode) +
    (order == null ? 0 : order!.hashCode) +
    (labels == null ? 0 : labels!.hashCode) +
    (priority == null ? 0 : priority!.hashCode) +
    (assigneeId == null ? 0 : assigneeId!.hashCode) +
    (dueString == null ? 0 : dueString!.hashCode) +
    (dueDate == null ? 0 : dueDate!.hashCode) +
    (dueDatetime == null ? 0 : dueDatetime!.hashCode) +
    (dueLang == null ? 0 : dueLang!.hashCode) +
    (duration == null ? 0 : duration!.hashCode) +
    (durationUnit == null ? 0 : durationUnit!.hashCode) +
    (deadlineDate == null ? 0 : deadlineDate!.hashCode) +
    (deadlineLang == null ? 0 : deadlineLang!.hashCode);

  @override
  String toString() => 'TodoistAppsApiRestTasksBody1[content=$content, description=$description, projectId=$projectId, sectionId=$sectionId, parentId=$parentId, order=$order, labels=$labels, priority=$priority, assigneeId=$assigneeId, dueString=$dueString, dueDate=$dueDate, dueDatetime=$dueDatetime, dueLang=$dueLang, duration=$duration, durationUnit=$durationUnit, deadlineDate=$deadlineDate, deadlineLang=$deadlineLang]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'content'] = this.content;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
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
    if (this.assigneeId != null) {
      json[r'assignee_id'] = this.assigneeId;
    } else {
      json[r'assignee_id'] = null;
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

  /// Returns a new [TodoistAppsApiRestTasksBody1] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TodoistAppsApiRestTasksBody1? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TodoistAppsApiRestTasksBody1[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TodoistAppsApiRestTasksBody1[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TodoistAppsApiRestTasksBody1(
        content: mapValueOfType<String>(json, r'content')!,
        description: mapValueOfType<String>(json, r'description'),
        projectId: ProjectId2.fromJson(json[r'project_id']),
        sectionId: SectionId4.fromJson(json[r'section_id']),
        parentId: ParentId.fromJson(json[r'parent_id']),
        order: mapValueOfType<int>(json, r'order'),
        labels: json[r'labels'] is Iterable
            ? (json[r'labels'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        priority: mapValueOfType<int>(json, r'priority'),
        assigneeId: mapValueOfType<int>(json, r'assignee_id'),
        dueString: mapValueOfType<String>(json, r'due_string'),
        dueDate: mapValueOfType<String>(json, r'due_date'),
        dueDatetime: mapValueOfType<String>(json, r'due_datetime'),
        dueLang: mapValueOfType<String>(json, r'due_lang'),
        duration: mapValueOfType<int>(json, r'duration'),
        durationUnit: mapValueOfType<String>(json, r'duration_unit'),
        deadlineDate: mapValueOfType<String>(json, r'deadline_date'),
        deadlineLang: mapValueOfType<String>(json, r'deadline_lang'),
      );
    }
    return null;
  }

  static List<TodoistAppsApiRestTasksBody1> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TodoistAppsApiRestTasksBody1>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TodoistAppsApiRestTasksBody1.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TodoistAppsApiRestTasksBody1> mapFromJson(dynamic json) {
    final map = <String, TodoistAppsApiRestTasksBody1>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TodoistAppsApiRestTasksBody1.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TodoistAppsApiRestTasksBody1-objects as value to a dart map
  static Map<String, List<TodoistAppsApiRestTasksBody1>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TodoistAppsApiRestTasksBody1>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TodoistAppsApiRestTasksBody1.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'content',
  };
}


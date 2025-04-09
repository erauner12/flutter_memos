//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateTaskRequest {
  /// Returns a new [CreateTaskRequest] instance.
  CreateTaskRequest({
    this.content,
    this.description,
    this.projectId,
    this.sectionId,
    this.parentId,
    this.order,
    this.labels = const [],
    this.priority,
    this.dueString,
    this.dueDate,
    this.dueDatetime,
    this.dueLang,
    this.assigneeId,
    this.duration,
    this.durationUnit,
  });

  /// Task content. This value may contain markdown-formatted text and hyperlinks.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? content;

  /// A description for the task. This value may contain markdown-formatted text and hyperlinks.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  /// Task project ID. If not set, the task is put in the user's Inbox.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? projectId;

  /// ID of the section to put the task into.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? sectionId;

  /// Parent task ID.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? parentId;

  /// Non-zero integer value used by clients to sort tasks under the same parent.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? order;

  /// The task's labels (a list of names that may represent either personal or shared labels).
  List<String> labels;

  /// Task priority from 1 (normal) to 4 (urgent).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? priority;

  /// Human-defined task due date (ex. \"next Monday,\" \"Tomorrow\"). Value is set using local (not UTC) time.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? dueString;

  /// Specific date in YYYY-MM-DD format relative to the user's timezone.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? dueDate;

  /// Specific date and time in RFC3339 format in UTC.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? dueDatetime;

  /// 2-letter code specifying the language in case due_string is not written in English.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? dueLang;

  /// The responsible user ID (only applies to shared tasks).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? assigneeId;

  /// A positive (greater than zero) integer for the amount of duration_unit the task will take. If specified, you must define a duration_unit.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? duration;

  /// The unit of time that the duration field above represents. Must be either minute or day. If specified, duration must be defined as well.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? durationUnit;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateTaskRequest &&
    other.content == content &&
    other.description == description &&
    other.projectId == projectId &&
    other.sectionId == sectionId &&
    other.parentId == parentId &&
    other.order == order &&
    _deepEquality.equals(other.labels, labels) &&
    other.priority == priority &&
    other.dueString == dueString &&
    other.dueDate == dueDate &&
    other.dueDatetime == dueDatetime &&
    other.dueLang == dueLang &&
    other.assigneeId == assigneeId &&
    other.duration == duration &&
    other.durationUnit == durationUnit;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (content == null ? 0 : content!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (projectId == null ? 0 : projectId!.hashCode) +
    (sectionId == null ? 0 : sectionId!.hashCode) +
    (parentId == null ? 0 : parentId!.hashCode) +
    (order == null ? 0 : order!.hashCode) +
    (labels.hashCode) +
    (priority == null ? 0 : priority!.hashCode) +
    (dueString == null ? 0 : dueString!.hashCode) +
    (dueDate == null ? 0 : dueDate!.hashCode) +
    (dueDatetime == null ? 0 : dueDatetime!.hashCode) +
    (dueLang == null ? 0 : dueLang!.hashCode) +
    (assigneeId == null ? 0 : assigneeId!.hashCode) +
    (duration == null ? 0 : duration!.hashCode) +
    (durationUnit == null ? 0 : durationUnit!.hashCode);

  @override
  String toString() => 'CreateTaskRequest[content=$content, description=$description, projectId=$projectId, sectionId=$sectionId, parentId=$parentId, order=$order, labels=$labels, priority=$priority, dueString=$dueString, dueDate=$dueDate, dueDatetime=$dueDatetime, dueLang=$dueLang, assigneeId=$assigneeId, duration=$duration, durationUnit=$durationUnit]';

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
      json[r'labels'] = this.labels;
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
    return json;
  }

  /// Returns a new [CreateTaskRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateTaskRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CreateTaskRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CreateTaskRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CreateTaskRequest(
        content: mapValueOfType<String>(json, r'content'),
        description: mapValueOfType<String>(json, r'description'),
        projectId: mapValueOfType<String>(json, r'project_id'),
        sectionId: mapValueOfType<String>(json, r'section_id'),
        parentId: mapValueOfType<String>(json, r'parent_id'),
        order: mapValueOfType<int>(json, r'order'),
        labels: json[r'labels'] is Iterable
            ? (json[r'labels'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        priority: mapValueOfType<int>(json, r'priority'),
        dueString: mapValueOfType<String>(json, r'due_string'),
        dueDate: mapValueOfType<String>(json, r'due_date'),
        dueDatetime: mapValueOfType<String>(json, r'due_datetime'),
        dueLang: mapValueOfType<String>(json, r'due_lang'),
        assigneeId: mapValueOfType<String>(json, r'assignee_id'),
        duration: mapValueOfType<int>(json, r'duration'),
        durationUnit: mapValueOfType<String>(json, r'duration_unit'),
      );
    }
    return null;
  }

  static List<CreateTaskRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateTaskRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateTaskRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateTaskRequest> mapFromJson(dynamic json) {
    final map = <String, CreateTaskRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateTaskRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateTaskRequest-objects as value to a dart map
  static Map<String, List<CreateTaskRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateTaskRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateTaskRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


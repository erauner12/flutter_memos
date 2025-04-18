//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ItemSyncView {
  /// Returns a new [ItemSyncView] instance.
  ItemSyncView({
    required this.userId,
    required this.id,
    required this.projectId,
    required this.sectionId,
    required this.parentId,
    required this.addedByUid,
    required this.assignedByUid,
    required this.responsibleUid,
    this.labels = const [],
    this.deadline = const {},
    this.duration = const {},
    required this.checked,
    required this.isDeleted,
    required this.addedAt,
    required this.completedAt,
    required this.updatedAt,
    this.due = const {},
    required this.priority,
    required this.childOrder,
    required this.content,
    required this.description,
    required this.noteCount,
    required this.dayOrder,
    required this.isCollapsed,
  });

  String userId;

  String id;

  String projectId;

  String? sectionId;

  String? parentId;

  String? addedByUid;

  String? assignedByUid;

  String? responsibleUid;

  List<String> labels;

  Map<String, ItemSyncViewDeadlineValue>? deadline;

  Map<String, ItemSyncViewDurationValue>? duration;

  bool checked;

  bool isDeleted;

  String? addedAt;

  String? completedAt;

  String? updatedAt;

  Map<String, Object>? due;

  int priority;

  int childOrder;

  String content;

  String description;

  int noteCount;

  int dayOrder;

  bool isCollapsed;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ItemSyncView &&
    other.userId == userId &&
    other.id == id &&
    other.projectId == projectId &&
    other.sectionId == sectionId &&
    other.parentId == parentId &&
    other.addedByUid == addedByUid &&
    other.assignedByUid == assignedByUid &&
    other.responsibleUid == responsibleUid &&
    _deepEquality.equals(other.labels, labels) &&
    _deepEquality.equals(other.deadline, deadline) &&
    _deepEquality.equals(other.duration, duration) &&
    other.checked == checked &&
    other.isDeleted == isDeleted &&
    other.addedAt == addedAt &&
    other.completedAt == completedAt &&
    other.updatedAt == updatedAt &&
    _deepEquality.equals(other.due, due) &&
    other.priority == priority &&
    other.childOrder == childOrder &&
    other.content == content &&
    other.description == description &&
    other.noteCount == noteCount &&
    other.dayOrder == dayOrder &&
    other.isCollapsed == isCollapsed;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (userId.hashCode) +
    (id.hashCode) +
    (projectId.hashCode) +
    (sectionId == null ? 0 : sectionId!.hashCode) +
    (parentId == null ? 0 : parentId!.hashCode) +
    (addedByUid == null ? 0 : addedByUid!.hashCode) +
    (assignedByUid == null ? 0 : assignedByUid!.hashCode) +
    (responsibleUid == null ? 0 : responsibleUid!.hashCode) +
    (labels.hashCode) +
    (deadline == null ? 0 : deadline!.hashCode) +
    (duration == null ? 0 : duration!.hashCode) +
    (checked.hashCode) +
    (isDeleted.hashCode) +
    (addedAt == null ? 0 : addedAt!.hashCode) +
    (completedAt == null ? 0 : completedAt!.hashCode) +
    (updatedAt == null ? 0 : updatedAt!.hashCode) +
    (due == null ? 0 : due!.hashCode) +
    (priority.hashCode) +
    (childOrder.hashCode) +
    (content.hashCode) +
    (description.hashCode) +
    (noteCount.hashCode) +
    (dayOrder.hashCode) +
    (isCollapsed.hashCode);

  @override
  String toString() => 'ItemSyncView[userId=$userId, id=$id, projectId=$projectId, sectionId=$sectionId, parentId=$parentId, addedByUid=$addedByUid, assignedByUid=$assignedByUid, responsibleUid=$responsibleUid, labels=$labels, deadline=$deadline, duration=$duration, checked=$checked, isDeleted=$isDeleted, addedAt=$addedAt, completedAt=$completedAt, updatedAt=$updatedAt, due=$due, priority=$priority, childOrder=$childOrder, content=$content, description=$description, noteCount=$noteCount, dayOrder=$dayOrder, isCollapsed=$isCollapsed]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'user_id'] = this.userId;
      json[r'id'] = this.id;
      json[r'project_id'] = this.projectId;
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
    if (this.addedByUid != null) {
      json[r'added_by_uid'] = this.addedByUid;
    } else {
      json[r'added_by_uid'] = null;
    }
    if (this.assignedByUid != null) {
      json[r'assigned_by_uid'] = this.assignedByUid;
    } else {
      json[r'assigned_by_uid'] = null;
    }
    if (this.responsibleUid != null) {
      json[r'responsible_uid'] = this.responsibleUid;
    } else {
      json[r'responsible_uid'] = null;
    }
      json[r'labels'] = this.labels;
    if (this.deadline != null) {
      json[r'deadline'] = this.deadline;
    } else {
      json[r'deadline'] = null;
    }
    if (this.duration != null) {
      json[r'duration'] = this.duration;
    } else {
      json[r'duration'] = null;
    }
      json[r'checked'] = this.checked;
      json[r'is_deleted'] = this.isDeleted;
    if (this.addedAt != null) {
      json[r'added_at'] = this.addedAt;
    } else {
      json[r'added_at'] = null;
    }
    if (this.completedAt != null) {
      json[r'completed_at'] = this.completedAt;
    } else {
      json[r'completed_at'] = null;
    }
    if (this.updatedAt != null) {
      json[r'updated_at'] = this.updatedAt;
    } else {
      json[r'updated_at'] = null;
    }
    if (this.due != null) {
      json[r'due'] = this.due;
    } else {
      json[r'due'] = null;
    }
      json[r'priority'] = this.priority;
      json[r'child_order'] = this.childOrder;
      json[r'content'] = this.content;
      json[r'description'] = this.description;
      json[r'note_count'] = this.noteCount;
      json[r'day_order'] = this.dayOrder;
      json[r'is_collapsed'] = this.isCollapsed;
    return json;
  }

  /// Returns a new [ItemSyncView] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ItemSyncView? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ItemSyncView[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ItemSyncView[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ItemSyncView(
        userId: mapValueOfType<String>(json, r'user_id')!,
        id: mapValueOfType<String>(json, r'id')!,
        projectId: mapValueOfType<String>(json, r'project_id')!,
        sectionId: mapValueOfType<String>(json, r'section_id'),
        parentId: mapValueOfType<String>(json, r'parent_id'),
        addedByUid: mapValueOfType<String>(json, r'added_by_uid'),
        assignedByUid: mapValueOfType<String>(json, r'assigned_by_uid'),
        responsibleUid: mapValueOfType<String>(json, r'responsible_uid'),
        labels: json[r'labels'] is Iterable
            ? (json[r'labels'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        deadline: ItemSyncViewDeadlineValue.mapFromJson(json[r'deadline']),
        duration: ItemSyncViewDurationValue.mapFromJson(json[r'duration']),
        checked: mapValueOfType<bool>(json, r'checked')!,
        isDeleted: mapValueOfType<bool>(json, r'is_deleted')!,
        addedAt: mapValueOfType<String>(json, r'added_at'),
        completedAt: mapValueOfType<String>(json, r'completed_at'),
        updatedAt: mapValueOfType<String>(json, r'updated_at'),
        due: mapCastOfType<String, Object>(json, r'due'),
        priority: mapValueOfType<int>(json, r'priority')!,
        childOrder: mapValueOfType<int>(json, r'child_order')!,
        content: mapValueOfType<String>(json, r'content')!,
        description: mapValueOfType<String>(json, r'description')!,
        noteCount: mapValueOfType<int>(json, r'note_count')!,
        dayOrder: mapValueOfType<int>(json, r'day_order')!,
        isCollapsed: mapValueOfType<bool>(json, r'is_collapsed')!,
      );
    }
    return null;
  }

  static List<ItemSyncView> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ItemSyncView>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ItemSyncView.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ItemSyncView> mapFromJson(dynamic json) {
    final map = <String, ItemSyncView>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ItemSyncView.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ItemSyncView-objects as value to a dart map
  static Map<String, List<ItemSyncView>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ItemSyncView>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ItemSyncView.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'user_id',
    'id',
    'project_id',
    'section_id',
    'parent_id',
    'added_by_uid',
    'assigned_by_uid',
    'responsible_uid',
    'labels',
    'deadline',
    'duration',
    'checked',
    'is_deleted',
    'added_at',
    'completed_at',
    'updated_at',
    'due',
    'priority',
    'child_order',
    'content',
    'description',
    'note_count',
    'day_order',
    'is_collapsed',
  };
}


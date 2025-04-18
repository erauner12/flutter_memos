//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SectionSyncView {
  /// Returns a new [SectionSyncView] instance.
  SectionSyncView({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.addedAt,
    required this.updatedAt,
    required this.archivedAt,
    required this.name,
    required this.sectionOrder,
    required this.isArchived,
    required this.isDeleted,
    required this.isCollapsed,
  });

  String id;

  String userId;

  String projectId;

  String addedAt;

  String? updatedAt;

  String? archivedAt;

  String name;

  int sectionOrder;

  bool isArchived;

  bool isDeleted;

  bool isCollapsed;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SectionSyncView &&
    other.id == id &&
    other.userId == userId &&
    other.projectId == projectId &&
    other.addedAt == addedAt &&
    other.updatedAt == updatedAt &&
    other.archivedAt == archivedAt &&
    other.name == name &&
    other.sectionOrder == sectionOrder &&
    other.isArchived == isArchived &&
    other.isDeleted == isDeleted &&
    other.isCollapsed == isCollapsed;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (userId.hashCode) +
    (projectId.hashCode) +
    (addedAt.hashCode) +
    (updatedAt == null ? 0 : updatedAt!.hashCode) +
    (archivedAt == null ? 0 : archivedAt!.hashCode) +
    (name.hashCode) +
    (sectionOrder.hashCode) +
    (isArchived.hashCode) +
    (isDeleted.hashCode) +
    (isCollapsed.hashCode);

  @override
  String toString() => 'SectionSyncView[id=$id, userId=$userId, projectId=$projectId, addedAt=$addedAt, updatedAt=$updatedAt, archivedAt=$archivedAt, name=$name, sectionOrder=$sectionOrder, isArchived=$isArchived, isDeleted=$isDeleted, isCollapsed=$isCollapsed]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'user_id'] = this.userId;
      json[r'project_id'] = this.projectId;
      json[r'added_at'] = this.addedAt;
    if (this.updatedAt != null) {
      json[r'updated_at'] = this.updatedAt;
    } else {
      json[r'updated_at'] = null;
    }
    if (this.archivedAt != null) {
      json[r'archived_at'] = this.archivedAt;
    } else {
      json[r'archived_at'] = null;
    }
      json[r'name'] = this.name;
      json[r'section_order'] = this.sectionOrder;
      json[r'is_archived'] = this.isArchived;
      json[r'is_deleted'] = this.isDeleted;
      json[r'is_collapsed'] = this.isCollapsed;
    return json;
  }

  /// Returns a new [SectionSyncView] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SectionSyncView? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SectionSyncView[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SectionSyncView[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SectionSyncView(
        id: mapValueOfType<String>(json, r'id')!,
        userId: mapValueOfType<String>(json, r'user_id')!,
        projectId: mapValueOfType<String>(json, r'project_id')!,
        addedAt: mapValueOfType<String>(json, r'added_at')!,
        updatedAt: mapValueOfType<String>(json, r'updated_at'),
        archivedAt: mapValueOfType<String>(json, r'archived_at'),
        name: mapValueOfType<String>(json, r'name')!,
        sectionOrder: mapValueOfType<int>(json, r'section_order')!,
        isArchived: mapValueOfType<bool>(json, r'is_archived')!,
        isDeleted: mapValueOfType<bool>(json, r'is_deleted')!,
        isCollapsed: mapValueOfType<bool>(json, r'is_collapsed')!,
      );
    }
    return null;
  }

  static List<SectionSyncView> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SectionSyncView>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SectionSyncView.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SectionSyncView> mapFromJson(dynamic json) {
    final map = <String, SectionSyncView>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SectionSyncView.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SectionSyncView-objects as value to a dart map
  static Map<String, List<SectionSyncView>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SectionSyncView>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SectionSyncView.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'user_id',
    'project_id',
    'added_at',
    'updated_at',
    'archived_at',
    'name',
    'section_order',
    'is_archived',
    'is_deleted',
    'is_collapsed',
  };
}


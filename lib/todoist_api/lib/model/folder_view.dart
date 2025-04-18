//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FolderView {
  /// Returns a new [FolderView] instance.
  FolderView({
    required this.workspaceId,
    this.name = '',
    this.isDeleted = false,
    this.id = '0',
    this.defaultOrder = 0,
    this.childOrder = 0,
  });

  String workspaceId;

  String name;

  bool isDeleted;

  String id;

  int defaultOrder;

  int childOrder;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FolderView &&
    other.workspaceId == workspaceId &&
    other.name == name &&
    other.isDeleted == isDeleted &&
    other.id == id &&
    other.defaultOrder == defaultOrder &&
    other.childOrder == childOrder;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (workspaceId.hashCode) +
    (name.hashCode) +
    (isDeleted.hashCode) +
    (id.hashCode) +
    (defaultOrder.hashCode) +
    (childOrder.hashCode);

  @override
  String toString() => 'FolderView[workspaceId=$workspaceId, name=$name, isDeleted=$isDeleted, id=$id, defaultOrder=$defaultOrder, childOrder=$childOrder]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'workspace_id'] = this.workspaceId;
      json[r'name'] = this.name;
      json[r'is_deleted'] = this.isDeleted;
      json[r'id'] = this.id;
      json[r'default_order'] = this.defaultOrder;
      json[r'child_order'] = this.childOrder;
    return json;
  }

  /// Returns a new [FolderView] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FolderView? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "FolderView[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "FolderView[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FolderView(
        workspaceId: mapValueOfType<String>(json, r'workspace_id')!,
        name: mapValueOfType<String>(json, r'name') ?? '',
        isDeleted: mapValueOfType<bool>(json, r'is_deleted') ?? false,
        id: mapValueOfType<String>(json, r'id') ?? '0',
        defaultOrder: mapValueOfType<int>(json, r'default_order') ?? 0,
        childOrder: mapValueOfType<int>(json, r'child_order') ?? 0,
      );
    }
    return null;
  }

  static List<FolderView> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FolderView>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FolderView.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FolderView> mapFromJson(dynamic json) {
    final map = <String, FolderView>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FolderView.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FolderView-objects as value to a dart map
  static Map<String, List<FolderView>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FolderView>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FolderView.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'workspace_id',
  };
}


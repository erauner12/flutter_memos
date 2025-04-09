//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Project {
  /// Returns a new [Project] instance.
  Project({
    this.id,
    this.name,
    this.color,
    this.parentId,
    this.order,
    this.commentCount,
    this.isShared,
    this.isFavorite,
    this.isInboxProject,
    this.isTeamInbox,
    this.viewStyle,
    this.url,
  });

  /// Project ID.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? id;

  /// Project name.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  /// The color of the project icon. Refer to the name column in the Colors guide for more info.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? color;

  /// ID of parent project (will be null for top-level projects).
  String? parentId;

  /// Project position under the same parent (read-only, will be 0 for inbox and team inbox projects).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? order;

  /// Number of project comments.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? commentCount;

  /// Whether the project is shared (read-only, a true or false value).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isShared;

  /// Whether the project is a favorite (a true or false value).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isFavorite;

  /// Whether the project is the user's Inbox (read-only).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isInboxProject;

  /// Whether the project is the Team Inbox (read-only).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isTeamInbox;

  /// A string value (either list or board). This determines the way the project is displayed within the Todoist clients.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? viewStyle;

  /// URL to access this project in the Todoist web or mobile applications.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? url;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Project &&
    other.id == id &&
    other.name == name &&
    other.color == color &&
    other.parentId == parentId &&
    other.order == order &&
    other.commentCount == commentCount &&
    other.isShared == isShared &&
    other.isFavorite == isFavorite &&
    other.isInboxProject == isInboxProject &&
    other.isTeamInbox == isTeamInbox &&
    other.viewStyle == viewStyle &&
    other.url == url;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (color == null ? 0 : color!.hashCode) +
    (parentId == null ? 0 : parentId!.hashCode) +
    (order == null ? 0 : order!.hashCode) +
    (commentCount == null ? 0 : commentCount!.hashCode) +
    (isShared == null ? 0 : isShared!.hashCode) +
    (isFavorite == null ? 0 : isFavorite!.hashCode) +
    (isInboxProject == null ? 0 : isInboxProject!.hashCode) +
    (isTeamInbox == null ? 0 : isTeamInbox!.hashCode) +
    (viewStyle == null ? 0 : viewStyle!.hashCode) +
    (url == null ? 0 : url!.hashCode);

  @override
  String toString() => 'Project[id=$id, name=$name, color=$color, parentId=$parentId, order=$order, commentCount=$commentCount, isShared=$isShared, isFavorite=$isFavorite, isInboxProject=$isInboxProject, isTeamInbox=$isTeamInbox, viewStyle=$viewStyle, url=$url]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.color != null) {
      json[r'color'] = this.color;
    } else {
      json[r'color'] = null;
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
    if (this.commentCount != null) {
      json[r'comment_count'] = this.commentCount;
    } else {
      json[r'comment_count'] = null;
    }
    if (this.isShared != null) {
      json[r'is_shared'] = this.isShared;
    } else {
      json[r'is_shared'] = null;
    }
    if (this.isFavorite != null) {
      json[r'is_favorite'] = this.isFavorite;
    } else {
      json[r'is_favorite'] = null;
    }
    if (this.isInboxProject != null) {
      json[r'is_inbox_project'] = this.isInboxProject;
    } else {
      json[r'is_inbox_project'] = null;
    }
    if (this.isTeamInbox != null) {
      json[r'is_team_inbox'] = this.isTeamInbox;
    } else {
      json[r'is_team_inbox'] = null;
    }
    if (this.viewStyle != null) {
      json[r'view_style'] = this.viewStyle;
    } else {
      json[r'view_style'] = null;
    }
    if (this.url != null) {
      json[r'url'] = this.url;
    } else {
      json[r'url'] = null;
    }
    return json;
  }

  /// Returns a new [Project] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Project? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Project[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Project[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Project(
        id: mapValueOfType<String>(json, r'id'),
        name: mapValueOfType<String>(json, r'name'),
        color: mapValueOfType<String>(json, r'color'),
        parentId: mapValueOfType<String>(json, r'parent_id'),
        order: mapValueOfType<int>(json, r'order'),
        commentCount: mapValueOfType<int>(json, r'comment_count'),
        isShared: mapValueOfType<bool>(json, r'is_shared'),
        isFavorite: mapValueOfType<bool>(json, r'is_favorite'),
        isInboxProject: mapValueOfType<bool>(json, r'is_inbox_project'),
        isTeamInbox: mapValueOfType<bool>(json, r'is_team_inbox'),
        viewStyle: mapValueOfType<String>(json, r'view_style'),
        url: mapValueOfType<String>(json, r'url'),
      );
    }
    return null;
  }

  static List<Project> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Project>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Project.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Project> mapFromJson(dynamic json) {
    final map = <String, Project>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Project.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Project-objects as value to a dart map
  static Map<String, List<Project>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Project>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Project.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


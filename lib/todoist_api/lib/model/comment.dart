//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Comment {
  /// Returns a new [Comment] instance.
  Comment({
    this.id,
    this.taskId,
    this.projectId,
    this.postedAt,
    this.content,
    this.attachment,
  });

  /// Comment ID.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? id;

  /// Comment's task ID (will be null if the comment belongs to a project).
  String? taskId;

  /// Comment's project ID (will be null if the comment belongs to a task).
  String? projectId;

  /// Date and time when comment was added, in RFC3339 format in UTC.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? postedAt;

  /// Comment content. This value may contain markdown-formatted text and hyperlinks. Details on markdown support can be found in the Text Formatting article in the Help Center.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? content;

  /// Attachment file metadata (will be null if there is no attachment). Format varies depending on the type of attachment, as detailed in the Sync API documentation.
  Object? attachment;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Comment &&
    other.id == id &&
    other.taskId == taskId &&
    other.projectId == projectId &&
    other.postedAt == postedAt &&
    other.content == content &&
    other.attachment == attachment;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (taskId == null ? 0 : taskId!.hashCode) +
    (projectId == null ? 0 : projectId!.hashCode) +
    (postedAt == null ? 0 : postedAt!.hashCode) +
    (content == null ? 0 : content!.hashCode) +
    (attachment == null ? 0 : attachment!.hashCode);

  @override
  String toString() => 'Comment[id=$id, taskId=$taskId, projectId=$projectId, postedAt=$postedAt, content=$content, attachment=$attachment]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.taskId != null) {
      json[r'task_id'] = this.taskId;
    } else {
      json[r'task_id'] = null;
    }
    if (this.projectId != null) {
      json[r'project_id'] = this.projectId;
    } else {
      json[r'project_id'] = null;
    }
    if (this.postedAt != null) {
      json[r'posted_at'] = this.postedAt!.toUtc().toIso8601String();
    } else {
      json[r'posted_at'] = null;
    }
    if (this.content != null) {
      json[r'content'] = this.content;
    } else {
      json[r'content'] = null;
    }
    if (this.attachment != null) {
      json[r'attachment'] = this.attachment;
    } else {
      json[r'attachment'] = null;
    }
    return json;
  }

  /// Returns a new [Comment] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Comment? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Comment[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Comment[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Comment(
        id: mapValueOfType<String>(json, r'id'),
        taskId: mapValueOfType<String>(json, r'task_id'),
        projectId: mapValueOfType<String>(json, r'project_id'),
        postedAt: mapDateTime(json, r'posted_at', r''),
        content: mapValueOfType<String>(json, r'content'),
        attachment: mapValueOfType<Object>(json, r'attachment'),
      );
    }
    return null;
  }

  static List<Comment> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Comment>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Comment.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Comment> mapFromJson(dynamic json) {
    final map = <String, Comment>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Comment.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Comment-objects as value to a dart map
  static Map<String, List<Comment>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Comment>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Comment.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TodoistAppsApiSyncRestQuickBody {
  /// Returns a new [TodoistAppsApiSyncRestQuickBody] instance.
  TodoistAppsApiSyncRestQuickBody({
    required this.text,
    this.note,
    this.reminder,
    this.autoReminder = false,
    this.meta = false,
  });

  /// The text of the task that is parsed. It can include a due date in free form text, a project name starting with the `#` character (without spaces), a label starting with the `@` character, an assignee starting with the `+` character, a priority (e.g., `p1`), a deadline between `{}` (e.g. {in 3 days}), or a description starting from `//` until the end of the text.
  String text;

  String? note;

  String? reminder;

  /// When this option is enabled, the default reminder will be added to the new item if it has a due date with time set. See also the [auto_reminder user option](#tag/Sync/User) for more info about the default reminder.
  bool autoReminder;

  bool meta;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TodoistAppsApiSyncRestQuickBody &&
    other.text == text &&
    other.note == note &&
    other.reminder == reminder &&
    other.autoReminder == autoReminder &&
    other.meta == meta;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (text.hashCode) +
    (note == null ? 0 : note!.hashCode) +
    (reminder == null ? 0 : reminder!.hashCode) +
    (autoReminder.hashCode) +
    (meta.hashCode);

  @override
  String toString() => 'TodoistAppsApiSyncRestQuickBody[text=$text, note=$note, reminder=$reminder, autoReminder=$autoReminder, meta=$meta]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'text'] = this.text;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    if (this.reminder != null) {
      json[r'reminder'] = this.reminder;
    } else {
      json[r'reminder'] = null;
    }
      json[r'auto_reminder'] = this.autoReminder;
      json[r'meta'] = this.meta;
    return json;
  }

  /// Returns a new [TodoistAppsApiSyncRestQuickBody] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TodoistAppsApiSyncRestQuickBody? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TodoistAppsApiSyncRestQuickBody[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TodoistAppsApiSyncRestQuickBody[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TodoistAppsApiSyncRestQuickBody(
        text: mapValueOfType<String>(json, r'text')!,
        note: mapValueOfType<String>(json, r'note'),
        reminder: mapValueOfType<String>(json, r'reminder'),
        autoReminder: mapValueOfType<bool>(json, r'auto_reminder') ?? false,
        meta: mapValueOfType<bool>(json, r'meta') ?? false,
      );
    }
    return null;
  }

  static List<TodoistAppsApiSyncRestQuickBody> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TodoistAppsApiSyncRestQuickBody>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TodoistAppsApiSyncRestQuickBody.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TodoistAppsApiSyncRestQuickBody> mapFromJson(dynamic json) {
    final map = <String, TodoistAppsApiSyncRestQuickBody>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TodoistAppsApiSyncRestQuickBody.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TodoistAppsApiSyncRestQuickBody-objects as value to a dart map
  static Map<String, List<TodoistAppsApiSyncRestQuickBody>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TodoistAppsApiSyncRestQuickBody>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TodoistAppsApiSyncRestQuickBody.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'text',
  };
}


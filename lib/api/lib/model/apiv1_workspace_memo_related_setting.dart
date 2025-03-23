//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Apiv1WorkspaceMemoRelatedSetting {
  /// Returns a new [Apiv1WorkspaceMemoRelatedSetting] instance.
  Apiv1WorkspaceMemoRelatedSetting({
    this.disallowPublicVisibility,
    this.displayWithUpdateTime,
    this.contentLengthLimit,
    this.enableAutoCompact,
    this.enableDoubleClickEdit,
    this.enableLinkPreview,
    this.enableComment,
    this.enableLocation,
    this.defaultVisibility,
    this.reactions = const [],
    this.disableMarkdownShortcuts,
  });

  /// disallow_public_visibility disallows set memo as public visibility.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? disallowPublicVisibility;

  /// display_with_update_time orders and displays memo with update time.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? displayWithUpdateTime;

  /// content_length_limit is the limit of content length. Unit is byte.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? contentLengthLimit;

  /// enable_auto_compact enables auto compact for large content.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? enableAutoCompact;

  /// enable_double_click_edit enables editing on double click.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? enableDoubleClickEdit;

  /// enable_link_preview enables links preview.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? enableLinkPreview;

  /// enable_comment enables comment.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? enableComment;

  /// enable_location enables setting location for memo.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? enableLocation;

  /// default_visibility set the global memos default visibility.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? defaultVisibility;

  /// reactions is the list of reactions.
  List<String> reactions;

  /// disable_markdown_shortcuts disallow the registration of markdown shortcuts.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? disableMarkdownShortcuts;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Apiv1WorkspaceMemoRelatedSetting &&
    other.disallowPublicVisibility == disallowPublicVisibility &&
    other.displayWithUpdateTime == displayWithUpdateTime &&
    other.contentLengthLimit == contentLengthLimit &&
    other.enableAutoCompact == enableAutoCompact &&
    other.enableDoubleClickEdit == enableDoubleClickEdit &&
    other.enableLinkPreview == enableLinkPreview &&
    other.enableComment == enableComment &&
    other.enableLocation == enableLocation &&
    other.defaultVisibility == defaultVisibility &&
    _deepEquality.equals(other.reactions, reactions) &&
    other.disableMarkdownShortcuts == disableMarkdownShortcuts;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (disallowPublicVisibility == null ? 0 : disallowPublicVisibility!.hashCode) +
    (displayWithUpdateTime == null ? 0 : displayWithUpdateTime!.hashCode) +
    (contentLengthLimit == null ? 0 : contentLengthLimit!.hashCode) +
    (enableAutoCompact == null ? 0 : enableAutoCompact!.hashCode) +
    (enableDoubleClickEdit == null ? 0 : enableDoubleClickEdit!.hashCode) +
    (enableLinkPreview == null ? 0 : enableLinkPreview!.hashCode) +
    (enableComment == null ? 0 : enableComment!.hashCode) +
    (enableLocation == null ? 0 : enableLocation!.hashCode) +
    (defaultVisibility == null ? 0 : defaultVisibility!.hashCode) +
    (reactions.hashCode) +
    (disableMarkdownShortcuts == null ? 0 : disableMarkdownShortcuts!.hashCode);

  @override
  String toString() => 'Apiv1WorkspaceMemoRelatedSetting[disallowPublicVisibility=$disallowPublicVisibility, displayWithUpdateTime=$displayWithUpdateTime, contentLengthLimit=$contentLengthLimit, enableAutoCompact=$enableAutoCompact, enableDoubleClickEdit=$enableDoubleClickEdit, enableLinkPreview=$enableLinkPreview, enableComment=$enableComment, enableLocation=$enableLocation, defaultVisibility=$defaultVisibility, reactions=$reactions, disableMarkdownShortcuts=$disableMarkdownShortcuts]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.disallowPublicVisibility != null) {
      json[r'disallowPublicVisibility'] = this.disallowPublicVisibility;
    } else {
      json[r'disallowPublicVisibility'] = null;
    }
    if (this.displayWithUpdateTime != null) {
      json[r'displayWithUpdateTime'] = this.displayWithUpdateTime;
    } else {
      json[r'displayWithUpdateTime'] = null;
    }
    if (this.contentLengthLimit != null) {
      json[r'contentLengthLimit'] = this.contentLengthLimit;
    } else {
      json[r'contentLengthLimit'] = null;
    }
    if (this.enableAutoCompact != null) {
      json[r'enableAutoCompact'] = this.enableAutoCompact;
    } else {
      json[r'enableAutoCompact'] = null;
    }
    if (this.enableDoubleClickEdit != null) {
      json[r'enableDoubleClickEdit'] = this.enableDoubleClickEdit;
    } else {
      json[r'enableDoubleClickEdit'] = null;
    }
    if (this.enableLinkPreview != null) {
      json[r'enableLinkPreview'] = this.enableLinkPreview;
    } else {
      json[r'enableLinkPreview'] = null;
    }
    if (this.enableComment != null) {
      json[r'enableComment'] = this.enableComment;
    } else {
      json[r'enableComment'] = null;
    }
    if (this.enableLocation != null) {
      json[r'enableLocation'] = this.enableLocation;
    } else {
      json[r'enableLocation'] = null;
    }
    if (this.defaultVisibility != null) {
      json[r'defaultVisibility'] = this.defaultVisibility;
    } else {
      json[r'defaultVisibility'] = null;
    }
      json[r'reactions'] = this.reactions;
    if (this.disableMarkdownShortcuts != null) {
      json[r'disableMarkdownShortcuts'] = this.disableMarkdownShortcuts;
    } else {
      json[r'disableMarkdownShortcuts'] = null;
    }
    return json;
  }

  /// Returns a new [Apiv1WorkspaceMemoRelatedSetting] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Apiv1WorkspaceMemoRelatedSetting? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Apiv1WorkspaceMemoRelatedSetting[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Apiv1WorkspaceMemoRelatedSetting[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Apiv1WorkspaceMemoRelatedSetting(
        disallowPublicVisibility: mapValueOfType<bool>(json, r'disallowPublicVisibility'),
        displayWithUpdateTime: mapValueOfType<bool>(json, r'displayWithUpdateTime'),
        contentLengthLimit: mapValueOfType<int>(json, r'contentLengthLimit'),
        enableAutoCompact: mapValueOfType<bool>(json, r'enableAutoCompact'),
        enableDoubleClickEdit: mapValueOfType<bool>(json, r'enableDoubleClickEdit'),
        enableLinkPreview: mapValueOfType<bool>(json, r'enableLinkPreview'),
        enableComment: mapValueOfType<bool>(json, r'enableComment'),
        enableLocation: mapValueOfType<bool>(json, r'enableLocation'),
        defaultVisibility: mapValueOfType<String>(json, r'defaultVisibility'),
        reactions: json[r'reactions'] is Iterable
            ? (json[r'reactions'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        disableMarkdownShortcuts: mapValueOfType<bool>(json, r'disableMarkdownShortcuts'),
      );
    }
    return null;
  }

  static List<Apiv1WorkspaceMemoRelatedSetting> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Apiv1WorkspaceMemoRelatedSetting>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Apiv1WorkspaceMemoRelatedSetting.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Apiv1WorkspaceMemoRelatedSetting> mapFromJson(dynamic json) {
    final map = <String, Apiv1WorkspaceMemoRelatedSetting>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Apiv1WorkspaceMemoRelatedSetting.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Apiv1WorkspaceMemoRelatedSetting-objects as value to a dart map
  static Map<String, List<Apiv1WorkspaceMemoRelatedSetting>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Apiv1WorkspaceMemoRelatedSetting>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Apiv1WorkspaceMemoRelatedSetting.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


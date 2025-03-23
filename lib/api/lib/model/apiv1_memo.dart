//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Apiv1Memo {
  /// Returns a new [Apiv1Memo] instance.
  Apiv1Memo({
    this.name,
    this.state,
    this.creator,
    this.createTime,
    this.updateTime,
    this.displayTime,
    this.content,
    this.nodes = const [],
    this.visibility,
    this.tags = const [],
    this.pinned,
    this.resources = const [],
    this.relations = const [],
    this.reactions = const [],
    this.property,
    this.parent,
    this.snippet,
    this.location,
  });

  /// The name of the memo.  Format: memos/{memo}, memo is the user defined id or uuid.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  V1State? state;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? creator;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? updateTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? displayTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? content;

  List<V1Node> nodes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  V1Visibility? visibility;

  List<String> tags;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? pinned;

  List<V1Resource> resources;

  List<V1MemoRelation> relations;

  List<V1Reaction> reactions;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  V1MemoProperty? property;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? parent;

  /// The snippet of the memo content. Plain text only.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? snippet;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Apiv1Location? location;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Apiv1Memo &&
    other.name == name &&
    other.state == state &&
    other.creator == creator &&
    other.createTime == createTime &&
    other.updateTime == updateTime &&
    other.displayTime == displayTime &&
    other.content == content &&
    _deepEquality.equals(other.nodes, nodes) &&
    other.visibility == visibility &&
    _deepEquality.equals(other.tags, tags) &&
    other.pinned == pinned &&
    _deepEquality.equals(other.resources, resources) &&
    _deepEquality.equals(other.relations, relations) &&
    _deepEquality.equals(other.reactions, reactions) &&
    other.property == property &&
    other.parent == parent &&
    other.snippet == snippet &&
    other.location == location;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (state == null ? 0 : state!.hashCode) +
    (creator == null ? 0 : creator!.hashCode) +
    (createTime == null ? 0 : createTime!.hashCode) +
    (updateTime == null ? 0 : updateTime!.hashCode) +
    (displayTime == null ? 0 : displayTime!.hashCode) +
    (content == null ? 0 : content!.hashCode) +
    (nodes.hashCode) +
    (visibility == null ? 0 : visibility!.hashCode) +
    (tags.hashCode) +
    (pinned == null ? 0 : pinned!.hashCode) +
    (resources.hashCode) +
    (relations.hashCode) +
    (reactions.hashCode) +
    (property == null ? 0 : property!.hashCode) +
    (parent == null ? 0 : parent!.hashCode) +
    (snippet == null ? 0 : snippet!.hashCode) +
    (location == null ? 0 : location!.hashCode);

  @override
  String toString() => 'Apiv1Memo[name=$name, state=$state, creator=$creator, createTime=$createTime, updateTime=$updateTime, displayTime=$displayTime, content=$content, nodes=$nodes, visibility=$visibility, tags=$tags, pinned=$pinned, resources=$resources, relations=$relations, reactions=$reactions, property=$property, parent=$parent, snippet=$snippet, location=$location]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.state != null) {
      json[r'state'] = this.state;
    } else {
      json[r'state'] = null;
    }
    if (this.creator != null) {
      json[r'creator'] = this.creator;
    } else {
      json[r'creator'] = null;
    }
    if (this.createTime != null) {
      json[r'createTime'] = this.createTime!.toUtc().toIso8601String();
    } else {
      json[r'createTime'] = null;
    }
    if (this.updateTime != null) {
      json[r'updateTime'] = this.updateTime!.toUtc().toIso8601String();
    } else {
      json[r'updateTime'] = null;
    }
    if (this.displayTime != null) {
      json[r'displayTime'] = this.displayTime!.toUtc().toIso8601String();
    } else {
      json[r'displayTime'] = null;
    }
    if (this.content != null) {
      json[r'content'] = this.content;
    } else {
      json[r'content'] = null;
    }
      json[r'nodes'] = this.nodes;
    if (this.visibility != null) {
      json[r'visibility'] = this.visibility;
    } else {
      json[r'visibility'] = null;
    }
      json[r'tags'] = this.tags;
    if (this.pinned != null) {
      json[r'pinned'] = this.pinned;
    } else {
      json[r'pinned'] = null;
    }
      json[r'resources'] = this.resources;
      json[r'relations'] = this.relations;
      json[r'reactions'] = this.reactions;
    if (this.property != null) {
      json[r'property'] = this.property;
    } else {
      json[r'property'] = null;
    }
    if (this.parent != null) {
      json[r'parent'] = this.parent;
    } else {
      json[r'parent'] = null;
    }
    if (this.snippet != null) {
      json[r'snippet'] = this.snippet;
    } else {
      json[r'snippet'] = null;
    }
    if (this.location != null) {
      json[r'location'] = this.location;
    } else {
      json[r'location'] = null;
    }
    return json;
  }

  /// Returns a new [Apiv1Memo] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Apiv1Memo? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Apiv1Memo[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Apiv1Memo[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Apiv1Memo(
        name: mapValueOfType<String>(json, r'name'),
        state: V1State.fromJson(json[r'state']),
        creator: mapValueOfType<String>(json, r'creator'),
        createTime: mapDateTime(json, r'createTime', r''),
        updateTime: mapDateTime(json, r'updateTime', r''),
        displayTime: mapDateTime(json, r'displayTime', r''),
        content: mapValueOfType<String>(json, r'content'),
        nodes: V1Node.listFromJson(json[r'nodes']),
        visibility: V1Visibility.fromJson(json[r'visibility']),
        tags: json[r'tags'] is Iterable
            ? (json[r'tags'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        pinned: mapValueOfType<bool>(json, r'pinned'),
        resources: V1Resource.listFromJson(json[r'resources']),
        relations: V1MemoRelation.listFromJson(json[r'relations']),
        reactions: V1Reaction.listFromJson(json[r'reactions']),
        property: V1MemoProperty.fromJson(json[r'property']),
        parent: mapValueOfType<String>(json, r'parent'),
        snippet: mapValueOfType<String>(json, r'snippet'),
        location: Apiv1Location.fromJson(json[r'location']),
      );
    }
    return null;
  }

  static List<Apiv1Memo> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Apiv1Memo>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Apiv1Memo.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Apiv1Memo> mapFromJson(dynamic json) {
    final map = <String, Apiv1Memo>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Apiv1Memo.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Apiv1Memo-objects as value to a dart map
  static Map<String, List<Apiv1Memo>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Apiv1Memo>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Apiv1Memo.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


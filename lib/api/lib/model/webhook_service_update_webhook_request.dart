//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class WebhookServiceUpdateWebhookRequest {
  /// Returns a new [WebhookServiceUpdateWebhookRequest] instance.
  WebhookServiceUpdateWebhookRequest({
    this.creator,
    this.createTime,
    this.updateTime,
    this.name,
    this.url,
  });

  /// The name of the creator.
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
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? url;

  @override
  bool operator ==(Object other) => identical(this, other) || other is WebhookServiceUpdateWebhookRequest &&
    other.creator == creator &&
    other.createTime == createTime &&
    other.updateTime == updateTime &&
    other.name == name &&
    other.url == url;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (creator == null ? 0 : creator!.hashCode) +
    (createTime == null ? 0 : createTime!.hashCode) +
    (updateTime == null ? 0 : updateTime!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (url == null ? 0 : url!.hashCode);

  @override
  String toString() => 'WebhookServiceUpdateWebhookRequest[creator=$creator, createTime=$createTime, updateTime=$updateTime, name=$name, url=$url]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
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
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.url != null) {
      json[r'url'] = this.url;
    } else {
      json[r'url'] = null;
    }
    return json;
  }

  /// Returns a new [WebhookServiceUpdateWebhookRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WebhookServiceUpdateWebhookRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "WebhookServiceUpdateWebhookRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "WebhookServiceUpdateWebhookRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return WebhookServiceUpdateWebhookRequest(
        creator: mapValueOfType<String>(json, r'creator'),
        createTime: mapDateTime(json, r'createTime', r''),
        updateTime: mapDateTime(json, r'updateTime', r''),
        name: mapValueOfType<String>(json, r'name'),
        url: mapValueOfType<String>(json, r'url'),
      );
    }
    return null;
  }

  static List<WebhookServiceUpdateWebhookRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WebhookServiceUpdateWebhookRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WebhookServiceUpdateWebhookRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WebhookServiceUpdateWebhookRequest> mapFromJson(dynamic json) {
    final map = <String, WebhookServiceUpdateWebhookRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WebhookServiceUpdateWebhookRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WebhookServiceUpdateWebhookRequest-objects as value to a dart map
  static Map<String, List<WebhookServiceUpdateWebhookRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<WebhookServiceUpdateWebhookRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WebhookServiceUpdateWebhookRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


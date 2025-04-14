//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PublicTestWebhookRequest {
  /// Returns a new [PublicTestWebhookRequest] instance.
  PublicTestWebhookRequest({
    this.data,
    this.webhookType,
  });

  Object? data;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? webhookType;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PublicTestWebhookRequest &&
    other.data == data &&
    other.webhookType == webhookType;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (data == null ? 0 : data!.hashCode) +
    (webhookType == null ? 0 : webhookType!.hashCode);

  @override
  String toString() => 'PublicTestWebhookRequest[data=$data, webhookType=$webhookType]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.data != null) {
      json[r'data'] = this.data;
    } else {
      json[r'data'] = null;
    }
    if (this.webhookType != null) {
      json[r'webhookType'] = this.webhookType;
    } else {
      json[r'webhookType'] = null;
    }
    return json;
  }

  /// Returns a new [PublicTestWebhookRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PublicTestWebhookRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PublicTestWebhookRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PublicTestWebhookRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PublicTestWebhookRequest(
        data: mapValueOfType<Object>(json, r'data'),
        webhookType: mapValueOfType<String>(json, r'webhookType'),
      );
    }
    return null;
  }

  static List<PublicTestWebhookRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PublicTestWebhookRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PublicTestWebhookRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PublicTestWebhookRequest> mapFromJson(dynamic json) {
    final map = <String, PublicTestWebhookRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PublicTestWebhookRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PublicTestWebhookRequest-objects as value to a dart map
  static Map<String, List<PublicTestWebhookRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PublicTestWebhookRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PublicTestWebhookRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


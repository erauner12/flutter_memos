//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesUpdateAttachmentsOrderRequest {
  /// Returns a new [NotesUpdateAttachmentsOrderRequest] instance.
  NotesUpdateAttachmentsOrderRequest({
    this.attachments = const [],
  });

  List<NotesUpdateAttachmentsOrderRequestAttachmentsInner> attachments;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesUpdateAttachmentsOrderRequest &&
    _deepEquality.equals(other.attachments, attachments);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (attachments.hashCode);

  @override
  String toString() => 'NotesUpdateAttachmentsOrderRequest[attachments=$attachments]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'attachments'] = this.attachments;
    return json;
  }

  /// Returns a new [NotesUpdateAttachmentsOrderRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesUpdateAttachmentsOrderRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesUpdateAttachmentsOrderRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesUpdateAttachmentsOrderRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesUpdateAttachmentsOrderRequest(
        attachments: NotesUpdateAttachmentsOrderRequestAttachmentsInner.listFromJson(json[r'attachments']),
      );
    }
    return null;
  }

  static List<NotesUpdateAttachmentsOrderRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesUpdateAttachmentsOrderRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesUpdateAttachmentsOrderRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesUpdateAttachmentsOrderRequest> mapFromJson(dynamic json) {
    final map = <String, NotesUpdateAttachmentsOrderRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesUpdateAttachmentsOrderRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesUpdateAttachmentsOrderRequest-objects as value to a dart map
  static Map<String, List<NotesUpdateAttachmentsOrderRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesUpdateAttachmentsOrderRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesUpdateAttachmentsOrderRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'attachments',
  };
}


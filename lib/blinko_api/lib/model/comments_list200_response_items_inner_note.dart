//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CommentsList200ResponseItemsInnerNote {
  /// Returns a new [CommentsList200ResponseItemsInnerNote] instance.
  CommentsList200ResponseItemsInnerNote({
    required this.account,
  });

  CommentsList200ResponseItemsInnerNoteAccount? account;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CommentsList200ResponseItemsInnerNote &&
    other.account == account;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (account == null ? 0 : account!.hashCode);

  @override
  String toString() => 'CommentsList200ResponseItemsInnerNote[account=$account]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.account != null) {
      json[r'account'] = this.account;
    } else {
      json[r'account'] = null;
    }
    return json;
  }

  /// Returns a new [CommentsList200ResponseItemsInnerNote] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CommentsList200ResponseItemsInnerNote? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CommentsList200ResponseItemsInnerNote[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CommentsList200ResponseItemsInnerNote[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CommentsList200ResponseItemsInnerNote(
        account: CommentsList200ResponseItemsInnerNoteAccount.fromJson(json[r'account']),
      );
    }
    return null;
  }

  static List<CommentsList200ResponseItemsInnerNote> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CommentsList200ResponseItemsInnerNote>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CommentsList200ResponseItemsInnerNote.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CommentsList200ResponseItemsInnerNote> mapFromJson(dynamic json) {
    final map = <String, CommentsList200ResponseItemsInnerNote>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CommentsList200ResponseItemsInnerNote.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CommentsList200ResponseItemsInnerNote-objects as value to a dart map
  static Map<String, List<CommentsList200ResponseItemsInnerNote>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CommentsList200ResponseItemsInnerNote>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CommentsList200ResponseItemsInnerNote.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'account',
  };
}


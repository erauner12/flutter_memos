//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesPublicDetail200Response {
  /// Returns a new [NotesPublicDetail200Response] instance.
  NotesPublicDetail200Response({
    required this.hasPassword,
    required this.data,
    required this.error,
  });

  bool hasPassword;

  NotesPublicDetail200ResponseData? data;

  NotesPublicDetail200ResponseErrorEnum? error;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesPublicDetail200Response &&
    other.hasPassword == hasPassword &&
    other.data == data &&
    other.error == error;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (hasPassword.hashCode) +
    (data == null ? 0 : data!.hashCode) +
    (error == null ? 0 : error!.hashCode);

  @override
  String toString() => 'NotesPublicDetail200Response[hasPassword=$hasPassword, data=$data, error=$error]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'hasPassword'] = this.hasPassword;
    if (this.data != null) {
      json[r'data'] = this.data;
    } else {
      json[r'data'] = null;
    }
    if (this.error != null) {
      json[r'error'] = this.error;
    } else {
      json[r'error'] = null;
    }
    return json;
  }

  /// Returns a new [NotesPublicDetail200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesPublicDetail200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesPublicDetail200Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesPublicDetail200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesPublicDetail200Response(
        hasPassword: mapValueOfType<bool>(json, r'hasPassword')!,
        data: NotesPublicDetail200ResponseData.fromJson(json[r'data']),
        error: NotesPublicDetail200ResponseErrorEnum.fromJson(json[r'error']),
      );
    }
    return null;
  }

  static List<NotesPublicDetail200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesPublicDetail200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesPublicDetail200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesPublicDetail200Response> mapFromJson(dynamic json) {
    final map = <String, NotesPublicDetail200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesPublicDetail200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesPublicDetail200Response-objects as value to a dart map
  static Map<String, List<NotesPublicDetail200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesPublicDetail200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesPublicDetail200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'hasPassword',
    'data',
    'error',
  };
}


class NotesPublicDetail200ResponseErrorEnum {
  /// Instantiate a new enum with the provided [value].
  const NotesPublicDetail200ResponseErrorEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const expired = NotesPublicDetail200ResponseErrorEnum._(r'expired');

  /// List of all possible values in this [enum][NotesPublicDetail200ResponseErrorEnum].
  static const values = <NotesPublicDetail200ResponseErrorEnum>[
    expired,
  ];

  static NotesPublicDetail200ResponseErrorEnum? fromJson(dynamic value) => NotesPublicDetail200ResponseErrorEnumTypeTransformer().decode(value);

  static List<NotesPublicDetail200ResponseErrorEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesPublicDetail200ResponseErrorEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesPublicDetail200ResponseErrorEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NotesPublicDetail200ResponseErrorEnum] to String,
/// and [decode] dynamic data back to [NotesPublicDetail200ResponseErrorEnum].
class NotesPublicDetail200ResponseErrorEnumTypeTransformer {
  factory NotesPublicDetail200ResponseErrorEnumTypeTransformer() => _instance ??= const NotesPublicDetail200ResponseErrorEnumTypeTransformer._();

  const NotesPublicDetail200ResponseErrorEnumTypeTransformer._();

  String encode(NotesPublicDetail200ResponseErrorEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a NotesPublicDetail200ResponseErrorEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NotesPublicDetail200ResponseErrorEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'expired': return NotesPublicDetail200ResponseErrorEnum.expired;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [NotesPublicDetail200ResponseErrorEnumTypeTransformer] instance.
  static NotesPublicDetail200ResponseErrorEnumTypeTransformer? _instance;
}



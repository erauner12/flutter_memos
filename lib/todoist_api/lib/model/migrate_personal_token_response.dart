//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MigratePersonalTokenResponse {
  /// Returns a new [MigratePersonalTokenResponse] instance.
  MigratePersonalTokenResponse({
    required this.accessToken,
    required this.tokenType,
  });

  String? accessToken;

  MigratePersonalTokenResponseTokenTypeEnum tokenType;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MigratePersonalTokenResponse &&
    other.accessToken == accessToken &&
    other.tokenType == tokenType;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (accessToken == null ? 0 : accessToken!.hashCode) +
    (tokenType.hashCode);

  @override
  String toString() => 'MigratePersonalTokenResponse[accessToken=$accessToken, tokenType=$tokenType]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.accessToken != null) {
      json[r'access_token'] = this.accessToken;
    } else {
      json[r'access_token'] = null;
    }
      json[r'token_type'] = this.tokenType;
    return json;
  }

  /// Returns a new [MigratePersonalTokenResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MigratePersonalTokenResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "MigratePersonalTokenResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "MigratePersonalTokenResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MigratePersonalTokenResponse(
        accessToken: mapValueOfType<String>(json, r'access_token'),
        tokenType: MigratePersonalTokenResponseTokenTypeEnum.fromJson(json[r'token_type'])!,
      );
    }
    return null;
  }

  static List<MigratePersonalTokenResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MigratePersonalTokenResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MigratePersonalTokenResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MigratePersonalTokenResponse> mapFromJson(dynamic json) {
    final map = <String, MigratePersonalTokenResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MigratePersonalTokenResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MigratePersonalTokenResponse-objects as value to a dart map
  static Map<String, List<MigratePersonalTokenResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MigratePersonalTokenResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MigratePersonalTokenResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'access_token',
    'token_type',
  };
}


class MigratePersonalTokenResponseTokenTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const MigratePersonalTokenResponseTokenTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const bearer = MigratePersonalTokenResponseTokenTypeEnum._(r'Bearer');

  /// List of all possible values in this [enum][MigratePersonalTokenResponseTokenTypeEnum].
  static const values = <MigratePersonalTokenResponseTokenTypeEnum>[
    bearer,
  ];

  static MigratePersonalTokenResponseTokenTypeEnum? fromJson(dynamic value) => MigratePersonalTokenResponseTokenTypeEnumTypeTransformer().decode(value);

  static List<MigratePersonalTokenResponseTokenTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MigratePersonalTokenResponseTokenTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MigratePersonalTokenResponseTokenTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MigratePersonalTokenResponseTokenTypeEnum] to String,
/// and [decode] dynamic data back to [MigratePersonalTokenResponseTokenTypeEnum].
class MigratePersonalTokenResponseTokenTypeEnumTypeTransformer {
  factory MigratePersonalTokenResponseTokenTypeEnumTypeTransformer() => _instance ??= const MigratePersonalTokenResponseTokenTypeEnumTypeTransformer._();

  const MigratePersonalTokenResponseTokenTypeEnumTypeTransformer._();

  String encode(MigratePersonalTokenResponseTokenTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a MigratePersonalTokenResponseTokenTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MigratePersonalTokenResponseTokenTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'Bearer': return MigratePersonalTokenResponseTokenTypeEnum.bearer;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [MigratePersonalTokenResponseTokenTypeEnumTypeTransformer] instance.
  static MigratePersonalTokenResponseTokenTypeEnumTypeTransformer? _instance;
}



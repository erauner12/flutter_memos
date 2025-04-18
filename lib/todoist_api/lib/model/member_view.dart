//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MemberView {
  /// Returns a new [MemberView] instance.
  MemberView({
    required this.userId,
    required this.workspaceId,
    required this.userEmail,
    required this.fullName,
    required this.timezone,
    required this.role,
    this.imageId,
    this.isDeleted = false,
  });

  String userId;

  String workspaceId;

  String userEmail;

  String fullName;

  String timezone;

  WorkspaceRole role;

  String? imageId;

  bool isDeleted;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MemberView &&
    other.userId == userId &&
    other.workspaceId == workspaceId &&
    other.userEmail == userEmail &&
    other.fullName == fullName &&
    other.timezone == timezone &&
    other.role == role &&
    other.imageId == imageId &&
    other.isDeleted == isDeleted;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (userId.hashCode) +
    (workspaceId.hashCode) +
    (userEmail.hashCode) +
    (fullName.hashCode) +
    (timezone.hashCode) +
    (role.hashCode) +
    (imageId == null ? 0 : imageId!.hashCode) +
    (isDeleted.hashCode);

  @override
  String toString() => 'MemberView[userId=$userId, workspaceId=$workspaceId, userEmail=$userEmail, fullName=$fullName, timezone=$timezone, role=$role, imageId=$imageId, isDeleted=$isDeleted]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'user_id'] = this.userId;
      json[r'workspace_id'] = this.workspaceId;
      json[r'user_email'] = this.userEmail;
      json[r'full_name'] = this.fullName;
      json[r'timezone'] = this.timezone;
      json[r'role'] = this.role;
    if (this.imageId != null) {
      json[r'image_id'] = this.imageId;
    } else {
      json[r'image_id'] = null;
    }
      json[r'is_deleted'] = this.isDeleted;
    return json;
  }

  /// Returns a new [MemberView] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MemberView? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "MemberView[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "MemberView[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MemberView(
        userId: mapValueOfType<String>(json, r'user_id')!,
        workspaceId: mapValueOfType<String>(json, r'workspace_id')!,
        userEmail: mapValueOfType<String>(json, r'user_email')!,
        fullName: mapValueOfType<String>(json, r'full_name')!,
        timezone: mapValueOfType<String>(json, r'timezone')!,
        role: WorkspaceRole.fromJson(json[r'role'])!,
        imageId: mapValueOfType<String>(json, r'image_id'),
        isDeleted: mapValueOfType<bool>(json, r'is_deleted') ?? false,
      );
    }
    return null;
  }

  static List<MemberView> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MemberView>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MemberView.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MemberView> mapFromJson(dynamic json) {
    final map = <String, MemberView>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MemberView.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MemberView-objects as value to a dart map
  static Map<String, List<MemberView>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MemberView>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MemberView.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'user_id',
    'workspace_id',
    'user_email',
    'full_name',
    'timezone',
    'role',
  };
}


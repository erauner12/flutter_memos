//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UploadResult {
  /// Returns a new [UploadResult] instance.
  UploadResult({
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.resourceType,
    this.image,
    this.imageWidth,
    this.imageHeight,
    this.uploadState = const UploadResultUploadStateEnum._('pending'),
  });

  String fileUrl;

  String fileName;

  int fileSize;

  String fileType;

  String resourceType;

  String? image;

  int? imageWidth;

  int? imageHeight;

  UploadResultUploadStateEnum uploadState;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UploadResult &&
    other.fileUrl == fileUrl &&
    other.fileName == fileName &&
    other.fileSize == fileSize &&
    other.fileType == fileType &&
    other.resourceType == resourceType &&
    other.image == image &&
    other.imageWidth == imageWidth &&
    other.imageHeight == imageHeight &&
    other.uploadState == uploadState;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (fileUrl.hashCode) +
    (fileName.hashCode) +
    (fileSize.hashCode) +
    (fileType.hashCode) +
    (resourceType.hashCode) +
    (image == null ? 0 : image!.hashCode) +
    (imageWidth == null ? 0 : imageWidth!.hashCode) +
    (imageHeight == null ? 0 : imageHeight!.hashCode) +
    (uploadState.hashCode);

  @override
  String toString() => 'UploadResult[fileUrl=$fileUrl, fileName=$fileName, fileSize=$fileSize, fileType=$fileType, resourceType=$resourceType, image=$image, imageWidth=$imageWidth, imageHeight=$imageHeight, uploadState=$uploadState]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'file_url'] = this.fileUrl;
      json[r'file_name'] = this.fileName;
      json[r'file_size'] = this.fileSize;
      json[r'file_type'] = this.fileType;
      json[r'resource_type'] = this.resourceType;
    if (this.image != null) {
      json[r'image'] = this.image;
    } else {
      json[r'image'] = null;
    }
    if (this.imageWidth != null) {
      json[r'image_width'] = this.imageWidth;
    } else {
      json[r'image_width'] = null;
    }
    if (this.imageHeight != null) {
      json[r'image_height'] = this.imageHeight;
    } else {
      json[r'image_height'] = null;
    }
      json[r'upload_state'] = this.uploadState;
    return json;
  }

  /// Returns a new [UploadResult] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UploadResult? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UploadResult[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UploadResult[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UploadResult(
        fileUrl: mapValueOfType<String>(json, r'file_url')!,
        fileName: mapValueOfType<String>(json, r'file_name')!,
        fileSize: mapValueOfType<int>(json, r'file_size')!,
        fileType: mapValueOfType<String>(json, r'file_type')!,
        resourceType: mapValueOfType<String>(json, r'resource_type')!,
        image: mapValueOfType<String>(json, r'image'),
        imageWidth: mapValueOfType<int>(json, r'image_width'),
        imageHeight: mapValueOfType<int>(json, r'image_height'),
        uploadState: UploadResultUploadStateEnum.fromJson(json[r'upload_state']) ?? 'pending',
      );
    }
    return null;
  }

  static List<UploadResult> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UploadResult>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UploadResult.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UploadResult> mapFromJson(dynamic json) {
    final map = <String, UploadResult>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UploadResult.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UploadResult-objects as value to a dart map
  static Map<String, List<UploadResult>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UploadResult>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UploadResult.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'file_url',
    'file_name',
    'file_size',
    'file_type',
    'resource_type',
  };
}


class UploadResultUploadStateEnum {
  /// Instantiate a new enum with the provided [value].
  const UploadResultUploadStateEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const pending = UploadResultUploadStateEnum._(r'pending');
  static const completed = UploadResultUploadStateEnum._(r'completed');

  /// List of all possible values in this [enum][UploadResultUploadStateEnum].
  static const values = <UploadResultUploadStateEnum>[
    pending,
    completed,
  ];

  static UploadResultUploadStateEnum? fromJson(dynamic value) => UploadResultUploadStateEnumTypeTransformer().decode(value);

  static List<UploadResultUploadStateEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UploadResultUploadStateEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UploadResultUploadStateEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UploadResultUploadStateEnum] to String,
/// and [decode] dynamic data back to [UploadResultUploadStateEnum].
class UploadResultUploadStateEnumTypeTransformer {
  factory UploadResultUploadStateEnumTypeTransformer() => _instance ??= const UploadResultUploadStateEnumTypeTransformer._();

  const UploadResultUploadStateEnumTypeTransformer._();

  String encode(UploadResultUploadStateEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a UploadResultUploadStateEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UploadResultUploadStateEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'pending': return UploadResultUploadStateEnum.pending;
        case r'completed': return UploadResultUploadStateEnum.completed;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [UploadResultUploadStateEnumTypeTransformer] instance.
  static UploadResultUploadStateEnumTypeTransformer? _instance;
}



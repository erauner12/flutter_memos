//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotesListRequest {
  /// Returns a new [NotesListRequest] instance.
  NotesListRequest({
    this.tagId,
    this.page = 1,
    this.size = 30,
    this.orderBy = const NotesListRequestOrderByEnum._('desc'),
    this.type,
    this.isArchived,
    this.isShare,
    this.isRecycle = false,
    this.searchText = '',
    this.withoutTag = false,
    this.withFile = false,
    this.withLink = false,
    this.isUseAiQuery = false,
    this.startDate,
    this.endDate,
    this.hasTodo = false,
  });

  num? tagId;

  num page;

  num size;

  NotesListRequestOrderByEnum orderBy;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  NotesListRequestType? type;

  bool? isArchived;

  bool? isShare;

  bool isRecycle;

  String searchText;

  bool withoutTag;

  bool withFile;

  bool withLink;

  bool isUseAiQuery;

  NotesListRequestStartDate? startDate;

  NotesListRequestStartDate? endDate;

  bool hasTodo;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotesListRequest &&
    other.tagId == tagId &&
    other.page == page &&
    other.size == size &&
    other.orderBy == orderBy &&
    other.type == type &&
    other.isArchived == isArchived &&
    other.isShare == isShare &&
    other.isRecycle == isRecycle &&
    other.searchText == searchText &&
    other.withoutTag == withoutTag &&
    other.withFile == withFile &&
    other.withLink == withLink &&
    other.isUseAiQuery == isUseAiQuery &&
    other.startDate == startDate &&
    other.endDate == endDate &&
    other.hasTodo == hasTodo;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (tagId == null ? 0 : tagId!.hashCode) +
    (page.hashCode) +
    (size.hashCode) +
    (orderBy.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (isArchived == null ? 0 : isArchived!.hashCode) +
    (isShare == null ? 0 : isShare!.hashCode) +
    (isRecycle.hashCode) +
    (searchText.hashCode) +
    (withoutTag.hashCode) +
    (withFile.hashCode) +
    (withLink.hashCode) +
    (isUseAiQuery.hashCode) +
    (startDate == null ? 0 : startDate!.hashCode) +
    (endDate == null ? 0 : endDate!.hashCode) +
    (hasTodo.hashCode);

  @override
  String toString() => 'NotesListRequest[tagId=$tagId, page=$page, size=$size, orderBy=$orderBy, type=$type, isArchived=$isArchived, isShare=$isShare, isRecycle=$isRecycle, searchText=$searchText, withoutTag=$withoutTag, withFile=$withFile, withLink=$withLink, isUseAiQuery=$isUseAiQuery, startDate=$startDate, endDate=$endDate, hasTodo=$hasTodo]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.tagId != null) {
      json[r'tagId'] = this.tagId;
    } else {
      json[r'tagId'] = null;
    }
      json[r'page'] = this.page;
      json[r'size'] = this.size;
      json[r'orderBy'] = this.orderBy;
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.isArchived != null) {
      json[r'isArchived'] = this.isArchived;
    } else {
      json[r'isArchived'] = null;
    }
    if (this.isShare != null) {
      json[r'isShare'] = this.isShare;
    } else {
      json[r'isShare'] = null;
    }
      json[r'isRecycle'] = this.isRecycle;
      json[r'searchText'] = this.searchText;
      json[r'withoutTag'] = this.withoutTag;
      json[r'withFile'] = this.withFile;
      json[r'withLink'] = this.withLink;
      json[r'isUseAiQuery'] = this.isUseAiQuery;
    if (this.startDate != null) {
      json[r'startDate'] = this.startDate;
    } else {
      json[r'startDate'] = null;
    }
    if (this.endDate != null) {
      json[r'endDate'] = null;
    } else {
      json[r'endDate'] = null;
    }
      json[r'hasTodo'] = this.hasTodo;
    return json;
  }

  /// Returns a new [NotesListRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotesListRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotesListRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotesListRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotesListRequest(
        tagId: json[r'tagId'] == null
            ? null
            : num.parse('${json[r'tagId']}'),
        page: num.parse('${json[r'page']}'),
        size: num.parse('${json[r'size']}'),
        // Cast the result of fromJson to the correct enum type or provide a default
        orderBy: NotesListRequestOrderByEnum.fromJson(json[r'orderBy']) ?? NotesListRequestOrderByEnum.desc,
        type: NotesListRequestType.fromJson(json[r'type']),
        isArchived: mapValueOfType<bool>(json, r'isArchived'),
        isShare: mapValueOfType<bool>(json, r'isShare'),
        isRecycle: mapValueOfType<bool>(json, r'isRecycle') ?? false,
        searchText: mapValueOfType<String>(json, r'searchText') ?? '',
        withoutTag: mapValueOfType<bool>(json, r'withoutTag') ?? false,
        withFile: mapValueOfType<bool>(json, r'withFile') ?? false,
        withLink: mapValueOfType<bool>(json, r'withLink') ?? false,
        isUseAiQuery: mapValueOfType<bool>(json, r'isUseAiQuery') ?? false,
        startDate: NotesListRequestStartDate.fromJson(json[r'startDate']),
        endDate: NotesListRequestStartDate.fromJson(json[r'endDate']),
        hasTodo: mapValueOfType<bool>(json, r'hasTodo') ?? false,
      );
    }
    return null;
  }

  static List<NotesListRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesListRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesListRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotesListRequest> mapFromJson(dynamic json) {
    final map = <String, NotesListRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotesListRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotesListRequest-objects as value to a dart map
  static Map<String, List<NotesListRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotesListRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotesListRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class NotesListRequestOrderByEnum {
  /// Instantiate a new enum with the provided [value].
  const NotesListRequestOrderByEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const asc = NotesListRequestOrderByEnum._(r'asc');
  static const desc = NotesListRequestOrderByEnum._(r'desc');

  /// List of all possible values in this [enum][NotesListRequestOrderByEnum].
  static const values = <NotesListRequestOrderByEnum>[
    asc,
    desc,
  ];

  static NotesListRequestOrderByEnum? fromJson(dynamic value) => NotesListRequestOrderByEnumTypeTransformer().decode(value);

  static List<NotesListRequestOrderByEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotesListRequestOrderByEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotesListRequestOrderByEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NotesListRequestOrderByEnum] to String,
/// and [decode] dynamic data back to [NotesListRequestOrderByEnum].
class NotesListRequestOrderByEnumTypeTransformer {
  factory NotesListRequestOrderByEnumTypeTransformer() => _instance ??= const NotesListRequestOrderByEnumTypeTransformer._();

  const NotesListRequestOrderByEnumTypeTransformer._();

  String encode(NotesListRequestOrderByEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a NotesListRequestOrderByEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NotesListRequestOrderByEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'asc': return NotesListRequestOrderByEnum.asc;
        case r'desc': return NotesListRequestOrderByEnum.desc;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [NotesListRequestOrderByEnumTypeTransformer] instance.
  static NotesListRequestOrderByEnumTypeTransformer? _instance;
}
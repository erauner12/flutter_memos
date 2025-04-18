//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class EmailObjectType {
  /// Instantiate a new enum with the provided [value].
  const EmailObjectType._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const project = EmailObjectType._(r'project');
  static const projectComments = EmailObjectType._(r'project_comments');
  static const task = EmailObjectType._(r'task');

  /// List of all possible values in this [enum][EmailObjectType].
  static const values = <EmailObjectType>[
    project,
    projectComments,
    task,
  ];

  static EmailObjectType? fromJson(dynamic value) => EmailObjectTypeTypeTransformer().decode(value);

  static List<EmailObjectType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <EmailObjectType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EmailObjectType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [EmailObjectType] to String,
/// and [decode] dynamic data back to [EmailObjectType].
class EmailObjectTypeTypeTransformer {
  factory EmailObjectTypeTypeTransformer() => _instance ??= const EmailObjectTypeTypeTransformer._();

  const EmailObjectTypeTypeTransformer._();

  String encode(EmailObjectType data) => data.value;

  /// Decodes a [dynamic value][data] to a EmailObjectType.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  EmailObjectType? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'project': return EmailObjectType.project;
        case r'project_comments': return EmailObjectType.projectComments;
        case r'task': return EmailObjectType.task;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [EmailObjectTypeTypeTransformer] instance.
  static EmailObjectTypeTypeTransformer? _instance;
}


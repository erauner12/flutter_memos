//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class EmailObjectTypePre9221 {
  /// Instantiate a new enum with the provided [value].
  const EmailObjectTypePre9221._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const project = EmailObjectTypePre9221._(r'project');
  static const projectComments = EmailObjectTypePre9221._(r'project_comments');
  static const item = EmailObjectTypePre9221._(r'item');

  /// List of all possible values in this [enum][EmailObjectTypePre9221].
  static const values = <EmailObjectTypePre9221>[
    project,
    projectComments,
    item,
  ];

  static EmailObjectTypePre9221? fromJson(dynamic value) => EmailObjectTypePre9221TypeTransformer().decode(value);

  static List<EmailObjectTypePre9221> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <EmailObjectTypePre9221>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EmailObjectTypePre9221.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [EmailObjectTypePre9221] to String,
/// and [decode] dynamic data back to [EmailObjectTypePre9221].
class EmailObjectTypePre9221TypeTransformer {
  factory EmailObjectTypePre9221TypeTransformer() => _instance ??= const EmailObjectTypePre9221TypeTransformer._();

  const EmailObjectTypePre9221TypeTransformer._();

  String encode(EmailObjectTypePre9221 data) => data.value;

  /// Decodes a [dynamic value][data] to a EmailObjectTypePre9221.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  EmailObjectTypePre9221? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'project': return EmailObjectTypePre9221.project;
        case r'project_comments': return EmailObjectTypePre9221.projectComments;
        case r'item': return EmailObjectTypePre9221.item;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [EmailObjectTypePre9221TypeTransformer] instance.
  static EmailObjectTypePre9221TypeTransformer? _instance;
}


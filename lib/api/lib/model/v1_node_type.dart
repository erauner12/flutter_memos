//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

///  - LINE_BREAK: Block nodes.  - TEXT: Inline nodes.
class V1NodeType {
  /// Instantiate a new enum with the provided [value].
  const V1NodeType._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const NODE_UNSPECIFIED = V1NodeType._(r'NODE_UNSPECIFIED');
  static const LINE_BREAK = V1NodeType._(r'LINE_BREAK');
  static const PARAGRAPH = V1NodeType._(r'PARAGRAPH');
  static const CODE_BLOCK = V1NodeType._(r'CODE_BLOCK');
  static const HEADING = V1NodeType._(r'HEADING');
  static const HORIZONTAL_RULE = V1NodeType._(r'HORIZONTAL_RULE');
  static const BLOCKQUOTE = V1NodeType._(r'BLOCKQUOTE');
  static const LIST = V1NodeType._(r'LIST');
  static const ORDERED_LIST_ITEM = V1NodeType._(r'ORDERED_LIST_ITEM');
  static const UNORDERED_LIST_ITEM = V1NodeType._(r'UNORDERED_LIST_ITEM');
  static const TASK_LIST_ITEM = V1NodeType._(r'TASK_LIST_ITEM');
  static const MATH_BLOCK = V1NodeType._(r'MATH_BLOCK');
  static const TABLE = V1NodeType._(r'TABLE');
  static const EMBEDDED_CONTENT = V1NodeType._(r'EMBEDDED_CONTENT');
  static const TEXT = V1NodeType._(r'TEXT');
  static const BOLD = V1NodeType._(r'BOLD');
  static const ITALIC = V1NodeType._(r'ITALIC');
  static const BOLD_ITALIC = V1NodeType._(r'BOLD_ITALIC');
  static const CODE = V1NodeType._(r'CODE');
  static const IMAGE = V1NodeType._(r'IMAGE');
  static const LINK = V1NodeType._(r'LINK');
  static const AUTO_LINK = V1NodeType._(r'AUTO_LINK');
  static const TAG = V1NodeType._(r'TAG');
  static const STRIKETHROUGH = V1NodeType._(r'STRIKETHROUGH');
  static const ESCAPING_CHARACTER = V1NodeType._(r'ESCAPING_CHARACTER');
  static const MATH = V1NodeType._(r'MATH');
  static const HIGHLIGHT = V1NodeType._(r'HIGHLIGHT');
  static const SUBSCRIPT = V1NodeType._(r'SUBSCRIPT');
  static const SUPERSCRIPT = V1NodeType._(r'SUPERSCRIPT');
  static const REFERENCED_CONTENT = V1NodeType._(r'REFERENCED_CONTENT');
  static const SPOILER = V1NodeType._(r'SPOILER');
  static const HTML_ELEMENT = V1NodeType._(r'HTML_ELEMENT');

  /// List of all possible values in this [enum][V1NodeType].
  static const values = <V1NodeType>[
    NODE_UNSPECIFIED,
    LINE_BREAK,
    PARAGRAPH,
    CODE_BLOCK,
    HEADING,
    HORIZONTAL_RULE,
    BLOCKQUOTE,
    LIST,
    ORDERED_LIST_ITEM,
    UNORDERED_LIST_ITEM,
    TASK_LIST_ITEM,
    MATH_BLOCK,
    TABLE,
    EMBEDDED_CONTENT,
    TEXT,
    BOLD,
    ITALIC,
    BOLD_ITALIC,
    CODE,
    IMAGE,
    LINK,
    AUTO_LINK,
    TAG,
    STRIKETHROUGH,
    ESCAPING_CHARACTER,
    MATH,
    HIGHLIGHT,
    SUBSCRIPT,
    SUPERSCRIPT,
    REFERENCED_CONTENT,
    SPOILER,
    HTML_ELEMENT,
  ];

  static V1NodeType? fromJson(dynamic value) => V1NodeTypeTypeTransformer().decode(value);

  static List<V1NodeType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1NodeType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1NodeType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [V1NodeType] to String,
/// and [decode] dynamic data back to [V1NodeType].
class V1NodeTypeTypeTransformer {
  factory V1NodeTypeTypeTransformer() => _instance ??= const V1NodeTypeTypeTransformer._();

  const V1NodeTypeTypeTransformer._();

  String encode(V1NodeType data) => data.value;

  /// Decodes a [dynamic value][data] to a V1NodeType.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  V1NodeType? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'NODE_UNSPECIFIED': return V1NodeType.NODE_UNSPECIFIED;
        case r'LINE_BREAK': return V1NodeType.LINE_BREAK;
        case r'PARAGRAPH': return V1NodeType.PARAGRAPH;
        case r'CODE_BLOCK': return V1NodeType.CODE_BLOCK;
        case r'HEADING': return V1NodeType.HEADING;
        case r'HORIZONTAL_RULE': return V1NodeType.HORIZONTAL_RULE;
        case r'BLOCKQUOTE': return V1NodeType.BLOCKQUOTE;
        case r'LIST': return V1NodeType.LIST;
        case r'ORDERED_LIST_ITEM': return V1NodeType.ORDERED_LIST_ITEM;
        case r'UNORDERED_LIST_ITEM': return V1NodeType.UNORDERED_LIST_ITEM;
        case r'TASK_LIST_ITEM': return V1NodeType.TASK_LIST_ITEM;
        case r'MATH_BLOCK': return V1NodeType.MATH_BLOCK;
        case r'TABLE': return V1NodeType.TABLE;
        case r'EMBEDDED_CONTENT': return V1NodeType.EMBEDDED_CONTENT;
        case r'TEXT': return V1NodeType.TEXT;
        case r'BOLD': return V1NodeType.BOLD;
        case r'ITALIC': return V1NodeType.ITALIC;
        case r'BOLD_ITALIC': return V1NodeType.BOLD_ITALIC;
        case r'CODE': return V1NodeType.CODE;
        case r'IMAGE': return V1NodeType.IMAGE;
        case r'LINK': return V1NodeType.LINK;
        case r'AUTO_LINK': return V1NodeType.AUTO_LINK;
        case r'TAG': return V1NodeType.TAG;
        case r'STRIKETHROUGH': return V1NodeType.STRIKETHROUGH;
        case r'ESCAPING_CHARACTER': return V1NodeType.ESCAPING_CHARACTER;
        case r'MATH': return V1NodeType.MATH;
        case r'HIGHLIGHT': return V1NodeType.HIGHLIGHT;
        case r'SUBSCRIPT': return V1NodeType.SUBSCRIPT;
        case r'SUPERSCRIPT': return V1NodeType.SUPERSCRIPT;
        case r'REFERENCED_CONTENT': return V1NodeType.REFERENCED_CONTENT;
        case r'SPOILER': return V1NodeType.SPOILER;
        case r'HTML_ELEMENT': return V1NodeType.HTML_ELEMENT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [V1NodeTypeTypeTransformer] instance.
  static V1NodeTypeTypeTransformer? _instance;
}


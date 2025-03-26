import 'package:flutter_memos/api/lib/api.dart';

/// Model class for memo relations
class MemoRelation {
  final String relatedMemoId;
  final String type;
  
  MemoRelation({
    required this.relatedMemoId,
    this.type = 'LINKED',
  });
  
  /// Create from a map
  factory MemoRelation.fromJson(Map<String, dynamic> json) {
    return MemoRelation(
      relatedMemoId: json['relatedMemoId'] as String,
      type: json['type'] as String? ?? 'LINKED',
    );
  }
  
  /// Convert to a map
  Map<String, dynamic> toJson() {
    return {
      'relatedMemoId': relatedMemoId,
      'type': type,
    };
  }
  
  /// Create from API V1MemoRelation
  factory MemoRelation.fromApiRelation(V1MemoRelation relation) {
    String id = '';
    
    // Handle relatedMemo which is V1MemoRelationMemo type, not String
    if (relation.relatedMemo != null) {
      // Get the string representation and extract the ID part
      final relatedMemoStr = relation.relatedMemo.toString();
      if (relatedMemoStr.contains('/')) {
        final parts = relatedMemoStr.split('/');
        id = parts.length > 1 ? parts[1] : relatedMemoStr;
      } else {
        id = relatedMemoStr;
      }
    }
    
    // Convert the type to string
    String typeStr = 'LINKED';
    if (relation.type != null) {
      typeStr = relation.type.toString();
    }
    
    return MemoRelation(relatedMemoId: id, type: typeStr);
  }
  
  /// Convert to API V1MemoRelation
  V1MemoRelation toApiRelation() {
    // Format the memo ID correctly for the API
    final formattedId =
        relatedMemoId.contains('/') ? relatedMemoId : 'memos/$relatedMemoId';
    
    // Convert string type to V1MemoRelationType enum
    V1MemoRelationType? relationType;
    switch (type) {
      case typeLinked:
        relationType =
            V1MemoRelationType.COMMENT; // Changed from LINKED to COMMENT
        break;
      case typeReference:
        relationType = V1MemoRelationType.REFERENCE; // This one is correct
        break;
      case typeInspiredBy:
        relationType =
            V1MemoRelationType
                .TYPE_UNSPECIFIED; // Changed from INSPIRED_BY to TYPE_UNSPECIFIED
        break;
      default:
        relationType =
            V1MemoRelationType.COMMENT; // Changed from LINKED to COMMENT
    }
    
    return V1MemoRelation(
      // Create a V1MemoRelationMemo object
      relatedMemo: V1MemoRelationMemo(name: formattedId),
      type: relationType,
    );
  }
  
  /// Get relation type constants
  static const String typeLinked = 'LINKED';
  static const String typeReference = 'REFERENCE';
  static const String typeInspiredBy = 'INSPIRED_BY';
}

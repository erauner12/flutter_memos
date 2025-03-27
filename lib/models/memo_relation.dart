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
    switch (type.toUpperCase()) {
      case 'REFERENCE':
        relationType = V1MemoRelationType.REFERENCE;
        break;
      case 'INSPIRED_BY':
        relationType = V1MemoRelationType.TYPE_UNSPECIFIED;
        break;
      case 'LINKED':
      case 'COMMENT':
      default:
        relationType = V1MemoRelationType.COMMENT;
    }
    
    // Create memo references for both sides of the relation
    final memoRef = V1MemoRelationMemo(name: 'memos/placeholder');
    final relatedMemoRef = V1MemoRelationMemo(name: formattedId);
    
    return V1MemoRelation(
      memo: memoRef,
      relatedMemo: relatedMemoRef,
      type: relationType,
    );
  }
  /// Get relation type constants
  static const String typeLinked = 'LINKED';
  static const String typeReference = 'REFERENCE';
  static const String typeInspiredBy = 'INSPIRED_BY';
}

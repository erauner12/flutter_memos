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
    if (relation.relatedMemo != null) {
      final parts = relation.relatedMemo!.split('/');
      id = parts.length > 1 ? parts[1] : relation.relatedMemo!;
    }
    
    return MemoRelation(relatedMemoId: id, type: relation.type ?? 'LINKED');
  }
  
  /// Convert to API V1MemoRelation
  V1MemoRelation toApiRelation() {
    return V1MemoRelation(
      relatedMemo:
          relatedMemoId.contains('/') ? relatedMemoId : 'memos/$relatedMemoId',
      type: type,
    );
  }
  
  /// Get relation type constants
  static const String typeLinked = 'LINKED';
  static const String typeReference = 'REFERENCE';
  static const String typeInspiredBy = 'INSPIRED_BY';
}

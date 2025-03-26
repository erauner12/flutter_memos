/// Enum for relation types
enum RelationType { linked, reference, inspiredBy }

/// Model class for memo relations
class MemoRelation {
  final String relatedMemoId;
  final RelationType type;
  
  MemoRelation({
    required this.relatedMemoId,
    this.type = RelationType.linked,
  });
  
  /// Create from a map
  factory MemoRelation.fromJson(Map<String, dynamic> json) {
    return MemoRelation(
      relatedMemoId: json['relatedMemoId'] as String,
      type: _parseTypeString(json['type'] as String?),
    );
  }
  
  /// Convert to a map
  Map<String, dynamic> toJson() {
    return {
      'relatedMemoId': relatedMemoId,
      'type': type.toString().split('.').last.toUpperCase(),
    };
  }
  
  /// Helper to parse type string
  static RelationType _parseTypeString(String? typeStr) {
    if (typeStr == null) return RelationType.linked;
    
    switch (typeStr.toUpperCase()) {
      case 'REFERENCE':
        return RelationType.reference;
      case 'INSPIRED_BY':
        return RelationType.inspiredBy;
      case 'LINKED':
      default:
        return RelationType.linked;
    }
  }
}

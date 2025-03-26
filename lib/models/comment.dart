/// Enum for comment states
enum CommentState { normal, archived, deleted }

/// Model class for memo comments
class Comment {
  final String id;
  final String content;
  final String? creatorId;
  final int createTime;
  final int? updateTime;
  final CommentState state;
  final bool pinned;
  
  Comment({
    required this.id,
    required this.content,
    this.creatorId,
    required this.createTime,
    this.updateTime,
    this.state = CommentState.normal,
    this.pinned = false,
  });
  
  /// Create a copy of this comment with some fields replaced
  Comment copyWith({
    String? content,
    int? updateTime, 
    CommentState? state,
    bool? pinned,
  }) {
    return Comment(
      id: id,
      content: content ?? this.content,
      creatorId: creatorId,
      createTime: createTime,
      updateTime: updateTime ?? this.updateTime,
      state: state ?? this.state,
      pinned: pinned ?? this.pinned,
    );
  }
  
  /// Convert from JSON representation
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      content: json['content'] as String,
      creatorId: json['creatorId'] as String?,
      createTime: json['createTime'] as int,
      updateTime: json['updateTime'] as int?,
      state: _parseState(json['state']),
      pinned: json['pinned'] as bool? ?? false,
    );
  }
  
  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      if (creatorId != null) 'creatorId': creatorId,
      'createTime': createTime,
      if (updateTime != null) 'updateTime': updateTime,
      'state': state.toString().split('.').last.toUpperCase(),
      'pinned': pinned,
    };
  }
  
  /// Helper method to parse state from JSON
  static CommentState _parseState(dynamic stateValue) {
    if (stateValue == null) return CommentState.normal;
    
    if (stateValue is String) {
      switch (stateValue.toUpperCase()) {
        case 'ARCHIVED':
          return CommentState.archived;
        case 'DELETED':
          return CommentState.deleted;
        case 'NORMAL':
        default:
          return CommentState.normal;
      }
    }
    
    return CommentState.normal;
  }
  
  @override
  String toString() {
    return 'Comment(id: $id, content: ${content.substring(0, content.length > 20 ? 20 : content.length)}...)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Comment &&
        other.id == id &&
        other.content == content &&
        other.creatorId == creatorId &&
        other.createTime == createTime &&
        other.updateTime == updateTime &&
        other.state == state &&
        other.pinned == pinned;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      content,
      creatorId,
      createTime,
      updateTime,
      state,
      pinned,
    );
  }
}

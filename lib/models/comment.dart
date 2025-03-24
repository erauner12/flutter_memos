/// Model class for memo comments
class Comment {
  final String id;
  final String content;
  final String? creatorId;
  final int createTime;
  final int? updateTime;
  
  Comment({
    required this.id,
    required this.content,
    this.creatorId,
    required this.createTime,
    this.updateTime,
  });
  
  /// Create a copy of this comment with some fields replaced
  Comment copyWith({String? content, int? updateTime}) {
    return Comment(
      id: id,
      content: content ?? this.content,
      creatorId: creatorId,
      createTime: createTime,
      updateTime: updateTime ?? this.updateTime,
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
    };
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
        other.updateTime == updateTime;
  }

  @override
  int get hashCode {
    return Object.hash(id, content, creatorId, createTime, updateTime);
  }
}

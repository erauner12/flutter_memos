class Comment {
  final String id;
  final String content;
  final int? createTime;
  final String? creatorId;

  Comment({
    required this.id,
    required this.content,
    this.createTime,
    this.creatorId,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    String id = '';
    if (json['id'] != null) {
      id = json['id'];
    } else if (json['name'] != null) {
      final idMatch = RegExp(r'comments\/(\d+)$').firstMatch(json['name']);
      id = idMatch != null ? idMatch.group(1)! : json['name'];
    }

    int? timestamp;
    if (json['createTime'] != null) {
      if (json['createTime'] is int) {
        timestamp = json['createTime'];
      } else if (json['createTime'] is String) {
        timestamp = DateTime.parse(json['createTime']).millisecondsSinceEpoch;
      }
    }

    String? creator;
    if (json['creatorId'] != null) {
      creator = json['creatorId'].toString();
    } else if (json['creator'] != null) {
      final creatorMatch = RegExp(r'users\/(\d+)').firstMatch(json['creator']);
      creator = creatorMatch != null ? creatorMatch.group(1) : json['creator'];
    }

    return Comment(
      id: id,
      content: json['content'] ?? '',
      createTime: timestamp,
      creatorId: creator,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'creator': creatorId != null ? 'users/$creatorId' : 'users/1',
    };
  }
}
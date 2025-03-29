class Memo {
  final String id;
  final String content;
  final bool pinned;
  final MemoState state;
  final String visibility;
  final List<String>? resourceNames;
  final List<dynamic>? relationList;
  final String? parent;
  final String? creator;
  final String? createTime;
  final String? updateTime;
  final String? displayTime;

  Memo({
    required this.id,
    required this.content,
    this.pinned = false,
    this.state = MemoState.normal,
    this.visibility = 'PUBLIC',
    this.resourceNames,
    this.relationList,
    this.parent,
    this.creator,
    this.createTime,
    this.updateTime,
    this.displayTime,
  });

  factory Memo.fromJson(Map<String, dynamic> json) {
    String id = '';
    if (json['name'] != null) {
      final parts = json['name'].toString().split('/');
      id = parts.length > 1 ? parts[1] : json['name'];
    } else if (json['id'] != null) {
      id = json['id'];
    }

    return Memo(
      id: id,
      content: json['content'] ?? '',
      pinned: json['pinned'] ?? false,
      state: _parseState(json['state']),
      visibility: json['visibility'] ?? 'PUBLIC',
      resourceNames: json['resourceName'] != null
          ? List<String>.from(json['resourceName'])
          : null,
      relationList: json['relationList'],
      parent: json['parent'],
      creator: json['creator'],
      createTime: json['createTime'],
      updateTime: json['updateTime'],
      displayTime: json['displayTime'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'content': content,
      'pinned': pinned,
      'state': state.toString().split('.').last.toUpperCase(),
      'visibility': visibility,
    };
    
    // Preserve timestamp fields when they exist
    // This prevents timestamps from being reset when updating a memo
    if (createTime != null) {
      json['createTime'] = createTime;
    }

    if (updateTime != null) {
      json['updateTime'] = updateTime;
    }

    if (displayTime != null) {
      json['displayTime'] = displayTime;
    }

    return json;
  }

  static MemoState _parseState(dynamic stateValue) {
    if (stateValue == null) return MemoState.normal;
    
    if (stateValue is String) {
      switch (stateValue.toUpperCase()) {
        case 'ARCHIVED':
          return MemoState.archived;
        case 'NORMAL':
        default:
          return MemoState.normal;
      }
    }
    
    return MemoState.normal;
  }

  Memo copyWith({
    String? id,
    String? content,
    bool? pinned,
    MemoState? state,
    String? visibility,
    List<String>? resourceNames,
    List<dynamic>? relationList,
    String? parent,
    String? creator,
    String? createTime,
    String? updateTime,
    String? displayTime,
  }) {
    return Memo(
      id: id ?? this.id,
      content: content ?? this.content,
      pinned: pinned ?? this.pinned,
      state: state ?? this.state,
      visibility: visibility ?? this.visibility,
      resourceNames: resourceNames ?? this.resourceNames,
      relationList: relationList ?? this.relationList,
      parent: parent ?? this.parent,
      creator: creator ?? this.creator,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      displayTime: displayTime ?? this.displayTime,
    );
  }
}

/// Enum for memo states
enum MemoState { normal, archived, deleted }

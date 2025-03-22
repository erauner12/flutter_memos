import 'message.dart';

class Conversation {
  final String id;
  final String userId;
  final int createdAt;
  final int updatedAt;
  final List<Message> messages;

  Conversation({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    List<Message> messagesList = [];
    if (json['messages'] != null) {
      messagesList = List<Message>.from(
        json['messages'].map((x) => Message.fromJson(x)),
      );
    }

    return Conversation(
      id: json['id'],
      userId: json['userId'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      messages: messagesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'messages': messages.map((message) => message.toJson()).toList(),
    };
  }
}
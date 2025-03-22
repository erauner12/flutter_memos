import 'dart:convert';
import 'package:flutter/material.dart';

/// Example chat message model
class ChatMessage {
  final String id;
  final String role; // "user" or "assistant"
  final String content;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool loading = false;
  bool sending = false;
  String? error;
  String? conversationId;
  final List<ChatMessage> messages = [];

  final _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  Future<void> _initializeConversation() async {
    setState(() {
      loading = true;
      error = null;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    // Here, you'd call your assistant creation endpoint
    // For now, let's mock:
    setState(() {
      conversationId = "fake_conversation_id";
      messages.clear();
      messages.add(ChatMessage(id: "1", role: "assistant", content: "Hello! I'm your memo assistant."));
      loading = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || sending) return;

    setState(() {
      sending = true;
      error = null;
    });
    // Add user message
    messages.add(ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: "user",
      content: text,
    ));
    _inputController.clear();

    // Mock sending to server
    await Future.delayed(const Duration(seconds: 1));
    // Mock assistant response
    messages.add(ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: "assistant",
      content: "I have received your message: \"$text\". Let me process that...",
    ));

    setState(() {
      sending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assistant Chat"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (error != null)
                  Container(
                    color: Colors.red.shade100,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: Text("Error: $error"),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isUser = msg.role == "user";
                      return Align(
                        alignment:
                            isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isUser
                                ? theme.colorScheme.primary.withOpacity(0.2)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(msg.content),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: sending
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.send),
                      onPressed: sending ? null : _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_memos/models/conversation.dart';
import 'package:flutter_memos/models/message.dart';
import 'package:flutter_memos/services/assistant_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AssistantService _assistantService = AssistantService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  String? _conversationId;
  List<Message> _messages = [];
  bool _loading = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeConversation() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final result = await _assistantService.createConversation();
      
      setState(() {
        _conversationId = result['conversationId'];
        _messages = (result['conversation'] as Conversation).messages;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to start conversation: ${e.toString()}';
        _loading = false;
      });
    }
  }

  Future<void> _handleSend() async {
    if (_conversationId == null || _inputController.text.trim().isEmpty || _sending) {
      return;
    }

    final userMessage = _inputController.text.trim();
    _inputController.clear();

    setState(() {
      _sending = true;
      
      // Add temporary user message immediately
      _messages.add(Message(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _conversationId!,
        role: 'user',
        content: userMessage,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    });

    // Scroll to the bottom after adding the message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      final result = await _assistantService.sendMessage(_conversationId!, userMessage);
      
      setState(() {
        _messages = (result['conversation'] as Conversation).messages;
        _sending = false;
      });
      
      // Scroll to the bottom after receiving the response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to send message: ${e.toString()}';
        _sending = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Chat'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _conversationId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing assistant...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_error != null)
          Container(
            color: Colors.red.shade100,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
                TextButton(
                  onPressed: _initializeConversation,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(10),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isUser = message.role == 'user';
              
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFFDC4C3E) : const Color(0xFFE9E9EB),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          fontSize: 16,
                          color: isUser ? Colors.white : Colors.black,
                        ),
                      ),
                      if (message.memoReference != null)
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'Memo ID: ${message.memoReference}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Ask the assistant...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  onSubmitted: (_) {
                    if (!_sending && _inputController.text.trim().isNotEmpty) {
                      _handleSend();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _sending || _inputController.text.trim().isEmpty
                        ? Colors.grey
                        : const Color(0xFFDC4C3E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: _sending || _inputController.text.trim().isEmpty
                      ? null
                      : _handleSend,
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

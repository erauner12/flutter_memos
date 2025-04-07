import 'package:flutter/cupertino.dart'; // Import Cupertino
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
    if (_conversationId == null ||
        _inputController.text.trim().isEmpty ||
        _sending) {
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
      final result = await _assistantService.sendMessage(
        _conversationId!,
        userMessage,
      );

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
    // Use CupertinoPageScaffold and CupertinoNavigationBar
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Assistant Chat'),
        transitionBetweenRoutes: false, // Disable default hero animation
      ),
      child: SafeArea(
        // Add SafeArea
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final theme = CupertinoTheme.of(context); // Get theme for colors

    if (_loading && _conversationId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(), // Use CupertinoActivityIndicator
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
            // Use Cupertino dynamic colors
            color: CupertinoColors.systemRed.resolveFrom(context).withAlpha(50),
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: CupertinoColors.systemRed.resolveFrom(context),
                    ),
                  ),
                ),
                // Use CupertinoButton
                CupertinoButton(
                  onPressed: _initializeConversation,
                  color: CupertinoColors.systemRed.resolveFrom(context),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: CupertinoColors.white),
                  ),
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

              // Define colors based on theme and user/assistant
              final userBubbleColor = theme.primaryColor;
              final assistantBubbleColor = CupertinoColors.secondarySystemFill
                  .resolveFrom(context);
              final userTextColor = CupertinoColors.white;
              final assistantTextColor = CupertinoColors.label.resolveFrom(
                context,
              );

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
                    color: isUser ? userBubbleColor : assistantBubbleColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          fontSize: 16,
                          color: isUser ? userTextColor : assistantTextColor,
                        ),
                      ),
                      if (message.memoReference != null)
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: CupertinoColors.black.withAlpha(
                              25,
                            ), // Subtle background
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'Memo ID: ${message.memoReference}',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color:
                                  isUser
                                      ? userTextColor.withAlpha(200)
                                      : assistantTextColor.withAlpha(200),
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

        // Input area
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.barBackgroundColor, // Use theme background color
            border: Border(
              top: BorderSide(
                color: CupertinoColors.separator.resolveFrom(context),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                // Use CupertinoTextField
                child: CupertinoTextField(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  placeholder: 'Ask the assistant...',
                  placeholderStyle: TextStyle(
                    color: CupertinoColors.placeholderText.resolveFrom(context),
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemFill.resolveFrom(context),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    border: Border.all(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send, // Suggest send action
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
                // Use CupertinoButton.filled
                child: CupertinoButton.filled(
                  padding: EdgeInsets.zero,
                  disabledColor: CupertinoColors.inactiveGray,
                  onPressed: _sending || _inputController.text.trim().isEmpty
                      ? null
                      : _handleSend,
                  child: _sending
                          ? const CupertinoActivityIndicator(
                            // Use CupertinoActivityIndicator
                            radius: 10,
                            color: CupertinoColors.white,
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator; // For loading bar
import 'package:flutter_markdown/flutter_markdown.dart'; // For rendering markdown
import 'package:flutter_memos/models/chat_message.dart'; // Import ChatMessage which now defines Role
import 'package:flutter_memos/providers/chat_providers.dart';
import 'package:flutter_memos/providers/settings_provider.dart'; // To check API key
import 'package:flutter_memos/services/mcp_client_service.dart'; // To show MCP status
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Remove google_generative_ai import if only used for Role
// import 'package:google_generative_ai/google_generative_ai.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // didChangeDependencies override is removed

  void _scrollToBottom() {
    // Use WidgetsBinding to schedule scroll after the frame build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      ref.read(chatProvider.notifier).sendMessage(text);
      _textController.clear();
      _focusNode.requestFocus(); // Keep focus after sending
       _scrollToBottom(); // Ensure scroll after sending
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final mcpState = ref.watch(mcpClientProvider);
    final isApiKeySet = ref.watch(geminiApiKeyProvider).isNotEmpty;

    // --- Move Listeners Here ---
    // Listen for changes and trigger scroll *after* the build phase
    ref.listen(chatProvider.select((state) => state.displayMessages.length), (
      _,
      __,
    ) {
      _scrollToBottom();
    });
    ref.listen(chatProvider.select((state) => state.isLoading), (_, isLoading) {
      // Scroll when loading starts or stops
      _scrollToBottom();
      // Optionally refocus after loading completes
      // if (!isLoading) {
      //   Future.microtask(() => _focusNode.requestFocus());
      // }
    });
    // --- End Listeners ---


    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Chat (${mcpState.connectedServerCount} MCP)'),
        // Example: Add a clear button
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.trash, size: 22),
          onPressed: () {
             // Add confirmation dialog if desired
             ref.read(chatProvider.notifier).clearChat();
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (chatState.isLoading)
              const LinearProgressIndicator(minHeight: 2), // Simple loading bar
            // Display general error message if any
            if (chatState.errorMessage != null)
              Container(
                // Use resolveFrom(context).withAlpha() for opacity
                color: CupertinoColors.systemRed
                    .withAlpha(25), // ~10% opacity
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle, color: CupertinoColors.systemRed, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(chatState.errorMessage!, style: const TextStyle(color: CupertinoColors.systemRed))),
                     CupertinoButton(
                       padding: EdgeInsets.zero,
                       minSize: 0,
                       child: const Icon(CupertinoIcons.xmark, size: 16, color: CupertinoColors.systemRed),
                       // Call the dedicated method in the notifier
                       onPressed: () => ref.read(chatProvider.notifier).clearErrorMessage(),
                     )
                  ],
                ),
              ),
            // Display API key warning if not set
            if (!isApiKeySet)
              Container(
                // Use resolveFrom(context).withAlpha() for opacity
                color: CupertinoColors.systemYellow
                    .withAlpha(38), // ~15% opacity
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.exclamationmark_shield, color: CupertinoColors.systemYellow, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text("Gemini API Key not set. Please configure it in Settings.", style: TextStyle(color: CupertinoColors.systemYellow))),
                  ],
                ),
              ),
            // Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: chatState.displayMessages.length,
                itemBuilder: (context, index) {
                  final message = chatState.displayMessages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
            // Input Area
            _buildInputArea(context, chatState.isLoading || !isApiKeySet),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == Role.user; // Use local Role enum
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isUser
        ? CupertinoColors.activeBlue
        : CupertinoColors.systemGrey5.resolveFrom(context);
    final textColor = isUser
        ? CupertinoColors.white
        : CupertinoColors.label.resolveFrom(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              // Use resolveFrom(context).withAlpha() for opacity
              color:
                  message.isError
                      ? CupertinoColors.systemRed
                          .withAlpha(204) // ~80% opacity for error
                      : color,
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: message.isLoading && message.text.isEmpty
                ? const CupertinoActivityIndicator(radius: 10)
                : MarkdownBody(
                    data: message.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(color: message.isError ? CupertinoColors.white : textColor, fontSize: 16),
                      // Add other styles as needed (code blocks, lists, etc.)
                       code: TextStyle(
                          // Use resolveFrom(context).withAlpha() for opacity
                          backgroundColor: CupertinoColors.black
                              .withAlpha(25), // ~10% opacity
                         fontFamily: 'monospace',
                         color: message.isError ? CupertinoColors.white : textColor,
                       ),
                       codeblockDecoration: BoxDecoration(
                          // Use withAlpha() for opacity
                          color: CupertinoColors.black
                              .withAlpha(25), // ~10% opacity
                         borderRadius: BorderRadius.circular(4),
                       ),
                    ),
                  ),
          ),
           // Optional: Display timestamp or tool info
           // Padding(
           //   padding: const EdgeInsets.only(top: 2.0, left: 5.0, right: 5.0),
           //   child: Text(
           //     intl.DateFormat.Hm().format(message.timestamp), // Example timestamp
           //     style: TextStyle(fontSize: 10, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
           //   ),
           // )
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, bool disabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
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
            child: CupertinoTextField(
              controller: _textController,
              focusNode: _focusNode,
              placeholder: 'Enter message...',
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.send, // Or newline depending on preference
              onSubmitted: disabled ? null : (_) => _sendMessage(),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
               decoration: BoxDecoration(
                 color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                 borderRadius: BorderRadius.circular(18.0),
               ),
               enabled: !disabled,
            ),
          ),
          const SizedBox(width: 8.0),
          CupertinoButton(
            padding: const EdgeInsets.all(8.0),
            onPressed: disabled ? null : _sendMessage,
            child: const Icon(CupertinoIcons.arrow_up_circle_fill, size: 30),
          ),
        ],
      ),
    );
  }
}

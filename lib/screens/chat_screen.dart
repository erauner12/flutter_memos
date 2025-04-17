import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator; // For loading bar
import 'package:flutter_markdown/flutter_markdown.dart'; // For rendering markdown
import 'package:flutter_memos/main.dart'; // Import for rootNavigatorKeyProvider
import 'package:flutter_memos/models/chat_message.dart'; // Import ChatMessage which now defines Role
import 'package:flutter_memos/models/workbench_item_reference.dart'; // For WorkbenchItemType enum
import 'package:flutter_memos/providers/chat_providers.dart';
import 'package:flutter_memos/providers/settings_provider.dart'; // To check API key
import 'package:flutter_memos/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:flutter_memos/services/mcp_client_service.dart'; // For mcpClientProvider
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _contextProcessed =
      false; // Flag to ensure context is processed only once

  @override
  void initState() {
    super.initState();
    // Don't process context here, wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Process context arguments only once when the screen is loaded with them
    if (!_contextProcessed) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final contextString = args['contextString'] as String?;
        final parentItemId = args['parentItemId'] as String?;
        final parentItemType = args['parentItemType'] as WorkbenchItemType?;
        final parentServerId = args['parentServerId'] as String?;

        if (contextString != null &&
            parentItemId != null &&
            parentItemType != null &&
            parentServerId != null) {
          // Use addPostFrameCallback to ensure notifier call happens after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref
                  .read(chatProvider.notifier)
                  .startChatWithContext(
                    contextString: contextString,
                    parentItemId: parentItemId,
                    parentItemType: parentItemType,
                    parentServerId: parentServerId,
                  );
              // Set flag after processing
              // No need for setState here as it's called from postFrameCallback
              // and the provider update will trigger a rebuild anyway.
              _contextProcessed = true;
              debugPrint("ChatScreen: Context processed from arguments.");
            }
          });
        } else {
          // If args exist but are invalid, mark as processed to avoid retrying
          _contextProcessed = true;
          debugPrint(
            "ChatScreen: Received arguments but context data was incomplete.",
          );
        }
      } else {
        // No arguments received, normal chat session
        _contextProcessed = true; // Mark as processed so we don't check again
        debugPrint("ChatScreen: No context arguments received.");
      }
    }
  }


  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
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
      _focusNode.requestFocus();
      _scrollToBottom();
    }
  }

  // Helper to get a display name for WorkbenchItemType
  String _getItemTypeName(WorkbenchItemType? type) {
    switch (type) {
      case WorkbenchItemType.note:
        return 'Note';
      case WorkbenchItemType.task:
        return 'Task';
      case WorkbenchItemType.comment:
        return 'Comment'; // Should ideally show parent type
      case null:
        return 'Item';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final mcpState = ref.watch(mcpClientProvider);
    final isApiKeySet = ref.watch(geminiApiKeyProvider).isNotEmpty;

    // Listeners for scrolling
    ref.listen(chatProvider.select((state) => state.displayMessages.length), (
      _,
      __,
    ) {
      _scrollToBottom();
    });
    ref.listen(chatProvider.select((state) => state.isLoading), (_, isLoading) {
      _scrollToBottom();
    });

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Chat (${mcpState.connectedServerCount} MCP)'),
        trailing: Row(
          // Wrap existing and new button in a Row
          mainAxisSize: MainAxisSize.min,
          children: [
            // Existing Trash Button
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.trash, size: 22),
              onPressed: () {
                // Confirmation could be added here
                ref.read(chatProvider.notifier).clearChat();
                // Reset context processed flag if chat is cleared manually
                setState(() {
                  _contextProcessed = false;
                });
              },
            ),
            const SizedBox(width: 8), // Add spacing
            // New Settings Button
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.settings, size: 22), // Gear icon
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder:
                        (context) =>
                            const SettingsScreen(isInitialSetup: false),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (chatState.isLoading)
              const LinearProgressIndicator(minHeight: 2),
            // Display general error message
            if (chatState.errorMessage != null)
              Container(
                color: CupertinoColors.systemRed.withAlpha(25),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle, color: CupertinoColors.systemRed, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(chatState.errorMessage!, style: const TextStyle(color: CupertinoColors.systemRed))),
                     CupertinoButton(
                       padding: EdgeInsets.zero,
                       minSize: 0,
                      child: const Icon(
                        CupertinoIcons.xmark,
                        size: 16,
                        color: CupertinoColors.systemRed,
                      ),
                       onPressed: () => ref.read(chatProvider.notifier).clearErrorMessage(),
                     )
                  ],
                ),
              ),
            // Display API key warning
            if (!isApiKeySet)
              Container(
                color: CupertinoColors.systemYellow.withAlpha(38),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.exclamationmark_shield, color: CupertinoColors.systemYellow, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text("Gemini API Key not set. Please configure it in Settings.", style: TextStyle(color: CupertinoColors.systemYellow))),
                  ],
                ),
              ),
            // Display Context Indicator
            if (chatState.currentContextItemId != null)
              GestureDetector(
                // Wrap with GestureDetector
                onTap: () {
                  // Navigate back to the source item if it's a note
                  if (chatState.currentContextItemType ==
                          WorkbenchItemType.note &&
                      chatState.currentContextItemId != null) {
                    final rootNavigator = ref.read(rootNavigatorKeyProvider);
                    rootNavigator.currentState?.pushNamed(
                      '/item-detail',
                      arguments: {'itemId': chatState.currentContextItemId},
                    );
                  }
                  // Add handling for other types if needed later
                },
                child: Container(
                  color: CupertinoColors.systemBlue.withAlpha(20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle,
                        color:
                            chatState.currentContextItemType ==
                                    WorkbenchItemType.note
                                ? CupertinoColors
                                    .systemBlue // Keep blue for tappable notes
                                : CupertinoColors.secondaryLabel.resolveFrom(
                                  context,
                                ), // Dim if not tappable
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Context: ${_getItemTypeName(chatState.currentContextItemType)} ${chatState.currentContextItemId}",
                          style: TextStyle(
                            color:
                                chatState.currentContextItemType ==
                                        WorkbenchItemType.note
                                    ? CupertinoColors
                                        .systemBlue // Keep blue for tappable notes
                                    : CupertinoColors.secondaryLabel
                                        .resolveFrom(
                                          context,
                                        ), // Dim if not tappable
                            fontSize: 13,
                            // Add underline if it's a tappable note
                            decoration:
                                chatState.currentContextItemType ==
                                        WorkbenchItemType.note
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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
                  // Don't display system messages if we add them later
                  // if (message.role == Role.system) return const SizedBox.shrink();
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
    final isUser = message.role == Role.user;
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
              color:
                  message.isError
                      ? CupertinoColors.systemRed.withAlpha(204)
                      : color,
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: message.isLoading && message.text.isEmpty
                ? const CupertinoActivityIndicator(radius: 10)
                : MarkdownBody(
                    data: message.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color:
                              message.isError
                                  ? CupertinoColors.white
                                  : textColor,
                          fontSize: 16,
                        ),
                       code: TextStyle(
                          backgroundColor: CupertinoColors.black.withAlpha(25),
                         fontFamily: 'monospace',
                         color: message.isError ? CupertinoColors.white : textColor,
                       ),
                       codeblockDecoration: BoxDecoration(
                          color: CupertinoColors.black.withAlpha(25),
                         borderRadius: BorderRadius.circular(4),
                       ),
                    ),
                  ),
          ),
          // Optional: Timestamp
           // Padding(
           //   padding: const EdgeInsets.only(top: 2.0, left: 5.0, right: 5.0),
           //   child: Text(
          //     DateFormat.Hm().format(message.timestamp.toLocal()),
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
              textInputAction: TextInputAction.send,
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart' show LinearProgressIndicator; // For loading bar
import 'package:flutter_markdown/flutter_markdown.dart'; // For rendering markdown
import 'package:flutter_memos/main.dart'; // Import for rootNavigatorKeyProvider
import 'package:flutter_memos/models/chat_message.dart'; // Import ChatMessage which now defines Role
import 'package:flutter_memos/models/workbench_item_type.dart';
// Removed chat overlay provider import
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check context from ModalRoute first if available upon build
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _processContextArguments(args);
      } else {
        _checkInitialContext(); // Check provider state if no route args
      }
    });
  }

  // Check context when dependencies change (e.g., ModalRoute available)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Process context arguments only once when the screen is loaded with them
    if (!_contextProcessed) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _processContextArguments(args);
      } else {
        // If no ModalRoute args, still check provider state in case context was set externally
        _checkInitialContext();
        // Mark as processed even if no context found initially, provider listener will handle future changes
        _contextProcessed = true;
        if (kDebugMode) {
          print("ChatScreen: No context arguments found via ModalRoute.");
        }
      }
    }
  }

  // Helper to check context from the provider state
  void _checkInitialContext() {
    if (!_contextProcessed && mounted) {
      final chatState = ref.read(chatProvider);
      if (chatState.currentContextItemId != null &&
          chatState.currentContextItemType != null) {
        // Context already exists in the provider, likely set externally (e.g., deep link)
        _contextProcessed = true; // Mark as processed
        if (kDebugMode) {
          print("ChatScreen: Initial context found in provider state.");
        }
        // UI will update automatically via watch
      }
    }
  }

  // Helper to process context arguments (from ModalRoute or potentially other sources)
  void _processContextArguments(Map<String, dynamic> args) {
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
          _contextProcessed = true; // Set flag after processing
          if (kDebugMode) {
            print(
              "ChatScreen: Context processed from arguments for type $parentItemType.",
            );
          }
        }
      });
    } else {
      // If args exist but are invalid, mark as processed to avoid retrying
      _contextProcessed = true;
      if (kDebugMode) {
        print(
          "ChatScreen: Received arguments but context data was incomplete.",
        );
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
      _focusNode.requestFocus(); // Keep focus after sending
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
        return 'Comment';
      case WorkbenchItemType.project: // Added case for project
        return 'Project';
      case WorkbenchItemType.unknown: // Added case for unknown
      case null: // Default case for exhaustiveness
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
      if (isLoading) {
        _scrollToBottom();
      }
    });

    // Listen for context changes from the provider (e.g., set by deep link handler)
    ref.listen(chatProvider.select((state) => state.currentContextItemId), (
      _,
      nextContextId,
    ) {
      if (nextContextId != null && !_contextProcessed && mounted) {
        _contextProcessed = true;
        if (kDebugMode) {
          print("ChatScreen: Context updated via provider listener.");
        }
      } else if (nextContextId == null && _contextProcessed) {
        _contextProcessed = false;
        if (kDebugMode) {
          print("ChatScreen: Context cleared, resetting processed flag.");
        }
      }
    });


    // Show loading indicator during initial session load
    if (chatState.isInitializing) {
      // Return scaffold with loading indicator in body
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Chat')),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    // Main screen content wrapped in CupertinoPageScaffold
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Chat (${mcpState.connectedServerCount} MCP)'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sync Button
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minSize: 0,
              onPressed:
                  chatState.isSyncing || chatState.isInitializing
                      ? null
                      : () =>
                          ref.read(chatProvider.notifier).forceFetchFromCloud(),
              child:
                  chatState.isSyncing
                      ? const CupertinoActivityIndicator(radius: 10)
                      : const Icon(CupertinoIcons.cloud_download, size: 22),
            ),
            // Trash Button
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minSize: 0,
              onPressed:
                  chatState.isSyncing || chatState.isInitializing
                      ? null
                      : () {
                        ref.read(chatProvider.notifier).clearChat();
                        setState(() {
                          _contextProcessed = false;
                        });
                      },
              child: const Icon(CupertinoIcons.trash, size: 20),
            ),
            // Settings Button
            CupertinoButton(
              padding: const EdgeInsets.only(left: 8, right: 0),
              minSize: 0,
              onPressed:
                  chatState.isSyncing || chatState.isInitializing
                      ? null
                      : () {
                        // Use root navigator to push settings screen
                        final rootNavigator = ref.read(
                          rootNavigatorKeyProvider,
                        );
                        rootNavigator.currentState?.push(
                          CupertinoPageRoute(
                            builder:
                                (context) =>
                                    const SettingsScreen(isInitialSetup: false),
                          ),
                        );
                      },
              child: const Icon(CupertinoIcons.settings, size: 20),
            ),
          ],
        ),
      ),
      child: SafeArea(
        // SafeArea for the body content below the nav bar
        top: false, // Nav bar handles top safe area
        bottom: false, // Input area will handle bottom safe area
        child: Column(
          children: [
            // Display AI loading indicator
            if (chatState.isLoading)
              const LinearProgressIndicator(minHeight: 2),
            // Display general error message
            if (chatState.errorMessage != null)
              Container(
                color: CupertinoColors.systemRed.withAlpha(25),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: CupertinoColors.systemRed,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatState.errorMessage!,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                          inherit: false,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 0,
                      child: const Icon(
                        CupertinoIcons.xmark,
                        size: 16,
                        color: CupertinoColors.systemRed,
                      ),
                      onPressed:
                          () =>
                              ref
                                  .read(chatProvider.notifier)
                                  .clearErrorMessage(),
                    ),
                  ],
                ),
              ),
            // Display API key warning
            if (!isApiKeySet)
              Container(
                color: CupertinoColors.systemYellow.withAlpha(38),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_shield,
                      color: CupertinoColors.systemYellow,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Gemini API Key not set. Please configure it in Settings.",
                        style: TextStyle(
                          color: CupertinoColors.systemYellow.resolveFrom(
                            context,
                          ),
                          inherit: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Display Context Indicator
            if (chatState.currentContextItemId != null)
              GestureDetector(
                onTap: () {
                  if (chatState.currentContextItemType ==
                          WorkbenchItemType.note &&
                      chatState.currentContextItemId != null) {
                    final rootNavigator = ref.read(rootNavigatorKeyProvider);
                    rootNavigator.currentState?.pushNamed(
                      '/item-detail',
                      arguments: {'itemId': chatState.currentContextItemId},
                    );
                    // Removed closing overlay logic
                  }
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
                                ? CupertinoColors.systemBlue
                                : CupertinoColors.secondaryLabel.resolveFrom(
                                  context,
                                ),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Context: ${_getItemTypeName(chatState.currentContextItemType)} ${chatState.currentContextItemId?.substring(0, 8)}...",
                          style: TextStyle(
                            inherit: false,
                            color:
                                chatState.currentContextItemType ==
                                        WorkbenchItemType.note
                                    ? CupertinoColors.systemBlue
                                    : CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                            fontSize: 13,
                            decoration:
                                chatState.currentContextItemType ==
                                        WorkbenchItemType.note
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                            decorationColor: CupertinoColors.systemBlue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.only(left: 8),
                        minSize: 0,
                        child: const Icon(
                          CupertinoIcons.xmark_circle,
                          size: 16,
                          color: CupertinoColors.secondaryLabel,
                        ),
                        onPressed: () {
                          ref.read(chatProvider.notifier).clearChatContext();
                          setState(() {
                            _contextProcessed = false;
                          });
                        },
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
                  if (message.role == Role.system) {
                    return const SizedBox.shrink();
                  }
                  return _buildMessageBubble(message);
                },
              ),
            ),
            // Input Area - Needs its own SafeArea handling
            _buildInputArea(
              context,
              chatState.isLoading || chatState.isSyncing || !isApiKeySet,
            ),
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
              // Constrain width relative to screen width (adjust as needed)
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
                      styleSheet: MarkdownStyleSheet.fromCupertinoTheme(
                        CupertinoTheme.of(context),
                      ).copyWith(
                        p: TextStyle(
                          inherit: false,
                          color:
                              message.isError
                                  ? CupertinoColors.white
                                  : textColor,
                          fontSize: 16,
                        ),
                        code: TextStyle(
                          inherit: false,
                          backgroundColor: CupertinoColors.black.withAlpha(25),
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color:
                              message.isError
                                  ? CupertinoColors.white
                                  : textColor,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: CupertinoColors.black.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, bool disabled) {
    // Wrap input area with SafeArea to avoid system intrusions (like keyboard)
    return SafeArea(
      top: false, // Only apply padding to the bottom
      left: true, // Apply horizontal padding if needed
      right: true,
      child: Container(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
                style: TextStyle(
                  color: CupertinoColors.label.resolveFrom(context),
                  inherit: false,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemFill.resolveFrom(
                    context,
                  ),
                  borderRadius: BorderRadius.circular(18.0),
                ),
                enabled: !disabled,
                keyboardAppearance: CupertinoTheme.of(context).brightness,
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
      ),
    );
  }
}

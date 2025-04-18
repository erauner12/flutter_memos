import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart' show LinearProgressIndicator; // For loading bar
import 'package:flutter_markdown/flutter_markdown.dart'; // For rendering markdown
import 'package:flutter_memos/main.dart'; // Import for rootNavigatorKeyProvider
import 'package:flutter_memos/models/chat_message.dart'; // Import ChatMessage which now defines Role
import 'package:flutter_memos/models/workbench_item_type.dart';
import 'package:flutter_memos/providers/chat_overlay_providers.dart'; // Import overlay provider
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
    // Don't process context here, wait for didChangeDependencies or provider updates
    // Check initial context from provider state in case it was set before screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialContext();
    });
  }

  // Check context when dependencies change (e.g., ModalRoute available)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Process context arguments only once when the screen is loaded with them
    // This handles cases where ChatScreen might be pushed directly (e.g., /chat route)
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
        // Scroll down when AI starts loading
        _scrollToBottom();
      }
    });

    // Listen for context changes from the provider (e.g., set by deep link handler)
    ref.listen(chatProvider.select((state) => state.currentContextItemId), (
      _,
      nextContextId,
    ) {
      if (nextContextId != null && !_contextProcessed && mounted) {
        // Context was set externally after initial build/check
        _contextProcessed = true; // Mark as processed
        if (kDebugMode) {
          print("ChatScreen: Context updated via provider listener.");
        }
      } else if (nextContextId == null && _contextProcessed) {
        // Context was cleared, reset the flag
        _contextProcessed = false;
        if (kDebugMode) {
          print("ChatScreen: Context cleared, resetting processed flag.");
        }
      }
    });


    // Show loading indicator during initial session load
    // Use a simple Container instead of CupertinoPageScaffold
    if (chatState.isInitializing) {
      return const Center(child: CupertinoActivityIndicator());
    }

    // Removed CupertinoPageScaffold and CupertinoNavigationBar
    return SafeArea(
      // Keep SafeArea at the top level of the screen content
      // Ensure SafeArea does not apply padding when inside the overlay (handled by overlay padding)
      // However, keep it for potential direct use of ChatScreen via routing.
      // Let the overlay manage its own padding.
      top: false, // Overlay handles top padding
      bottom: true, // Let SafeArea handle bottom padding for input area
      left: false, // Overlay handles horizontal padding
      right: false,
      child: Column(
        children: [
          // --- Top Bar Area (Replaces Navigation Bar) ---
          Container(
            padding: const EdgeInsets.only(
              left: 50,
              right: 16,
              top: 8,
              bottom: 4,
            ), // Adjust padding (left accommodates close button)
            decoration: BoxDecoration(
              // Optional: Add a subtle background or border if needed
              // color: CupertinoTheme.of(context).barBackgroundColor.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator
                      .resolveFrom(context)
                      .withOpacity(0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title (Optional, can be simpler)
                Text(
                  'Chat (${mcpState.connectedServerCount} MCP)',
                  style: CupertinoTheme.of(
                    context,
                  ).textTheme.navTitleTextStyle.copyWith(fontSize: 16),
                ),
                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sync Button
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minSize: 0,
                      onPressed:
                          chatState.isSyncing || chatState.isInitializing
                              ? null // Disable while syncing or initializing
                              : () {
                                ref
                                    .read(chatProvider.notifier)
                                    .forceFetchFromCloud();
                              },
                      child:
                          chatState.isSyncing
                              ? const CupertinoActivityIndicator(radius: 10)
                              : const Icon(
                                CupertinoIcons.cloud_download,
                                size: 22,
                              ),
                    ),
                    // Trash Button
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minSize: 0,
                      onPressed:
                          chatState.isSyncing || chatState.isInitializing
                              ? null // Disable while syncing or initializing
                              : () {
                                // Confirmation could be added here
                                ref.read(chatProvider.notifier).clearChat();
                                // Reset context processed flag if chat is cleared manually
                                setState(() {
                                  _contextProcessed = false;
                                });
                              },
                      child: const Icon(CupertinoIcons.trash, size: 20),
                    ),
                    // Settings Button
                    CupertinoButton(
                      padding: const EdgeInsets.only(
                        left: 8,
                        right: 0,
                      ), // Adjust padding
                      minSize: 0,
                      onPressed:
                          chatState.isSyncing || chatState.isInitializing
                              ? null // Disable while syncing or initializing
                              : () {
                                // Use root navigator to push settings screen over the overlay
                                final rootNavigator = ref.read(
                                  rootNavigatorKeyProvider,
                                );
                                rootNavigator.currentState?.push(
                                  CupertinoPageRoute(
                                    builder:
                                        (context) => const SettingsScreen(
                                          isInitialSetup: false,
                                        ),
                                  ),
                                );
                                // Optionally close the overlay when navigating away
                                // ref.read(chatOverlayVisibleProvider.notifier).state = false;
                              },
                      child: const Icon(CupertinoIcons.settings, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Display AI loading indicator
          if (chatState.isLoading) const LinearProgressIndicator(minHeight: 2),
          // Display general error message
          if (chatState.errorMessage != null)
            Container(
              color: CupertinoColors.systemRed.withAlpha(25),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        inherit: false, // Explicitly set inherit
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
                            ref.read(chatProvider.notifier).clearErrorMessage(),
                  ),
                ],
              ),
            ),
          // Display API key warning
          if (!isApiKeySet)
            Container(
              color: CupertinoColors.systemYellow.withAlpha(38),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        ), // Use resolved color
                        inherit: false, // Explicitly set inherit
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Display Context Indicator
          if (chatState.currentContextItemId != null)
            GestureDetector(
              // Wrap with GestureDetector
              onTap: () {
                // Navigate back ONLY if it's a note (for now)
                if (chatState.currentContextItemType ==
                        WorkbenchItemType.note &&
                    chatState.currentContextItemId != null) {
                  final rootNavigator = ref.read(rootNavigatorKeyProvider);
                  rootNavigator.currentState?.pushNamed(
                    '/item-detail', // Assuming this is the route for Note detail
                    arguments: {'itemId': chatState.currentContextItemId},
                  );
                  // Optionally close the overlay when navigating away
                  ref.read(chatOverlayVisibleProvider.notifier).state = false;
                }
                // No action for tapping on Task context yet
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
                          // Make icon blue only if tappable (Note)
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
                        // Use the updated helper function
                        "Context: ${_getItemTypeName(chatState.currentContextItemType)} ${chatState.currentContextItemId?.substring(0, 8)}...", // Shorten ID
                        style: TextStyle(
                          inherit: false, // Explicitly set inherit
                          color:
                              // Make text blue and underlined only if tappable (Note)
                              chatState.currentContextItemType ==
                                      WorkbenchItemType.note
                                  ? CupertinoColors.systemBlue
                                  : CupertinoColors.secondaryLabel.resolveFrom(
                                    context,
                                  ),
                          fontSize: 13,
                          decoration:
                              chatState.currentContextItemType ==
                                      WorkbenchItemType.note
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                          decorationColor:
                              CupertinoColors
                                  .systemBlue, // Ensure underline color matches text
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Add a clear context button
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
                          _contextProcessed =
                              false; // Reset flag when context cleared
                        });
                      },
                    )
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
                // Don't display system messages
                if (message.role == Role.system) {
                  return const SizedBox.shrink();
                }
                return _buildMessageBubble(message);
              },
            ),
          ),
          // Input Area
          _buildInputArea(
            context,
            chatState.isLoading ||
                chatState.isSyncing || // Disable input while syncing
                !isApiKeySet,
          ),
        ],
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
              // Constrain width relative to the overlay width, not full screen
              maxWidth:
                  MediaQuery.of(context).size.width *
                  0.85 *
                  0.75, // 75% of overlay width
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
                          inherit: false, // Explicitly set inherit
                          color:
                              message.isError
                                  ? CupertinoColors.white
                                  : textColor,
                          fontSize: 16,
                        ),
                        code: TextStyle(
                          inherit: false, // Explicitly set inherit
                          backgroundColor: CupertinoColors.black.withAlpha(25),
                          fontFamily: 'monospace',
                          fontSize: 14, // Slightly smaller for code
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
              style: TextStyle(
                // Ensure text field text color is correct
                color: CupertinoColors.label.resolveFrom(context),
                inherit: false,
              ),
               decoration: BoxDecoration(
                 color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                 borderRadius: BorderRadius.circular(18.0),
               ),
               enabled: !disabled,
              keyboardAppearance:
                  CupertinoTheme.of(
                    context,
                  ).brightness, // Match keyboard to theme
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

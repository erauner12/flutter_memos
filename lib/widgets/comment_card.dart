import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/comment_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/todoist_api/lib/api.dart'
    as todoist; // For error types
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

// Convert to ConsumerStatefulWidget
class CommentCard extends ConsumerStatefulWidget {
  final Comment comment;
  final String memoId; // Keep memoId if needed for context/actions
  final bool isSelected;
  final bool isEditing; // Keep editing state if used elsewhere

  // Remove actions parameter, actions are now internal to this widget
  const CommentCard({
    super.key,
    required this.comment,
    required this.memoId,
    this.isSelected = false,
    this.isEditing = false,
  });

  @override
  ConsumerState<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends ConsumerState<CommentCard> {
  bool _isDeleting = false;
  bool _isSendingToTodoist = false; // State for Todoist loading indicator
  bool _isFixingGrammar = false; // State for grammar fix loading indicator

  // Helper to show dialogs safely after async gaps
  void _showDialog(String title, String content, {bool isError = false}) {
    if (!mounted) return; // Check mounted BEFORE using context
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  Future<void> _sendCommentToTodoist(Comment comment) async {
    final todoistService = ref.read(todoistApiServiceProvider);

    // 1. Check if configured
    if (!todoistService.isConfigured) {
      _showDialog(
        'Todoist Not Configured',
        'Please add your Todoist API key in Settings > Integrations.',
        isError: true,
      );
      return;
    }

    // 2. Parse content for pre-population
    final fullContent = comment.content.trim();
    if (fullContent.isEmpty) {
      _showDialog(
        'Empty Comment',
        'Cannot send empty comment to Todoist',
        isError: true,
      );
      return;
    }

    String initialTitle;
    String initialDescription;
    final newlineIndex = fullContent.indexOf('\n');

    if (newlineIndex != -1) {
      initialTitle = fullContent.substring(0, newlineIndex).trim();
      initialDescription = fullContent;
    } else {
      initialTitle = fullContent;
      initialDescription = fullContent;
    }

    // 3. Show form dialog
    if (!mounted) return;
    final result = await _showTodoistTaskForm(
      initialTitle: initialTitle,
      initialDescription: initialDescription,
    );
    
    // If user cancelled, result will be null
    if (result == null) return;
    
    // 4. Extract form values
    final taskContent = result['title'] as String;
    final taskDescription = result['description'] as String;
    
    if (taskContent.isEmpty) {
      _showDialog(
        'Empty Title',
        'Cannot create Todoist task with empty title',
        isError: true,
      );
      return;
    }

    // 5. Show loading
    setState(() => _isSendingToTodoist = true);

    // 6. Call API
    try {
      if (kDebugMode) {
        print(
          '[Todoist Send] Creating task: "$taskContent" / Desc: "$taskDescription"',
        );
      }
      final createdTask = await todoistService.createTask(
        content: taskContent,
        description: taskDescription,
        // Add other default parameters if desired (e.g., projectId, labels)
      );

      if (kDebugMode) {
        print('[Todoist Send] Success! Task ID: ${createdTask.id}');
      }

      // 7. Show Success using dialog
      _showDialog(
        'Success',
        'Sent to Todoist: "${createdTask.content ?? "Task"}"',
      );
    } on todoist.ApiException catch (e) {
      if (kDebugMode) {
        print('[Todoist Send] API Error: ${e.message} (Code: ${e.code})');
      }
      _showDialog(
        'Todoist Error',
        'Failed to create task.\n\nAPI Error ${e.code}: ${e.message ?? "Unknown error"}',
        isError: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[Todoist Send] General Error: $e');
      }
      _showDialog(
        'Error',
        'An unexpected error occurred: ${e.toString()}',
        isError: true,
      );
    } finally {
      // Hide loading
      if (mounted) {
        setState(() => _isSendingToTodoist = false);
      }
    }
  }

  Future<void> _fixGrammar(BuildContext context) async {
    final fullId = '${widget.memoId}/${widget.comment.id}';

    if (mounted) {
      setState(() {
        _isFixingGrammar = true;
      });
    }

    try {
      // Call the provider to fix grammar
      await ref.read(fixCommentGrammarProvider(fullId).future);

      if (mounted) {
        _showDialog('Success', 'Grammar corrected successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showDialog('Error', 'Failed to fix grammar: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFixingGrammar = false;
        });
      }
    }
  }

  Future<Map<String, String>?> _showTodoistTaskForm({
    required String initialTitle,
    required String initialDescription,
  }) async {
    // Create controllers for the form fields
    final titleController = TextEditingController(text: initialTitle);
    final descriptionController = TextEditingController(text: initialDescription);
    
    // Create focus nodes for field navigation
    final titleFocusNode = FocusNode();
    final descriptionFocusNode = FocusNode();
    
    try {
      // Show dialog and wait for result
      return await showCupertinoDialog<Map<String, String>>(
        context: context,
        builder: (context) {
          // Get the available height for the dialog content
          final availableHeight = MediaQuery.of(context).size.height * 0.7;
          
          return CupertinoAlertDialog(
            title: const Text('Create Todoist Task'),
            content: SizedBox(
              // Constrain height to prevent overflow
              width: double.maxFinite,
              height: min(availableHeight, 350),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // Title label
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      'Task Title',
                      style: TextStyle(
                        color: CupertinoColors.label.resolveFrom(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Title field - single line with Cupertino styling
                  CupertinoTextField(
                    controller: titleController,
                    focusNode: titleFocusNode,
                    placeholder: 'Enter task title',
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    clearButtonMode: OverlayVisibilityMode.editing,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                    onSubmitted: (_) {
                      titleFocusNode.unfocus();
                      descriptionFocusNode.requestFocus();
                    },
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemFill.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description label
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      'Task Description',
                      style: TextStyle(
                        color: CupertinoColors.label.resolveFrom(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  // Description field - multi-line, scrollable with Cupertino styling
                  Expanded(
                    child: CupertinoTextField(
                      controller: descriptionController,
                      focusNode: descriptionFocusNode,
                      placeholder: 'Enter task description',
                      padding: const EdgeInsets.all(10),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemFill.resolveFrom(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.of(context).pop({
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                  });
                },
                child: const Text('Create Task'),
              ),
            ],
          );
        },
      );
    } finally {
      // Clean up controllers and focus nodes
      titleController.dispose();
      descriptionController.dispose();
      titleFocusNode.dispose();
      descriptionFocusNode.dispose();
    }
  }

  void _showContextMenu(BuildContext context) {
    final fullId = '${widget.memoId}/${widget.comment.id}';

    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: const Text('Comment Actions'),
            actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Text('Edit'),
            onPressed: () {
                  Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/edit-entity',
                arguments: {'entityType': 'comment', 'entityId': fullId},
              );
            },
          ),
          CupertinoActionSheetAction(
            child: Text(widget.comment.pinned ? 'Unpin' : 'Pin'),
            onPressed: () {
              Navigator.pop(context);
              _onTogglePin(context);
            },
          ),
              // Fix Grammar option
              CupertinoActionSheetAction(
                // Disable button while processing
                isDefaultAction:
                    !_isFixingGrammar, // Make it default if not loading
                onPressed:
                    _isFixingGrammar
                        ? () {} // Empty callback when disabled
                        : () {
                          Navigator.pop(context); // Close the action sheet
                          _fixGrammar(
                            context,
                          ); // Call the grammar fixing method
                        },
                child:
                    _isFixingGrammar
                        ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CupertinoActivityIndicator(radius: 10),
                            SizedBox(width: 10),
                            Text('Fixing Grammar...'),
                          ],
                        )
                        : const Text('Fix Grammar (AI)'),
              ),
              // Add Send to Todoist action here
              CupertinoActionSheetAction(
                child: const Text('Send to Todoist'),
                onPressed: () {
                  Navigator.pop(context);
                  _sendCommentToTodoist(widget.comment);
                },
              ),
          CupertinoActionSheetAction(
            child: const Text('Copy Content'),
            onPressed: () async {
              Navigator.pop(context);
              await Clipboard.setData(ClipboardData(text: widget.comment.content));
                  _showDialog('Copied', 'Comment copied to clipboard.');
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Copy Link'),
            onPressed: () async {
              Navigator.pop(context);
              final url = 'flutter-memos://comment/${widget.memoId}/${widget.comment.id}';
              await Clipboard.setData(ClipboardData(text: url));
                  _showDialog('Copied', 'Comment link copied to clipboard.');
            },
          ),
              CupertinoActionSheetAction(
            child: const Text('Convert to Memo'),
            onPressed: () {
              Navigator.pop(context);
              _onConvertToMemo(context);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Hide'),
            onPressed: () {
              Navigator.pop(context);
              _onHide(context);
            },
          ),
              CupertinoActionSheetAction(
            child: const Text('Archive'),
            onPressed: () {
              Navigator.pop(context);
              _onArchive(context);
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
                  _onDelete(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _onTogglePin(BuildContext context) async {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    try {
      await ref.read(togglePinCommentProvider(fullId))();
    } catch (e) {
      _showDialog('Error', 'Failed to toggle pin: $e', isError: true);
    }
  }

  Future<void> _onDelete(BuildContext context) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('Delete Comment'),
            content: const Text(
              'Are you sure you want to delete this comment?',
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    final fullId = '${widget.memoId}/${widget.comment.id}';

    try {
      await ref.read(deleteCommentProvider(fullId))();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
      _showDialog('Error', 'Failed to delete comment: $e', isError: true);
    }
    // No need to set _isDeleting back to false on success, as the widget will be removed
  }

  void _onArchive(BuildContext context) async {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    try {
      await ref.read(archiveCommentProvider(fullId))();
    } catch (e) {
      _showDialog('Error', 'Failed to archive comment: $e', isError: true);
    }
  }

  void _onConvertToMemo(BuildContext context) async {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    try {
      // Use the correct provider name
      final convertFunction = ref.read(convertCommentToNoteProvider(fullId));
      await convertFunction();
    } catch (e) {
      _showDialog(
        'Error',
        'Failed to convert comment to memo: $e',
        isError: true,
      );
    }
  }

  void _onHide(BuildContext context) {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    ref.read(toggleHideCommentProvider(fullId))();
  }

  void _toggleMultiSelection() {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    final currentSelection = Set<String>.from(
      ref.read(selectedCommentIdsForMultiSelectProvider),
    );

    if (currentSelection.contains(fullId)) {
      currentSelection.remove(fullId);
    } else {
      currentSelection.add(fullId);
    }

    ref.read(selectedCommentIdsForMultiSelectProvider.notifier).state =
        currentSelection;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final textColor =
        widget.comment.pinned
            ? CupertinoColors.systemBlue.resolveFrom(context)
            : CupertinoColors.label.resolveFrom(context);

    // Use updateTime with fallback to createTime
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      widget.comment.updateTime ?? widget.comment.createTime,
    );
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final formattedDate = dateFormat.format(dateTime);
    final isMultiSelectMode = ref.watch(commentMultiSelectModeProvider);
    final selectedIds = ref.watch(selectedCommentIdsForMultiSelectProvider);
    final fullId = '${widget.memoId}/${widget.comment.id}';
    final isMultiSelected = selectedIds.contains(fullId);

    final highlightedCommentId = ref.watch(highlightedCommentIdProvider);
    final bool isHighlighted = highlightedCommentId == widget.comment.id;

    Color cardBackgroundColor;
    BorderSide cardBorderStyle;

    if (isHighlighted) {
      cardBackgroundColor = isDarkMode
              ? CupertinoColors.systemTeal.darkColor.withAlpha(100)
              : CupertinoColors.systemTeal.color.withAlpha(50);
      cardBorderStyle = BorderSide(
        color: isDarkMode
            ? CupertinoColors.systemTeal.darkColor
            : CupertinoColors.systemTeal.color,
        width: 2,
      );
    } else if (widget.isSelected && !isMultiSelectMode) {
      cardBackgroundColor = CupertinoColors.systemGrey4.resolveFrom(context);
      cardBorderStyle = BorderSide(
        color: CupertinoColors.systemGrey2.resolveFrom(context),
        width: 1,
      );
    } else {
      cardBackgroundColor = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
      cardBorderStyle = BorderSide.none;
    }

    if (isHighlighted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            ref.read(highlightedCommentIdProvider) == widget.comment.id) {
          ref.read(highlightedCommentIdProvider.notifier).state = null;
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            alignment: 0.5,
          );
        }
      });
    }

    if (_isDeleting) {
      return const SizedBox.shrink();
    }

    final apiService = ref.watch(apiServiceProvider);
    final baseUrl = apiService.apiBaseUrl;

    final cardKey =
        isHighlighted
            ? Key('highlighted-comment-card-${widget.comment.id}')
            : (widget.isSelected && !isMultiSelectMode
                ? Key('selected-comment-card-${widget.comment.id}')
                : null);

    Widget commentCardWidget = Container(
      key: cardKey,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.fromBorderSide(cardBorderStyle),
        boxShadow:
            !isDarkMode && !widget.isSelected && !isHighlighted
                ? [
                  BoxShadow(
                    color: CupertinoColors.black.withAlpha(25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
                : null,
      ),
      child: GestureDetector(
        onLongPress: isMultiSelectMode ? () => _toggleMultiSelection() : () => _showContextMenu(context),
        onTap: isMultiSelectMode ? () => _toggleMultiSelection() : null,
        onVerticalDragStart: null,
        onVerticalDragUpdate: null,
        onVerticalDragEnd: null,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.comment.content.isNotEmpty)
                MarkdownBody(
                  data: widget.comment.content,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight:
                          widget.comment.pinned
                              ? FontWeight.w500
                              : FontWeight.normal,
                    ),
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  shrinkWrap: true,
                  onTapLink: (text, href, title) {
                    if (kDebugMode) {
                      print(
                        '[CommentCard] Link tapped in comment ${widget.comment.id}: "$text" -> "$href"',
                      );
                    }
                    if (href != null) {
                      UrlHelper.launchUrl(href, ref: ref, context: context);
                    }
                  },
                ),
              if (widget.comment.resources != null &&
                  widget.comment.resources!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    top: widget.comment.content.isNotEmpty ? 8.0 : 0.0,
                  ),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children:
                        (widget.comment.resources ?? [])
                            // Access 'contentType' key in the map
                            .where(
                              (r) =>
                                  (r['contentType'] as String?)?.startsWith(
                                    'image/',
                                  ) ??
                                  false,
                            )
                            .map((resource) {
                              // Access keys from the map
                              final String? resourceName =
                                  resource['name'] as String?;
                              final String? filename =
                                  resource['filename'] as String?;
                              final String? externalLink =
                                  resource['externalLink']
                                      as String?; // Use externalLink or specific API path
                              final String? memosResourceName =
                                  resourceName?.startsWith('resources/') == true
                                      ? resourceName?.split('/').last
                                      : resourceName; // Extract Memos ID if needed
                              final String? blinkoPath =
                                  resource['blinkoPath']
                                      as String?; // Example if Blinko path is stored

                              // Construct URL based on available data (adjust logic as needed for different APIs)
                              String? imageUrl;
                              if (baseUrl.isNotEmpty && externalLink != null) {
                                // Generic external link
                                imageUrl = externalLink;
                              } else if (baseUrl.isNotEmpty &&
                                  memosResourceName != null &&
                                  filename != null) {
                                // Memos specific URL structure
                                final encodedFilename = Uri.encodeComponent(
                                  filename,
                                );
                                imageUrl =
                                    '$baseUrl/o/r/$memosResourceName/$encodedFilename';
                              } else if (baseUrl.isNotEmpty &&
                                  blinkoPath != null) {
                                // Blinko specific URL structure (if different)
                                imageUrl = '$baseUrl$blinkoPath'; // Example
                              }

                              if (imageUrl != null) {
                                return ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 200,
                                    maxHeight: 200,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (
                                        context,
                                        child,
                                        loadingProgress,
                                      ) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          alignment: Alignment.center,
                                          color: CupertinoColors.systemGrey5
                                              .resolveFrom(context),
                                          child:
                                              const CupertinoActivityIndicator(
                                                radius: 10,
                                              ),
                                        );
                                      },
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          color: CupertinoColors.systemGrey5
                                              .resolveFrom(context),
                                          child: const Icon(
                                            CupertinoIcons
                                                .exclamationmark_circle,
                                            color: CupertinoColors.systemGrey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            })
                            .toList(),
                  ),
                ),
              if (widget.comment.content.isNotEmpty &&
                  widget.comment.resources != null &&
                  widget.comment.resources!.isNotEmpty)
                const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  // Combine internal actions (pin) with external actions (Todoist)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.comment.pinned)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            CupertinoIcons.pin_fill,
                            size: 16,
                            color: CupertinoColors.systemBlue.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      // Add the Todoist button logic here
                      if (_isSendingToTodoist)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: CupertinoActivityIndicator(
                            radius: 9,
                          ),
                        )
                      else
                        CupertinoButton(
                          padding: const EdgeInsets.all(4),
                          minSize: 0,
                          child: Icon(
                            CupertinoIcons.paperplane,
                            size: 18,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                          onPressed:
                              () => _sendCommentToTodoist(widget.comment),
                        ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (isMultiSelectMode) {
      // Wrap with Row for checkbox in multi-select mode
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12.0, right: 8.0),
              child: CupertinoCheckbox(
                value: isMultiSelected,
                onChanged: (value) => _toggleMultiSelection(),
                activeColor: CupertinoTheme.of(context).primaryColor,
              ),
            ),
            Expanded(child: commentCardWidget),
          ],
        ),
      );
    } else {
      // Wrap with Slidable for normal mode
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Slidable(
          key: Key('slidable-comment-${widget.comment.id}'),
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (_) => _onTogglePin(context),
                backgroundColor: CupertinoColors.systemBlue,
                foregroundColor: CupertinoColors.white,
                icon:
                    widget.comment.pinned
                        ? CupertinoIcons.pin_slash_fill
                        : CupertinoIcons.pin_fill,
                label: widget.comment.pinned ? 'Unpin' : 'Pin',
                autoClose: true,
              ),
              SlidableAction(
                onPressed: (_) => _onConvertToMemo(context),
                backgroundColor: CupertinoColors.systemTeal,
                foregroundColor: CupertinoColors.white,
                icon: CupertinoIcons.doc_text_fill,
                label: 'To Memo',
                autoClose: true,
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (_) => _onDelete(context),
                backgroundColor: CupertinoColors.destructiveRed,
                foregroundColor: CupertinoColors.white,
                icon: CupertinoIcons.delete,
                label: 'Delete',
                autoClose: true,
              ),
              SlidableAction(
                onPressed: (_) => _onArchive(context),
                backgroundColor: CupertinoColors.systemPurple,
                foregroundColor: CupertinoColors.white,
                icon: CupertinoIcons.archivebox_fill,
                label: 'Archive',
                autoClose: true,
              ),
            ],
          ),
          child: commentCardWidget,
        ),
      );
    }
  }
}

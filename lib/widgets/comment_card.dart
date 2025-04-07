import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/api_providers.dart'; // Import apiServiceProvider
import 'package:flutter_memos/providers/comment_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class CommentCard extends ConsumerStatefulWidget {
  final Comment comment;
  final String memoId;
  final bool isSelected;

  const CommentCard({
    super.key,
    required this.comment,
    required this.memoId,
    this.isSelected = false,
  });

  @override
  ConsumerState<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends ConsumerState<CommentCard> {
  bool _isDeleting = false;

  void _showContextMenu(BuildContext context) {
    final fullId = '${widget.memoId}/${widget.comment.id}';

    // Replace showModalBottomSheet with showCupertinoModalPopup
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet( // Use CupertinoActionSheet
        title: const Text('Comment Actions'), // Optional title
        actions: <CupertinoActionSheetAction>[
          // Replicate actions using CupertinoActionSheetAction
          CupertinoActionSheetAction(
            child: const Text('Edit'),
            onPressed: () {
              Navigator.pop(context); // Close sheet first
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
          CupertinoActionSheetAction(
            child: const Text('Copy Content'),
            onPressed: () async {
              Navigator.pop(context);
              await Clipboard.setData(ClipboardData(text: widget.comment.content));
              if (!mounted) return;
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('Copied'),
                  content: const Text('Comment copied to clipboard.'),
                  actions: [ CupertinoDialogAction(isDefaultAction: true, child: const Text('OK'), onPressed: () => Navigator.pop(context)) ],
                ),
              );
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Copy Link'),
            onPressed: () async {
              Navigator.pop(context);
              final url = 'flutter-memos://comment/${widget.memoId}/${widget.comment.id}';
              await Clipboard.setData(ClipboardData(text: url));
               if (!mounted) return;
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('Copied'),
                  content: const Text('Comment link copied to clipboard.'),
                  actions: [ CupertinoDialogAction(isDefaultAction: true, child: const Text('OK'), onPressed: () => Navigator.pop(context)) ],
                ),
              );
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
              _onDelete(context); // Assumes onDelete handles confirmation
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
      if (!mounted) return;
      
      // Confirmation removed - UI update is sufficient
      // ScaffoldMessenger.of(context).showSnackBar(...);

    } catch (e) {
      if (!mounted) return;
      // Replace SnackBar with CupertinoAlertDialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Failed to toggle pin: $e'),
          actions: [ CupertinoDialogAction(isDefaultAction: true, child: const Text('OK'), onPressed: () => Navigator.pop(context)) ],
        ),
      );
    }
  }

  Future<void> _onDelete(BuildContext context) async {
    // Replace showDialog with showCupertinoDialog
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog( // Use CupertinoAlertDialog
            title: const Text('Delete Comment'),
            content: const Text(
              'Are you sure you want to delete this comment?',
            ),
            actions: [
              // Replace TextButton with CupertinoDialogAction
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

      // Confirmation removed - UI update is sufficient
      // if (!mounted) return;
      // ScaffoldMessenger.of(context).showSnackBar(...);

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
      // Replace SnackBar with CupertinoAlertDialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Failed to delete comment: $e'),
          actions: [ CupertinoDialogAction(isDefaultAction: true, child: const Text('OK'), onPressed: () => Navigator.pop(context)) ],
        ),
      );
    }
  }

  void _onArchive(BuildContext context) async {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    try {
      await ref.read(archiveCommentProvider(fullId))();
      // Confirmation removed - UI update is sufficient
      // if (!mounted) return;
      // ScaffoldMessenger.of(context).showSnackBar(...);
    } catch (e) {
      if (!mounted) return;
      // Replace SnackBar with CupertinoAlertDialog
       showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Failed to archive comment: $e'),
          actions: [ CupertinoDialogAction(isDefaultAction: true, child: const Text('OK'), onPressed: () => Navigator.pop(context)) ],
        ),
      );
    }
  }

  void _onConvertToMemo(BuildContext context) async {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    try {
      final convertFunction = ref.read(convertCommentToMemoProvider(fullId));
      await convertFunction();
      // Confirmation removed - UI update is sufficient
      // if (!mounted) return;
      // ScaffoldMessenger.of(context).showSnackBar(...);
    } catch (e) {
      if (!mounted) return;
      // Replace SnackBar with CupertinoAlertDialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Failed to convert comment to memo: $e'),
          actions: [ CupertinoDialogAction(isDefaultAction: true, child: const Text('OK'), onPressed: () => Navigator.pop(context)) ],
        ),
      );
    }
  }

  void _onHide(BuildContext context) {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    ref.read(toggleHideCommentProvider(fullId))();
    // Confirmation removed - UI update is sufficient
    // ScaffoldMessenger.of(context).showSnackBar(...);
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

    if (kDebugMode) {
      print('[CommentCard] Multi-selection toggled for comment ID: ${widget.comment.id}');
      print('[CommentCard] Current selection: ${currentSelection.join(', ')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use CupertinoTheme for brightness check
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final textColor =
        widget.comment.pinned
            ? CupertinoColors.systemBlue.resolveFrom(
              context,
            ) // Use Cupertino color
            : (isDarkMode
                ? CupertinoColors.white
                : CupertinoColors.label.resolveFrom(
                  context,
                )); // Use Cupertino colors

    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      widget.comment.createTime,
    );
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final formattedDate = dateFormat.format(dateTime);
    final isMultiSelectMode = ref.watch(commentMultiSelectModeProvider);
    final selectedIds = ref.watch(selectedCommentIdsForMultiSelectProvider);
    final fullId = '${widget.memoId}/${widget.comment.id}';
    final isMultiSelected = selectedIds.contains(fullId);

    // Determine if the card should be highlighted
    final highlightedCommentId = ref.watch(highlightedCommentIdProvider);
    final bool isHighlighted = highlightedCommentId == widget.comment.id;

    // Add debug prints
    if (kDebugMode) {
      print('[CommentCard build] Comment ID: ${widget.comment.id}');
      print('[CommentCard build] Highlighted ID from provider: $highlightedCommentId');
      print('[CommentCard build] isHighlighted: $isHighlighted');
    }

    // Define card style variables
    Color cardBackgroundColor;
    BorderSide cardBorderStyle;

    // Determine card style based on selection and highlight state
    if (isHighlighted) {
      cardBackgroundColor = isDarkMode
          ? CupertinoColors.systemTeal.darkColor.withAlpha(100) // Adjusted alpha
          : CupertinoColors.systemTeal.color.withAlpha(50); // Adjusted alpha
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

    // Add debug prints for final style
    if (kDebugMode) {
      print('[CommentCard build] Final cardColor: $cardBackgroundColor');
      print('[CommentCard build] Final cardBorder: $cardBorderStyle');
    }

    // Reset highlight state after build if it was highlighted
    if (isHighlighted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            ref.read(highlightedCommentIdProvider) == widget.comment.id) {
          if (kDebugMode) {
            print(
              '[CommentCard] Resetting highlight for comment ${widget.comment.id}',
            );
          }
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
    
    // Define card key
    final cardKey =
        isHighlighted
            ? Key('highlighted-comment-card-${widget.comment.id}')
            : (widget.isSelected && !isMultiSelectMode
                ? Key('selected-comment-card-${widget.comment.id}')
                : null);

    // Replace Card with Container
    Widget commentCardWidget = Container(
      key: cardKey,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.fromBorderSide(cardBorderStyle),
         // Add subtle shadow for light mode if desired
        boxShadow: !isDarkMode && !widget.isSelected && !isHighlighted ? [
          BoxShadow(
                    color: CupertinoColors.black.withAlpha(
                      25,
                    ), // Replace withOpacity with withAlpha
            blurRadius: 4,
            offset: const Offset(0, 1),
          )
        ] : null,
      ),
      // Replace InkWell with GestureDetector
      child: GestureDetector(
        onLongPress: isMultiSelectMode ? () => _toggleMultiSelection() : () => _showContextMenu(context),
        onTap: isMultiSelectMode ? () => _toggleMultiSelection() : null,
        // Add these lines to ignore vertical drags and set behavior
        onVerticalDragStart: null,
        onVerticalDragUpdate: null,
        onVerticalDragEnd: null,
        behavior:
            HitTestBehavior.opaque, // Ensure taps are still captured correctly
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
                        widget.comment.resources!
                            .where((r) => r.type?.startsWith('image/') ?? false)
                            .map((resource) {
                              final resourceName =
                                  resource.name?.split('/').last;
                              final filename = resource.filename;
                              if (baseUrl.isNotEmpty &&
                                  resourceName != null &&
                                  filename != null) {
                                final encodedFilename = Uri.encodeComponent(
                                  filename,
                                );
                                final imageUrl =
                                    '$baseUrl/o/r/$resourceName/$encodedFilename';

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
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          alignment: Alignment.center,
                                          color: CupertinoColors.systemGrey5.resolveFrom(context), // Use Cupertino color
                                          // Replace CircularProgressIndicator with CupertinoActivityIndicator
                                          child: const CupertinoActivityIndicator(
                                            radius: 10, // Adjust size
                                            // Value cannot be directly set for CupertinoActivityIndicator
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
                                          color: CupertinoColors.systemGrey5.resolveFrom(context), // Use Cupertino color
                                          child: const Icon(
                                            CupertinoIcons.exclamationmark_circle, // Use Cupertino icon
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
                      color: CupertinoColors.secondaryLabel.resolveFrom(context), // Use Cupertino color
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (widget.comment.pinned)
                    Icon( // Use Cupertino icon
                      CupertinoIcons.pin_fill,
                      size: 16,
                      color: CupertinoColors.systemBlue.resolveFrom(context), // Use Cupertino color
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (isMultiSelectMode) {
      if (isMultiSelected) {
        commentCardWidget = Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: CupertinoTheme.of(context).primaryColor, // Use Cupertino theme color
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: commentCardWidget,
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Align checkbox with top of card
          children: [
            // Replace Checkbox with CupertinoCheckbox
            Padding(
              padding: const EdgeInsets.only(top: 12.0, right: 8.0), // Adjust padding
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
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Slidable(
        key: Key('slidable-comment-${widget.comment.id}'),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _onTogglePin(context),
              backgroundColor: CupertinoColors.systemBlue, // Use Cupertino color
              foregroundColor: CupertinoColors.white,
              icon:
                  widget.comment.pinned
                      ? CupertinoIcons.pin_slash_fill // Use Cupertino icon
                      : CupertinoIcons.pin_fill, // Use Cupertino icon
              label: widget.comment.pinned ? 'Unpin' : 'Pin',
              autoClose: true,
            ),
            SlidableAction(
              onPressed: (_) => _onConvertToMemo(context),
              backgroundColor: CupertinoColors.systemTeal, // Use Cupertino color
              foregroundColor: CupertinoColors.white,
              icon: CupertinoIcons.doc_text_fill, // Use Cupertino icon
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
              backgroundColor: CupertinoColors.destructiveRed, // Use Cupertino color
              foregroundColor: CupertinoColors.white,
              icon: CupertinoIcons.delete, // Use Cupertino icon
              label: 'Delete',
              autoClose: true,
            ),
            SlidableAction(
              onPressed: (_) => _onArchive(context),
              backgroundColor: CupertinoColors.systemPurple, // Use Cupertino color
              foregroundColor: CupertinoColors.white,
              icon: CupertinoIcons.archivebox_fill, // Use Cupertino icon
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

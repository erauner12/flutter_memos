import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/api_providers.dart'; // Import apiServiceProvider
import 'package:flutter_memos/providers/comment_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_providers.dart'; // Import memoCommentsProvider
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_memos/widgets/comment_context_menu.dart';
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return CommentContextMenu(
          commentId: widget.comment.id,
          isPinned: widget.comment.pinned,
          onArchive: () async {
            Navigator.of(bottomSheetContext).pop();
            if (!mounted) return;
            _onArchive(context);
          },
          onDelete: () async {
            Navigator.of(bottomSheetContext).pop();
            if (!mounted) return;
            _onDelete(context);
          },
          onHide: () {
            Navigator.of(bottomSheetContext).pop();
            if (!mounted) return;
            _onHide(context);
          },
          onTogglePin: () async {
            Navigator.of(bottomSheetContext).pop();
            if (!mounted) return;
            _onTogglePin(context);
          },
          onCopy: () {
            Navigator.of(bottomSheetContext).pop();
            Clipboard.setData(ClipboardData(text: widget.comment.content)).then(
              (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comment copied to clipboard')),
                );
              },
            );
          },
          onCopyLink: () {
            Navigator.of(bottomSheetContext).pop();
            final url =
                'flutter-memos://comment/${widget.memoId}/${widget.comment.id}';
            Clipboard.setData(ClipboardData(text: url)).then((_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Comment link copied to clipboard'),
                ),
              );
            });
          },
          onConvertToMemo: () async {
            Navigator.of(bottomSheetContext).pop();
            if (!mounted) return;
            _onConvertToMemo(context);
          },
          onEdit: () {
            Navigator.of(bottomSheetContext).pop();
            if (!mounted) return;
            Navigator.pushNamed(
              context,
              '/edit-entity',
              arguments: {
                'entityType': 'comment',
                'entityId': fullId,
              },
            );
          },
          onClose: () {
            Navigator.of(bottomSheetContext).pop();
          },
        );
      },
    );
  }

  void _onTogglePin(BuildContext context) async {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    try {
      await ref.read(togglePinCommentProvider(fullId))();
      if (!mounted) return;

      final commentsData = ref.read(memoCommentsProvider(widget.memoId)).asData;
      final currentCommentState = commentsData?.value.firstWhere(
        (c) => c.id == widget.comment.id,
        orElse: () => widget.comment,
      );
      final isNowPinned = currentCommentState?.pinned ?? widget.comment.pinned;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowPinned ? 'Comment pinned' : 'Comment unpinned',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('Error toggling pin: $e')),
      );
    }
  }

  Future<void> _onDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Comment'),
            content: const Text(
              'Are you sure you want to delete this comment?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
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

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(content: Text('Comment deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('Error deleting comment: $e')),
      );
    }
  }

  void _onArchive(BuildContext context) async {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    try {
      await ref.read(archiveCommentProvider(fullId))();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(content: Text('Comment archived')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('Error archiving comment: $e')),
      );
    }
  }

  void _onConvertToMemo(BuildContext context) async {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    try {
      final convertFunction = ref.read(convertCommentToMemoProvider(fullId));
      await convertFunction();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment converted to memo')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('Error converting to memo: $e')),
      );
    }
  }

  void _onHide(BuildContext context) {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    ref.read(toggleHideCommentProvider(fullId))();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(content: Text('Comment hidden from view')),
    );
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        widget.comment.pinned
            ? Colors.blue
            : (isDarkMode ? Colors.white : Colors.black87);

    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      widget.comment.createTime,
    );
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final formattedDate = dateFormat.format(dateTime);

    final highlightedId = ref.watch(highlightedCommentIdProvider);
    final bool isHighlighted = highlightedId == widget.comment.id;

    final isMultiSelectMode = ref.watch(commentMultiSelectModeProvider);
    final selectedIds = ref.watch(selectedCommentIdsForMultiSelectProvider);
    final fullId = '${widget.memoId}/${widget.comment.id}';
    final isMultiSelected = selectedIds.contains(fullId);

    final selectedStyle = (
      color:
          isDarkMode
              ? Colors.grey.shade700.withOpacity(0.6)
              : Colors.grey.shade300,
      border: BorderSide(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        width: 1,
      ),
    );

    final highlightedStyle = (
      color: isDarkMode ? Colors.teal.shade900 : Colors.teal.shade50,
      border: const BorderSide(color: Colors.teal, width: 2),
    );

    final defaultStyle = (
      color: isDarkMode ? const Color(0xFF222222) : Colors.white,
      border: BorderSide.none,
    );

    Color? cardBackgroundColor;
    BorderSide cardBorderStyle;

    if (isHighlighted) {
      cardBackgroundColor = highlightedStyle.color;
      cardBorderStyle = highlightedStyle.border;
    } else if (widget.isSelected && !isMultiSelectMode) {
      cardBackgroundColor = selectedStyle.color;
      cardBorderStyle = selectedStyle.border;
    } else {
      cardBackgroundColor = defaultStyle.color;
      cardBorderStyle = defaultStyle.border;
    }

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

    Widget commentCardWidget = Card(
      key:
          isHighlighted
              ? Key('highlighted-comment-card-${widget.comment.id}')
              : (widget.isSelected && !isMultiSelectMode
                  ? Key('selected-comment-card-${widget.comment.id}')
                  : null),
      elevation:
          isHighlighted ? 4 : (widget.isSelected && !isMultiSelectMode ? 2 : 1),
      margin: EdgeInsets.zero,
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: cardBorderStyle,
      ),
      child: InkWell(
        onLongPress:
            isMultiSelectMode
                ? () => _toggleMultiSelection()
                : () => _showContextMenu(context),
        onTap: isMultiSelectMode ? () => _toggleMultiSelection() : null,
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
                      UrlHelper.launchUrl(href);
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
                                          color: Colors.grey[300],
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            value:
                                                loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
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
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
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
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (widget.comment.pinned)
                    const Icon(
                      Icons.push_pin,
                      size: 16,
                      color: Colors.blue,
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
              color: Theme.of(context).colorScheme.primary,
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
          children: [
            Checkbox(
              value: isMultiSelected,
              onChanged: (value) => _toggleMultiSelection(),
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
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon:
                  widget.comment.pinned
                      ? Icons.push_pin_outlined
                      : Icons.push_pin,
              label: widget.comment.pinned ? 'Unpin' : 'Pin',
              autoClose: true,
            ),
            SlidableAction(
              onPressed: (_) => _onConvertToMemo(context),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              icon: Icons.note_add,
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              autoClose: true,
            ),
            SlidableAction(
              onPressed: (_) => _onArchive(context),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              icon: Icons.archive,
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

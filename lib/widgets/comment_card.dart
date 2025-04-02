import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/comment_providers.dart';
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
            _onArchive(context);
          },
          onDelete: () async {
            Navigator.of(bottomSheetContext).pop();
            _onDelete(context);
          },
          onHide: () {
            Navigator.of(bottomSheetContext).pop();
            _onHide(context);
          },
          onTogglePin: () async {
            Navigator.of(bottomSheetContext).pop();
            _onTogglePin(context);
          },
          onCopy: () {
            Navigator.of(bottomSheetContext).pop();
            Clipboard.setData(
              ClipboardData(text: widget.comment.content),
            ).then((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comment copied to clipboard')),
                );
              }
            });
          },
          onConvertToMemo: () async {
            Navigator.of(bottomSheetContext).pop();
            _onConvertToMemo(context);
          },
          onEdit: () {
            // Add onEdit handler
            Navigator.of(bottomSheetContext).pop(); // Close bottom sheet first
            if (context.mounted) {
              // Check if context is still valid
              Navigator.pushNamed(
                context,
                '/edit-entity', // Use the new generic route name
                arguments: {
                  'entityType': 'comment',
                  'entityId': fullId, // Pass "memoId/commentId"
                },
              );
            }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.comment.pinned ? 'Comment unpinned' : 'Comment pinned',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text('Error toggling pin: $e')));
      }
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

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment deleted')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting comment: $e')));
      }
    }
  }

  void _onArchive(BuildContext context) async {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    try {
      await ref.read(archiveCommentProvider(fullId))();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(content: Text('Comment archived')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text('Error archiving comment: $e')));
      }
    }
  }

  void _onConvertToMemo(BuildContext context) async {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    try {
      final convertFunction = ref.read(convertCommentToMemoProvider(fullId));
      final memo = await convertFunction();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment converted to memo')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text('Error converting to memo: $e')));
      }
    }
  }

  void _onHide(BuildContext context) {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    ref.read(toggleHideCommentProvider(fullId))();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Comment hidden from view')),
    );
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

    if (_isDeleting) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Slidable(
        key: Key('slidable-comment-${widget.comment.id}'),
        // Left side (start) actions
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => _onTogglePin(context),
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
              onPressed: (context) => _onConvertToMemo(context),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              icon: Icons.note_add,
              label: 'To Memo',
              autoClose: true,
            ),
          ],
        ),
        
        // Right side (end) actions
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => _onDelete(context),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              autoClose: true,
            ),
            SlidableAction(
              onPressed: (context) => _onArchive(context),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              icon: Icons.archive,
              label: 'Archive',
              autoClose: true,
            ),
          ],
        ),
        child: Card(
          key:
              widget.isSelected
                  ? Key('selected-comment-card-${widget.comment.id}')
                  : null,
          elevation: widget.isSelected ? 3 : 1,
          margin: EdgeInsets.zero,
          color:
              widget.isSelected
                  ? (isDarkMode ? const Color(0xFF3A3A3A) : Colors.blue.shade50)
                  : (isDarkMode ? const Color(0xFF222222) : Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side:
                widget.isSelected
                    ? BorderSide(
                      color:
                          widget.isSelected
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                      width: widget.isSelected ? 3 : 2,
                    )
                    : BorderSide.none,
          ),
          child: InkWell(
            onLongPress: () => _showContextMenu(context),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      textScaleFactor: 1.0,
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
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
        ),
      ),
    );
  }
}

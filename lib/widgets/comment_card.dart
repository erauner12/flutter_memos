import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/comment_providers.dart';
import 'package:flutter_memos/widgets/comment_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            // Close the menu first
            Navigator.of(bottomSheetContext).pop();

            try {
              // Then archive the comment
              await ref.read(archiveCommentProvider(fullId))();

              // Show success message only if the widget is still mounted
              if (mounted) {
                // Use the most current context safely
                final currentContext = context;
                if (currentContext.mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(content: Text('Comment archived')),
                  );
                }
              }
            } catch (e) {
              // Show error message only if the widget is still mounted
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error archiving comment: $e')),
                );
              }
            }
          },
          onDelete: () async {
            // Close the menu first
            Navigator.of(bottomSheetContext).pop();

            // Confirm deletion
            if (!mounted) return;

            final confirmed = await showDialog<bool>(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: const Text('Delete Comment'),
                content: const Text('Are you sure you want to delete this comment?'),
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

            try {
              // Mark as deleting to remove from widget tree immediately
              setState(() {
                _isDeleting = true;
              });
              
              await ref.read(deleteCommentProvider(fullId))();

              // Show success message only if the widget is still mounted
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comment deleted')),
                );
              }
            } catch (e) {
              // In case of error, restore visibility
              if (mounted) {
                setState(() {
                  _isDeleting = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting comment: $e')),
                );
              }
            }
          },
          onHide: () {
            // Toggle visibility of comment in current view
            Navigator.of(bottomSheetContext).pop();
            ref.read(toggleHideCommentProvider(fullId))();
          },
          onTogglePin: () async {
            // Close the menu first
            Navigator.of(bottomSheetContext).pop();

            try {
              await ref.read(togglePinCommentProvider(fullId))();
              // Show success message only if the widget is still mounted
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.comment.pinned
                          ? 'Comment unpinned'
                          : 'Comment pinned',
                    ),
                  ),
                );
              }
            } catch (e) {
              // Show error message only if the widget is still mounted
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error toggling pin: $e')),
                );
              }
            }
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
            // Close the menu first
            Navigator.of(bottomSheetContext).pop();

            try {
              final fullId = '${widget.memoId}/${widget.comment.id}';
              final convertFunction = ref.read(
                convertCommentToMemoProvider(fullId),
              );
              final memo = await convertFunction();

              // Show success message only if the widget is still mounted
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comment converted to memo'),
                  ),
                );
              }
            } catch (e) {
              // Show error message only if the widget is still mounted
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error converting to memo: $e'),
                  ),
                );
              }
            }
          },
          onClose: () {
            Navigator.of(bottomSheetContext).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        widget.comment.pinned
            ? Colors.blue
            : (isDarkMode ? Colors.white : Colors.black87);
    
    // Format timestamp for display
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      widget.comment.createTime,
    );
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final formattedDate = dateFormat.format(dateTime);

    // Don't show the card at all if it's being deleted (addresses the Dismissible issue)
    if (_isDeleting) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Dismissible(
        key: Key('comment-${widget.comment.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          color: Colors.red,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          // Confirm deletion
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
          return confirmed ?? false;
        },
        onDismissed: (direction) async {
          // Mark as deleting to remove from widget tree immediately
          setState(() {
            _isDeleting = true;
          });
          
          final fullId = '${widget.memoId}/${widget.comment.id}';
          
          try {
            await ref.read(deleteCommentProvider(fullId))();
            
            // Only show snackbar if still mounted
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Comment deleted')),
              );
            }
          } catch (e) {
            // Only show error if still mounted
            if (mounted) {
              // In case of error, restore visibility
              setState(() {
                _isDeleting = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error deleting comment: $e')),
              );
            }
          }
        },
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
                  Text(
                    widget.comment.content,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight:
                          widget.comment.pinned
                              ? FontWeight.w500
                              : FontWeight.normal,
                    ),
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

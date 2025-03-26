import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/comment_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'comment_context_menu.dart';

class CommentCard extends ConsumerWidget {
  final Comment comment;
  final String memoId;
  final bool isSelected;
  
  const CommentCard({
    super.key,
    required this.comment,
    required this.memoId,
    this.isSelected = false,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: comment.content)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    final fullId = '$memoId/${comment.id}';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return CommentContextMenu(
          commentId: fullId,
          isPinned: comment.pinned,
          onArchive: () {
            Navigator.pop(context);
            ref.read(archiveCommentProvider(fullId))().then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Comment archived'),
                  duration: Duration(seconds: 2),
                ),
              );
            });
          },
          onDelete: () async {
            Navigator.pop(context);
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirm Delete'),
                content: const Text('Are you sure you want to delete this comment?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            
            if (confirm == true) {
              ref.read(deleteCommentProvider(fullId))().then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Comment deleted'),
                    duration: Duration(seconds: 2),
                  ),
                );
              });
            }
          },
          onHide: () {
            Navigator.pop(context);
            ref.read(toggleHideCommentProvider(fullId))();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Comment hidden'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          onTogglePin: () {
            Navigator.pop(context);
            ref.read(togglePinCommentProvider(fullId))().then((_) {
              final message = comment.pinned ? 'Comment unpinned' : 'Comment pinned';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  duration: const Duration(seconds: 2),
                ),
              );
            });
          },
          onCopy: () {
            Navigator.pop(context);
            _copyToClipboard(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fullId = '$memoId/${comment.id}';
    
    // Format the timestamp in a more readable way
    final DateTime commentDate = DateTime.fromMillisecondsSinceEpoch(
      comment.createTime,
    );
    final String formattedDate = _formatCommentDate(commentDate);
    
    return Dismissible(
      key: ValueKey('comment-${comment.id}'),
      background: Container(
        color: Colors.orange,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16.0),
        child: const Row(
          children: [
            SizedBox(width: 16),
            Icon(Icons.visibility_off, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Hide',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Text(
          'Delete',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Hide comment
          ref.read(toggleHideCommentProvider(fullId))();
          return false; // Don't remove from list
        } else if (direction == DismissDirection.endToStart) {
          // Confirm delete
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Confirm Delete'),
                content: const Text(
                  'Are you sure you want to delete this comment?',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              );
            },
          );
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          // Delete logic
          ref.read(deleteCommentProvider(fullId))().catchError((e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error deleting comment: $e'),
                backgroundColor: Colors.red,
              ),
            );
          });
        }
      },
      child: GestureDetector(
        onLongPress: () => _showContextMenu(context, ref),
        child: Card(
          elevation: isDarkMode ? 0 : 1,
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isDarkMode
                ? BorderSide(color: Colors.grey[850]!, width: 0.5)
                : BorderSide.none,
          ),
          color: isSelected
              ? (isDarkMode ? const Color(0xFF3A3A3A) : Colors.blue.shade50)
              : (isDarkMode ? const Color(0xFF262626) : null),
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (comment.pinned)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.push_pin,
                            size: 14,
                            color: isDarkMode
                                ? const Color(0xFF9CCC65)
                                : Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pinned',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode
                                  ? const Color(0xFF9CCC65)
                                  : Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Comment content with proper styling
                  Text(
                    comment.content,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[100] : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Timestamp with better formatting
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      
                      if (comment.state == CommentState.archived)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.archive,
                                size: 14,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Archived',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
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
  
  // Helper method to format comment date in a human-readable format
  String _formatCommentDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    // For very recent content (less than 1 hour)
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    }
    // For content from today (less than 24 hours)
    else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    }
    // Yesterday
    else if (difference.inDays == 1) {
      return 'Yesterday';
    }
    // Recent days
    else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    // Older content
    else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}

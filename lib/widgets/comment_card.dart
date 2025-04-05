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
            // Use the context passed to _showContextMenu, guarded by mounted check
            if (!mounted) return;
            _onArchive(context); // Pass context
          },
          onDelete: () async {
            Navigator.of(bottomSheetContext).pop();
            // Use the context passed to _showContextMenu, guarded by mounted check
            if (!mounted) return;
            _onDelete(context); // Pass context
          },
          onHide: () {
            Navigator.of(bottomSheetContext).pop();
            // Use the context passed to _showContextMenu, guarded by mounted check
            if (!mounted) return;
            _onHide(context); // Pass context
          },
          onTogglePin: () async {
            Navigator.of(bottomSheetContext).pop();
            // Use the context passed to _showContextMenu, guarded by mounted check
            if (!mounted) return;
            _onTogglePin(context); // Pass context
          },
          onCopy: () {
            Navigator.of(bottomSheetContext).pop();
            Clipboard.setData(ClipboardData(text: widget.comment.content)).then(
              (_) {
                if (!mounted) return; // Add mounted check
                ScaffoldMessenger.of(context).showSnackBar(
                  // Use context directly
                  const SnackBar(content: Text('Comment copied to clipboard')),
                );
              },
            );
          },
          onCopyLink: () {
            Navigator.of(bottomSheetContext).pop();
            final url =
                'flutter-memos://comment/${widget.memoId}/${widget.comment.id}'; // Use correct URL format with host
            Clipboard.setData(ClipboardData(text: url)).then((_) {
              if (!mounted) return; // Add mounted check
              ScaffoldMessenger.of(context).showSnackBar(
                // Use context directly
                const SnackBar(
                  content: Text('Comment link copied to clipboard'),
                ),
              );
            });
          },
          onConvertToMemo: () async {
            Navigator.of(bottomSheetContext).pop();
            // Use the context passed to _showContextMenu, guarded by mounted check
            if (!mounted) return;
            _onConvertToMemo(context); // Pass context
          },
          onEdit: () {
            Navigator.of(bottomSheetContext).pop(); // Close bottom sheet first
            // Use the context passed to _showContextMenu, guarded by mounted check
            if (!mounted) return;
            Navigator.pushNamed(
              // Use context directly
              context,
              '/edit-entity', // Use the new generic route name
              arguments: {
                'entityType': 'comment',
                'entityId': fullId, // Pass "memoId/commentId"
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
      if (!mounted) return; // Add mounted check

      // Correctly read the provider state after the await
      final commentsData = ref.read(memoCommentsProvider(widget.memoId)).asData;
      final currentCommentState = commentsData?.value.firstWhere(
        (c) => c.id == widget.comment.id,
        orElse: () => widget.comment, // Fallback to original state if not found
      );
      final isNowPinned = currentCommentState?.pinned ?? widget.comment.pinned;

      ScaffoldMessenger.of(context).showSnackBar(
        // Use passed context
        SnackBar(
          content: Text(
            isNowPinned ? 'Comment pinned' : 'Comment unpinned',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return; // Add mounted check
      ScaffoldMessenger.of(context).showSnackBar(
        // Use passed context
        SnackBar(content: Text('Error toggling pin: $e')),
      );
    }
  }

  Future<void> _onDelete(BuildContext context) async {
    // Use the context passed to the method
    final confirmed = await showDialog<bool>(
      context: context, // Use passed context
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

    // Check mounted *after* the dialog await
    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    final fullId = '${widget.memoId}/${widget.comment.id}';

    try {
      await ref.read(deleteCommentProvider(fullId))();

      // Check mounted *after* the delete await
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        // Use passed context
        const SnackBar(content: Text('Comment deleted')),
      );
      // No need to set _isDeleting = false, widget will be removed by provider invalidation
    } catch (e) {
      // Check mounted *after* the delete await (in catch block)
      if (!mounted) return;
      // If deletion failed, reset state and show error
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        // Use passed context
        SnackBar(content: Text('Error deleting comment: $e')),
      );
    }
}
  void _onArchive(BuildContext context) async {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    try {
      await ref.read(archiveCommentProvider(fullId))();
      if (!mounted) return; // Add mounted check
      ScaffoldMessenger.of(context).showSnackBar(
        // Use passed context
        const SnackBar(content: Text('Comment archived')),
      );
    } catch (e) {
      if (!mounted) return; // Add mounted check
      ScaffoldMessenger.of(context).showSnackBar(
        // Use passed context
        SnackBar(content: Text('Error archiving comment: $e')),
      );
    }
  }

  void _onConvertToMemo(BuildContext context) async {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    try {
      final convertFunction = ref.read(convertCommentToMemoProvider(fullId));
      await convertFunction();
      if (!mounted) return; // Add mounted check
      ScaffoldMessenger.of(context).showSnackBar(
        // Use passed context
        const SnackBar(content: Text('Comment converted to memo')),
      );
    } catch (e) {
      if (!mounted) return; // Add mounted check
      ScaffoldMessenger.of(context).showSnackBar(
        // Use passed context
        SnackBar(content: Text('Error converting to memo: $e')),
      );
    }
  }

  void _onHide(BuildContext context) {
    final fullId = '${widget.memoId}/${widget.comment.id}';
    ref.read(toggleHideCommentProvider(fullId))();
    // No await call here, so no mounted check needed before ScaffoldMessenger
    ScaffoldMessenger.of(context).showSnackBar(
      // Use passed context
      const SnackBar(content: Text('Comment hidden from view')),
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

    // Check if this comment should be highlighted (from deep link)
    final highlightedId = ref.watch(highlightedCommentIdProvider);
    final bool isHighlighted = highlightedId == widget.comment.id;

    // Reset highlight state after rendering if this is the highlighted comment
    if (isHighlighted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Check if still mounted and the ID still matches before resetting
        if (mounted &&
            ref.read(highlightedCommentIdProvider) == widget.comment.id) {
          if (kDebugMode) {
            print(
              '[CommentCard] Resetting highlight for comment ${widget.comment.id}',
            );
          }
          ref.read(highlightedCommentIdProvider.notifier).state = null;

          // Scroll to ensure the highlighted comment is visible
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            alignment: 0.5, // Center the comment in the viewport
          );
        }
      });
    }

    if (_isDeleting) {
      return const SizedBox.shrink();
    }

    // Get ApiService to construct image URLs
    final apiService = ref.watch(apiServiceProvider);
    final baseUrl = apiService.apiBaseUrl; // Get base URL

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
                  : (isHighlighted
                      ? Key('highlighted-comment-card-${widget.comment.id}')
                      : null),
          elevation: widget.isSelected ? 3 : (isHighlighted ? 4 : 1),
          margin: EdgeInsets.zero,
          color:
              widget.isSelected
                  ? (isDarkMode ? const Color(0xFF3A3A3A) : Colors.blue.shade50)
                  : (isHighlighted
                      ? (isDarkMode
                          ? Colors.teal.shade900
                          : Colors.teal.shade50)
                      : (isDarkMode ? const Color(0xFF222222) : Colors.white)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side:
                widget.isSelected
                    ? BorderSide(
                      color:
                          Theme.of(context)
                              .colorScheme
                              .primary, // Use primary color for selection border
                      width: 2, // Consistent width
                    )
                    : (isHighlighted
                        ? const BorderSide(color: Colors.teal, width: 2)
                        : BorderSide.none),
          ),
          child: InkWell(
            onLongPress: () => _showContextMenu(context),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Markdown Content
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
                        // textScaleFactor: 1.0, // Deprecated
                        textScaler: const TextScaler.linear(
                          1.0,
                        ), // Use textScaler instead
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

                  // Display Attached Resources (Images) - Accessing widget.comment.resources
                  // Ensure widget.comment.resources is accessed correctly
                  if (widget.comment.resources != null &&
                      widget.comment.resources!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: widget.comment.content.isNotEmpty ? 8.0 : 0.0,
                      ), // Add padding if text exists
                      child: Wrap(
                        // Use Wrap for multiple images
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children:
                            widget
                                .comment
                                .resources! // Access resources here
                                .where(
                                  (r) => r.type?.startsWith('image/') ?? false,
                                )
                                .map((resource) {
                                  // Construct the image URL
                                  final resourceName =
                                      resource.name?.split('/').last;
                                  final filename = resource.filename;
                                  if (baseUrl.isNotEmpty &&
                                      resourceName != null &&
                                      filename != null) {
                                    // Ensure filename is URL encoded
                                    final encodedFilename = Uri.encodeComponent(
                                      filename,
                                    );
                                    final imageUrl =
                                        '$baseUrl/file/$resourceName/$encodedFilename';

                                    if (kDebugMode) {
                                      print(
                                        '[CommentCard] Displaying image: $imageUrl',
                                      );
                                    }

                                    // Display the image with constraints
                                    return ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 200, // Limit image width
                                        maxHeight: 200, // Limit image height
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
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
                                              // Placeholder while loading
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
                                            if (kDebugMode) {
                                              print(
                                                '[CommentCard] Error loading image $imageUrl: $error',
                                              );
                                            }
                                            return Container(
                                              // Placeholder on error
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
                                    if (kDebugMode) {
                                      print(
                                        '[CommentCard] Could not construct image URL for resource: ${resource.name}',
                                      );
                                    }
                                    return const SizedBox.shrink(); // Don't display if URL can't be built
                                  }
                                })
                                .toList(),
                      ),
                    ),

                  // Separator if both content and resources exist
                  if (widget.comment.content.isNotEmpty &&
                      widget.comment.resources != null &&
                      widget.comment.resources!.isNotEmpty)
                    const SizedBox(height: 8),

                  // Date and Pin status row
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

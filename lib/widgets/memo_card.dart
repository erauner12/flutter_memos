import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemoCard extends ConsumerStatefulWidget {
  final String content;
  final bool pinned;
  final String? updatedAt;
  final bool showTimeStamps;
  final String? highlightTimestamp;
  final String? timestampType;
  final VoidCallback? onTap;
  final String id;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;
  final VoidCallback? onTogglePin;
  final bool isSelected; // Add isSelected property for keyboard navigation
  final VoidCallback? onBump; // Add onBump callback
  final VoidCallback? onMoveToServer; // Add onMoveToServer callback

  const MemoCard({
    super.key,
    required this.content,
    this.pinned = false,
    this.updatedAt,
    this.showTimeStamps = false,
    this.highlightTimestamp,
    this.timestampType,
    this.onTap,
    this.id = '',
    this.onArchive,
    this.onDelete,
    this.onHide,
    this.onTogglePin,
    this.isSelected = false, // Default to not selected
    this.onBump, // Add onBump to constructor
    this.onMoveToServer, // Add onMoveToServer to constructor
  });

  @override
  ConsumerState<MemoCard> createState() => MemoCardState();
}

// Renamed from _MemoCardState to make it public for GlobalKey access
class MemoCardState extends ConsumerState<MemoCard> {
  Offset tapPosition = Offset.zero;

  // Helper method to format date strings for display
  String formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
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
    } catch (e) {
      return dateTimeString;
    }
  }

  // Store position for context menu
  void storePosition(TapDownDetails details) {
    tapPosition = details.globalPosition;
  }

  // Made public to be called via GlobalKey
  void showContextMenu() {
    // Replace showModalBottomSheet with showCupertinoModalPopup
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: const Text('Memo Actions'), // Optional title
            actions: <CupertinoActionSheetAction>[
              if (widget.onMoveToServer != null)
                CupertinoActionSheetAction(
                  child: const Text('Move to Server...'),
                  onPressed: () {
                    Navigator.pop(context); // Close the sheet
                    widget.onMoveToServer!(); // Call the new callback
                  },
                ),
              if (widget.onTap != null)
                CupertinoActionSheetAction(
                  child: const Text('View'),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onTap!();
                  },
                ),
              CupertinoActionSheetAction(
                child: const Text('Edit'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/edit-entity',
                    arguments: {'entityType': 'memo', 'entityId': widget.id},
                  );
                },
              ),
              CupertinoActionSheetAction(
                child: Text(widget.pinned ? 'Unpin' : 'Pin'),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onTogglePin?.call();
                },
              ),
              if (widget.onBump != null)
                CupertinoActionSheetAction(
                  child: const Text('Bump'),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onBump!();
                  },
                ),
              CupertinoActionSheetAction(
                child: const Text('Copy Content'),
                onPressed: () async {
                  Navigator.pop(context);
                  await Clipboard.setData(ClipboardData(text: widget.content));
                  if (!mounted) return;
                  showCupertinoDialog(
                    context: context,
                    builder:
                        (context) => CupertinoAlertDialog(
                          title: const Text('Copied'),
                          content: const Text(
                            'Memo content copied to clipboard.',
                          ),
                          actions: [
                            CupertinoDialogAction(
                              isDefaultAction: true,
                              child: const Text('OK'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                  );
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Copy Link'),
                onPressed: () async {
                  Navigator.pop(context);
                  final url = 'flutter-memos://memo/${widget.id}';
                  await Clipboard.setData(ClipboardData(text: url));
                  if (!mounted) return;
                  showCupertinoDialog(
                    context: context,
                    builder:
                        (context) => CupertinoAlertDialog(
                          title: const Text('Copied'),
                          content: const Text('Memo link copied to clipboard.'),
                          actions: [
                            CupertinoDialogAction(
                              isDefaultAction: true,
                              child: const Text('OK'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                  );
                },
              ),
              if (widget.onHide != null)
                CupertinoActionSheetAction(
                  child: const Text('Hide'),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onHide!();
                  },
                ),
              if (widget.onArchive != null)
                CupertinoActionSheetAction(
                  child: const Text('Archive'),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onArchive!();
                  },
                ),
              if (widget.onDelete != null)
                CupertinoActionSheetAction(
                  isDestructiveAction: true,
                  child: const Text('Delete'),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onDelete!();
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

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final selectedStyle = (
      color: CupertinoColors.systemGrey.resolveFrom(context).withOpacity(0.3),
      border: BorderSide(
        color: CupertinoColors.systemGrey3.resolveFrom(context),
        width: 1,
      ),
    );

    final defaultStyle = (
      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
        context,
      ),
      border:
          isDarkMode
              ? BorderSide(
                color: CupertinoColors.systemGrey5.resolveFrom(context),
                width: 0.5,
              )
              : BorderSide.none,
    );

    Color cardBackgroundColor;
    BorderSide cardBorderStyle;

    if (widget.isSelected) {
      cardBackgroundColor = selectedStyle.color;
      cardBorderStyle = selectedStyle.border;
    } else {
      cardBackgroundColor = defaultStyle.color;
      cardBorderStyle = defaultStyle.border;
    }

    if (kDebugMode && widget.isSelected) {
      print('[MemoCard] Building selected memo card: ${widget.id}');
      if (widget.content.length < 100) {
        print('[MemoCard] Content: "${widget.content}"');
      } else {
        print(
          '[MemoCard] Content preview: "${widget.content.substring(0, 97)}..."',
        );
      }

      final urlRegex = RegExp(r'(https?://[^\s]+)|([\w-]+://[^\s]+)');
      final matches = urlRegex.allMatches(widget.content);
      if (matches.isNotEmpty) {
        print('[MemoCard] URLs in content:');
        for (final match in matches) {
          print('[MemoCard]   - ${match.group(0)}');
        }
      }
    }

    return Container(
      key: ValueKey(
        'memo-card-${widget.id}',
      ),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.fromBorderSide(cardBorderStyle),
        boxShadow:
            !isDarkMode && !widget.isSelected
                ? [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
                : null,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: kIsWeb ? showContextMenu : null,
        onTapDown: storePosition,
        // Explicitly ignore vertical drags on this detector to let the parent scroll view handle them.
        onVerticalDragStart: null,
        onVerticalDragUpdate: null,
        onVerticalDragEnd: null,
        behavior:
            HitTestBehavior.opaque, // Ensure taps are still captured correctly
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16.0,
            16.0,
            40.0,
            16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isSelected && kDebugMode)
                Builder(
                  builder: (context) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        print(
                          '[MemoCard] Rendering selected card: ${widget.id}',
                        );
                      }
                    });
                    return const SizedBox.shrink();
                  },
                ),
              MarkdownBody(
                data: widget.content,
                selectable: false, // Temporarily disable selection for testing
                shrinkWrap: true, // Ensure this is true to fit content height
                // physics: NeverScrollableScrollPhysics(), // REMOVED: MarkdownBody doesn't take physics
                styleSheet: MarkdownStyleSheet.fromCupertinoTheme(theme)
                    .copyWith(
                  p: theme.textTheme.textStyle.copyWith(
                    fontSize: 15,
                    height: 1.3,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                  code: theme.textTheme.textStyle.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    backgroundColor: CupertinoColors.systemGrey6.resolveFrom(
                      context,
                    ),
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6.resolveFrom(context),
                    border: Border(
                      left: BorderSide(
                        color: CupertinoColors.systemGrey.resolveFrom(context),
                        width: 4,
                      ),
                    ),
                  ),
                  blockquotePadding: const EdgeInsets.all(8),
                ),
                onTapLink: (text, href, title) {
                  if (href != null) {
                    UrlHelper.launchUrl(href, ref: ref, context: context);
                  }
                },
              ),
              const SizedBox(height: 8),
              if (widget.pinned)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.pin_fill,
                        size: 14,
                        color: CupertinoColors.systemGreen.resolveFrom(
                          context,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pinned',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.systemGreen.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.highlightTimestamp != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        widget.timestampType == 'Updated'
                            ? CupertinoIcons.refresh_thin
                            : CupertinoIcons.calendar,
                        size: 14,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.timestampType}: ${widget.highlightTimestamp}',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.showTimeStamps && widget.updatedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.refresh_thin,
                            size: 14,
                            color: CupertinoColors.tertiaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Updated: ${formatDateTime(widget.updatedAt!)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.tertiaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

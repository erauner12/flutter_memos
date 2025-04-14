import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NoteCard extends ConsumerStatefulWidget { // Renamed class
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
  final bool isSelected;
  final VoidCallback? onBump;
  final VoidCallback? onMoveToServer;

  const NoteCard({ // Renamed constructor
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
    this.isSelected = false,
    this.onBump,
    this.onMoveToServer,
  });

  @override
  ConsumerState<NoteCard> createState() => NoteCardState(); // Renamed class
}

class NoteCardState extends ConsumerState<NoteCard> { // Renamed class
  Offset tapPosition = Offset.zero;

  String formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return dateTimeString;
    }
  }

  void storePosition(TapDownDetails details) {
    tapPosition = details.globalPosition;
  }

  void showContextMenu() {
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: const Text('Note Actions'), // Updated text
            actions: <CupertinoActionSheetAction>[
              if (widget.onMoveToServer != null)
                CupertinoActionSheetAction(
                  child: const Text('Move to Server...'),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onMoveToServer!();
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
                    '/edit-entity', // Use generic route
                    arguments: {'entityType': 'note', 'entityId': widget.id}, // Specify type as 'note'
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
                  final BuildContext dialogContext = context;
                  Navigator.pop(dialogContext);
                  await Clipboard.setData(ClipboardData(text: widget.content));
                  if (mounted) {
                    showCupertinoDialog(
                      context: dialogContext,
                      builder:
                          (ctx) => CupertinoAlertDialog(
                            title: const Text('Copied'),
                            content: const Text(
                              'Note content copied to clipboard.', // Updated text
                            ),
                            actions: [
                              CupertinoDialogAction(
                                isDefaultAction: true,
                                child: const Text('OK'),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                    );
                  }
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Copy Link'),
                onPressed: () async {
                  final BuildContext dialogContext = context;
                  Navigator.pop(dialogContext);
                  // Use note in deep link structure
                  final url = 'flutter-memos://note/${widget.id}';
                  await Clipboard.setData(ClipboardData(text: url));
                  if (mounted) {
                    showCupertinoDialog(
                      context: dialogContext,
                      builder:
                          (ctx) => CupertinoAlertDialog(
                            title: const Text('Copied'),
                            content: const Text(
                              'Note link copied to clipboard.', // Updated text
                            ),
                            actions: [
                              CupertinoDialogAction(
                                isDefaultAction: true,
                                child: const Text('OK'),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                    );
                  }
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
      color: CupertinoColors.systemGrey
          .resolveFrom(context)
          .withAlpha((255 * 0.3).round()),
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
      print('[NoteCard] Building selected note card: ${widget.id}'); // Updated log identifier
      if (widget.content.length < 100) {
        print('[NoteCard] Content: "${widget.content}"'); // Updated log identifier
      } else {
        print(
          '[NoteCard] Content preview: "${widget.content.substring(0, 97)}..."', // Updated log identifier
        );
      }

      final urlRegex = RegExp(r'(https?://[^\s]+)|([\w-]+://[^\s]+)');
      final matches = urlRegex.allMatches(widget.content);
      if (matches.isNotEmpty) {
        print('[NoteCard] URLs in content:'); // Updated log identifier
        for (final match in matches) {
          print('[NoteCard]   - ${match.group(0)}'); // Updated log identifier
        }
      }
    }

    return Container(
      key: ValueKey(
        'note-card-${widget.id}', // Updated key prefix
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
        onVerticalDragStart: null,
        onVerticalDragUpdate: null,
        onVerticalDragEnd: null,
        behavior: HitTestBehavior.opaque,
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
                          '[NoteCard] Rendering selected card: ${widget.id}', // Updated log identifier
                        );
                      }
                    });
                    return const SizedBox.shrink();
                  },
                ),
              MarkdownBody(
                data: widget.content,
                selectable: false,
                shrinkWrap: true,
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
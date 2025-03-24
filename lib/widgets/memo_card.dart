import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/widgets/memo_context_menu.dart';

class MemoCard extends StatefulWidget {
  final String content;
  final bool pinned;
  final String? createdAt;
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

  const MemoCard({
    super.key,
    required this.content,
    this.pinned = false,
    this.createdAt,
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
  });

  @override
  State<MemoCard> createState() => _MemoCardState();
}

class _MemoCardState extends State<MemoCard> {
  Offset _tapPosition = Offset.zero;
  
  // Helper method to format date strings for display
  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
  
  // Store position for context menu
  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void _showContextMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 1.0,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return MemoContextMenu(
              memoId: widget.id,
              isPinned: widget.pinned,
              position: _tapPosition,
              parentContext: context,
              scrollController: scrollController,
              onClose: () => Navigator.pop(context),
              onView: widget.onTap,
              onEdit: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/edit-memo',
                  arguments: {'memoId': widget.id},
                );
              },
              onArchive: () {
                Navigator.pop(context);
                widget.onArchive?.call();
              },
              onDelete: () {
                Navigator.pop(context);
                widget.onDelete?.call();
              },
              onHide: () {
                Navigator.pop(context);
                widget.onHide?.call();
              },
              onPin: () {
                Navigator.pop(context);
                widget.onTogglePin?.call();
              },
              onCopy: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: widget.content)).then((
                  _,
                ) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Memo content copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                });
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDarkMode ? 0 : 1,
      margin: const EdgeInsets.only(bottom: 6),
      color: isDarkMode ? const Color(0xFF262626) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isDarkMode
            ? BorderSide(color: Colors.grey[850]!, width: 0.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: _showContextMenu,
        onDoubleTap: kIsWeb ? _showContextMenu : null,
        onTapDown: _storePosition,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            12.0,
            12.0,
            36.0,
            12.0,
          ), // Extra padding on right for archive button
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.content,
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isDarkMode
                          ? const Color(0xFFE0E0E0)
                          : const Color(0xFF333333),
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.pinned)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Pinned',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDarkMode
                              ? const Color(0xFF9CCC65)
                              : Colors.green[700],
                    ),
                  ),
                ),
              if (widget.highlightTimestamp != null)
                // Display the highlighted timestamp (based on sort mode)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        widget.timestampType == 'Updated'
                            ? Icons.update
                            : Icons.calendar_today,
                        size: 12,
                        color:
                            isDarkMode
                                ? const Color(0xFF9E9E9E)
                                : Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.timestampType}: ${widget.highlightTimestamp}',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isDarkMode
                                  ? const Color(0xFF9E9E9E)
                                  : Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Show detailed timestamps if needed
              if (widget.showTimeStamps && (widget.createdAt != null || widget.updatedAt != null))
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.createdAt != null)
                        Text(
                          'Created: ${_formatDateTime(widget.createdAt!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isDarkMode
                                    ? const Color(0xFF9E9E9E)
                                    : Colors.grey[600],
                          ),
                        ),
                      if (widget.updatedAt != null)
                        Text(
                          'Updated: ${_formatDateTime(widget.updatedAt!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isDarkMode
                                    ? const Color(0xFF9E9E9E)
                                    : Colors.grey[600],
                          ),
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/widgets/memo_context_menu.dart' as memo_menu;

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
  final bool isSelected; // Add isSelected property for keyboard navigation

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
    this.isSelected = false, // Default to not selected
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
      constraints: const BoxConstraints(
        // Limit maximum height to prevent overflow issues
        maxHeight: double.infinity,
      ),
      // Use useSafeArea to respect device safe areas
      useSafeArea: true,
      builder: (context) {
        // Get screen dimensions to adapt the sheet size
        final screenHeight = MediaQuery.of(context).size.height;

        // Dynamic initial size based on screen height
        // Smaller on phones, larger on tablets/desktop
        final initialSize = screenHeight < 600 ? 0.6 : 0.4;
        
        return DraggableScrollableSheet(
          initialChildSize: initialSize,
          minChildSize: 0.25,
          maxChildSize: 0.85, // Prevent taking the full screen
          expand: false,
          snap: true, // Enable snapping to common sizes
          snapSizes: const [0.4, 0.6, 0.85], // Common snap points
          builder: (BuildContext context, ScrollController scrollController) {
            return memo_menu.MemoContextMenu(
              memoId: widget.id,
              isPinned: widget.pinned,
              position: _tapPosition,
              parentContext: context,
              scrollController: scrollController,
              onClose: () => Navigator.pop(context),
              onView: widget.onTap,
              onEdit: () async {
                Navigator.pop(context);
                if (!mounted) return;
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
              onCopy: () async {
                Navigator.pop(context);
                await Clipboard.setData(ClipboardData(text: widget.content));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Memo content copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
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
    
    // Create a key if this card is selected to make it easier to find in tests
    final Key? cardKey =
        widget.isSelected ? Key('selected-memo-card-${widget.id}') : null;

    return Card(
      key: cardKey,
      elevation: isDarkMode ? 0 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      color:
          widget.isSelected
              ? (isDarkMode ? const Color(0xFF3A3A3A) : Colors.blue.shade50)
              : (isDarkMode ? const Color(0xFF262626) : null),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side:
            widget.isSelected
                ? BorderSide(
                  // Use a more visible color for testing purposes
                  color:
                      kDebugMode
                          ? Colors.red
                          : Theme.of(context).colorScheme.primary,
                  width: kDebugMode ? 3 : 2,
                )
                : (isDarkMode
                    ? BorderSide(color: Colors.grey[850]!, width: 0.5)
                    : BorderSide.none),
      ),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: _showContextMenu,
        onDoubleTap: kIsWeb ? _showContextMenu : null,
        onTapDown: _storePosition,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16.0,
            16.0,
            40.0,
            16.0,
          ), // Extra padding on right for archive button
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Log selection state in debug mode
              if (widget.isSelected && kDebugMode)
                Builder(
                  builder: (context) {
                    // Use post-frame callback to avoid layout phase
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      print('[MemoCard] Rendering selected card: ${widget.id}');
                    });
                    return const SizedBox.shrink();
                  },
                ),
              
              Text(
                widget.content,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.3,
                  color:
                      isDarkMode
                          ? const Color(0xFFE0E0E0)
                          : const Color(0xFF333333),
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Pinned indicator with improved styling
              if (widget.pinned)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.push_pin,
                        size: 14,
                        color:
                            isDarkMode
                                ? const Color(0xFF9CCC65)
                                : Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pinned',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              isDarkMode
                              ? const Color(0xFF9CCC65)
                              : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),

              // Primary timestamp display with better formatting
              if (widget.highlightTimestamp != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        widget.timestampType == 'Updated'
                            ? Icons.update
                            : Icons.calendar_today,
                        size: 14,
                        color:
                            isDarkMode
                                ? const Color(0xFF9E9E9E)
                                : Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.timestampType}: ${widget.highlightTimestamp}',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode
                                  ? const Color(0xFF9E9E9E)
                                  : Colors.grey[700],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

              // Show detailed timestamps with improved styling
              if (widget.showTimeStamps && (widget.createdAt != null || widget.updatedAt != null))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.create,
                                size: 14,
                                color:
                                    isDarkMode
                                        ? const Color(0xFF9E9E9E)
                                        : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Created: ${_formatDateTime(widget.createdAt!)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      isDarkMode
                                          ? const Color(0xFF9E9E9E)
                                          : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.updatedAt != null)
                        Row(
                          children: [
                            Icon(
                              Icons.update,
                              size: 14,
                              color:
                                  isDarkMode
                                      ? const Color(0xFF9E9E9E)
                                      : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Updated: ${_formatDateTime(widget.updatedAt!)}',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    isDarkMode
                                    ? const Color(0xFF9E9E9E)
                                    : Colors.grey[600],
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

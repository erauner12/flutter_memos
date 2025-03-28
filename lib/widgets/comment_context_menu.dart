import 'package:flutter/material.dart';

class CommentContextMenu extends StatelessWidget {
  final String commentId;
  final bool isPinned;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;
  final VoidCallback? onTogglePin;
  final VoidCallback? onCopy;
  final VoidCallback? onConvertToMemo;
  final VoidCallback? onClose;
  final ScrollController? scrollController;

  const CommentContextMenu({
    super.key,
    required this.commentId,
    required this.isPinned,
    this.onArchive,
    this.onDelete,
    this.onHide,
    this.onTogglePin,
    this.onCopy,
    this.onConvertToMemo,
    this.onClose,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate a maximum height for the menu content
    final maxContentHeight = screenHeight * 0.7;

    return Container(
      constraints: BoxConstraints(maxHeight: maxContentHeight),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle at the top
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title + close button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Comment Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content area
            Flexible(
              child: SingleChildScrollView(
                key: const Key('comment_context_menu_scroll'),
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Menu items in the scrollable area
                    _buildMenuItem(
                      icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      label: isPinned ? 'Unpin' : 'Pin',
                      onTap: onTogglePin,
                      isDarkMode: isDarkMode,
                    ),
                    _buildMenuItem(
                      icon: Icons.edit,
                      label: 'Edit',
                      onTap: () {
                        Navigator.of(context).pop();
                        // Navigate to edit screen
                        // This would need to be implemented
                      },
                      isDarkMode: isDarkMode,
                    ),
                    _buildMenuItem(
                      key: const Key('archive_comment_menu_item'),
                      icon: Icons.archive_outlined,
                      label: 'Archive',
                      onTap: onArchive,
                      isDarkMode: isDarkMode,
                    ),
                    _buildMenuItem(
                      icon: Icons.visibility_off,
                      label: 'Hide',
                      onTap: onHide,
                      isDarkMode: isDarkMode,
                    ),
                    _buildMenuItem(
                      icon: Icons.content_copy,
                      label: 'Copy Text',
                      onTap: onCopy,
                      isDarkMode: isDarkMode,
                    ),
                    _buildMenuItem(
                      key: const Key('convert_to_memo_menu_item'),
                      icon: Icons.note_add,
                      label: 'Convert to Memo',
                      onTap: onConvertToMemo,
                      isDarkMode: isDarkMode,
                    ),

                    Divider(
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),

                    // Delete option (in red)
                    _buildMenuItem(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      onTap: onDelete,
                      color: Colors.red,
                      isDarkMode: isDarkMode,
                    ),

                    // Add a little space at the bottom for better appearance
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    Key? key,
    required IconData icon,
    required String label,
    required bool isDarkMode,
    VoidCallback? onTap,
    Color? color,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: color ?? (isDarkMode ? Colors.white : Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: color ?? (isDarkMode ? Colors.white : Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// A custom context menu for memo actions
class MemoContextMenu extends StatelessWidget {
  final String memoId;
  final bool isPinned;
  final Offset
  position; // not used here, but can be used for context menus near tap
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;
  final VoidCallback? onPin;
  final VoidCallback? onCopy;
  final VoidCallback? onCopyLink; // Add this parameter
  final VoidCallback? onClose;
  final VoidCallback? onBump; // Add onBump callback
  final BuildContext parentContext;
  final ScrollController? scrollController;

  const MemoContextMenu({
    super.key,
    required this.memoId,
    required this.isPinned,
    required this.position,
    required this.parentContext,
    this.scrollController,
    this.onView,
    this.onEdit,
    this.onArchive,
    this.onDelete,
    this.onHide,
    this.onPin,
    this.onCopy,
    this.onCopyLink, // Include in constructor
    this.onClose,
    this.onBump, // Add onBump to constructor
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate a maximum height for the menu content
    // This ensures it won't overflow on smaller screens
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
                    'Memo Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
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
                key: const Key('memo_context_menu_scroll'),
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Menu items in the scrollable area
                    _buildMenuItem(
                      icon: Icons.visibility,
                      label: 'View Memo',
                      onTap: onView,
                      isDarkMode: isDarkMode,
                    ),
                    _buildMenuItem(
                      icon: Icons.edit,
                      label: 'Edit',
                      onTap: onEdit,
                      isDarkMode: isDarkMode,
                    ),
                    _buildMenuItem(
                      icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      label: isPinned ? 'Unpin' : 'Pin',
                      onTap: onPin,
                      isDarkMode: isDarkMode,
                    ),
                    _buildMenuItem(
                      icon: Icons.arrow_upward, // Add Bump item
                      label: 'Bump',
                      onTap: onBump,
                      isDarkMode: isDarkMode,
                    ),
                    _buildMenuItem(
                      key: const Key('archive_menu_item'), // Key for testing
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
                      icon: Icons.link,
                      label: 'Copy Link',
                      onTap: onCopyLink,
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

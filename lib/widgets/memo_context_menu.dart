import 'package:flutter/material.dart';

/// A custom context menu for memo actions
class MemoContextMenu extends StatelessWidget {
  final String memoId;
  final bool isPinned;
  final Offset
  position; // Kept for API compatibility but not used in bottom sheet mode
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;
  final VoidCallback? onPin;
  final VoidCallback? onCopy;
  final VoidCallback? onClose;
  final BuildContext parentContext;

  const MemoContextMenu({
    super.key,
    required this.memoId,
    required this.isPinned,
    required this.position,
    required this.parentContext,
    this.onView,
    this.onEdit,
    this.onArchive,
    this.onDelete,
    this.onHide,
    this.onPin,
    this.onCopy,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Bottom sheet style context menu
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        // Use LayoutBuilder to get constraints and make the menu scrollable when needed
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle at the top
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Title
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
                          ),
                        ],
                      ),
                    ),

                    // Main options
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool isDarkMode,
    VoidCallback? onTap,
    Color? color,
  }) {
    return InkWell(
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

import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/workbench_instance.dart';

class WorkbenchInstanceTile extends StatelessWidget {
  final WorkbenchInstance instance;
  final bool isSelected; // Optional: To highlight the selected instance
  final VoidCallback onTap;
  final VoidCallback? onLongPress; // Optional: For rename/delete actions

  const WorkbenchInstanceTile({
    super.key,
    required this.instance,
    required this.onTap,
    this.isSelected = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque, // Ensure the whole area is tappable
      child: Container(
        color: theme.barBackgroundColor, // Or Colors.transparent if using grouped list background
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              instance.isSystemDefault
                  ? CupertinoIcons.square_grid_2x2_fill // Example icon for default
                  : CupertinoIcons.square_list, // Example icon for others
              color: isSelected
                  ? theme.primaryColor
                  : CupertinoColors.secondaryLabel.resolveFrom(context),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                instance.name,
                style: theme.textTheme.textStyle.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_forward,
              color: CupertinoColors.tertiaryLabel,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

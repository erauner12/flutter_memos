import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/focus_instance.dart'; // Updated import

class FocusInstanceTile extends StatelessWidget {
  final FocusInstance instance;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress; // Make long press optional

  const FocusInstanceTile({
    super.key,
    required this.instance,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle;
    CupertinoTheme.of(context)
        .textTheme
        .textStyle
        .copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context), fontSize: 13);

    return GestureDetector( // Wrap with GestureDetector for long press
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container( // Use Container for padding and background
        color: CupertinoTheme.of(context).barBackgroundColor, // Match list background
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              instance.isSystemDefault ? CupertinoIcons.pin_fill : CupertinoIcons.square_grid_2x2, // Example icons
              color: instance.isSystemDefault ? CupertinoColors.systemGrey : textStyle.color,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    instance.name,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Optionally add more info like item count or creation date
                  // Text(
                  //   'Created: ${DateFormat.yMd().format(instance.createdAt)}', // Example formatting
                  //   style: secondaryTextStyle,
                  // ),
                ],
              ),
            ),
             if (onTap != null) // Show chevron only if tappable
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: CupertinoListTileChevron(),
              ),
          ],
        ),
      ),
    );
  }
}

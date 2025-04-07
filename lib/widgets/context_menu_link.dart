import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/services.dart';

/// A widget that displays text as a link with a context menu on long press
class ContextMenuLink extends StatelessWidget {
  final String text;
  final String url;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const ContextMenuLink({
    super.key,
    required this.text,
    required this.url,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        _showContextMenu(context);
      },
      child: Text(
        text,
        style: TextStyle(
          color: CupertinoColors.link.resolveFrom(
            context,
          ), // Use Cupertino link color
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    // Replace showModalBottomSheet with showCupertinoModalPopup
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        // Use CupertinoActionSheet
        return CupertinoActionSheet(
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              // leading icon not directly supported, rely on text
              child: const Text('Open Link'),
              onPressed: () {
                Navigator.pop(context);
                onTap();
              },
            ),
            CupertinoActionSheetAction(
              // leading icon not directly supported, rely on text
              child: const Text('Copy Link'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                Navigator.pop(context);
                onCopy(); // Assume onCopy might show confirmation (e.g., CupertinoAlertDialog)
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
        );
      },
    );
  }
}

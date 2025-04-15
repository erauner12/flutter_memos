import 'package:flutter/cupertino.dart';
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
          color: CupertinoColors.link.resolveFrom(context),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      useRootNavigator: true, // Use root navigator to avoid empty stack issues
      builder: (BuildContext popupContext) {
        return CupertinoActionSheet(
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              child: const Text('Open Link'),
              onPressed: () {
                Navigator.of(
                  popupContext,
                ).pop(); // Use the popup context explicitly
                onTap();
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Copy Link'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                Navigator.of(
                  popupContext,
                ).pop(); // Use the popup context explicitly
                onCopy();
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(
                popupContext,
              ).pop(); // Use the popup context explicitly
            },
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }
}

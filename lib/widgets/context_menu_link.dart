import 'package:flutter/material.dart';
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
        style: const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Open Link'),
                onTap: () {
                  Navigator.pop(context);
                  onTap();
                },
              ),
              ListTile(
                leading: const Icon(Icons.content_copy),
                title: const Text('Copy Link'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: url));
                  Navigator.pop(context);
                  onCopy();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

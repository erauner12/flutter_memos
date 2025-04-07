import 'package:flutter/cupertino.dart';

/// Shows a Cupertino-style alert dialog
Future<T?> showCupertinoAlert<T>({
  required BuildContext context,
  required String title,
  required String message,
  String cancelButtonText = 'Cancel',
  String? confirmButtonText,
  VoidCallback? onConfirm,
}) {
  return showCupertinoDialog<T>(
    context: context,
    barrierDismissible: false, // Matches iOS behavior
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelButtonText),
        ),
        if (confirmButtonText != null)
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop(true as T);
              onConfirm?.call();
            },
            child: Text(confirmButtonText),
          ),
      ],
    ),
  );
}

/// Shows a Cupertino-style action sheet
Future<T?> showCupertinoActionSheet<T>({
  required BuildContext context,
  String? title,
  String? message,
  required List<CupertinoActionSheetAction> actions,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: title != null ? Text(title) : null,
      message: message != null ? Text(message) : null,
      actions: actions,
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
    ),
  );
}

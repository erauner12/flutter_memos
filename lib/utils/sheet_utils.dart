import 'package:flutter/cupertino.dart';

/// Shows a Cupertino-style modal bottom sheet
Future<T?> showCupertinoModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  double initialChildSize = 0.5,
  double minChildSize = 0.25,
  double maxChildSize = 0.9,
  bool expand = false,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    barrierColor: CupertinoColors.black.withOpacity(0.4),
    builder: (context) => CupertinoPopupSurface(
      isSurfacePainted: true,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * maxChildSize,
        ),
        padding: const EdgeInsets.only(top: 12.0),
        decoration: BoxDecoration(
          color: backgroundColor ?? CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12.0),
            topRight: Radius.circular(12.0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator at top (iOS style)
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4.resolveFrom(context),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 8),
            // Content
            Flexible(
              child: builder(context),
            ),
          ],
        ),
      ),
    ),
  );
}

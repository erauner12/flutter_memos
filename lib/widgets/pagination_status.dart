import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaginationStatus extends ConsumerWidget {
  const PaginationStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosState = ref.watch(memosNotifierProvider);
    final theme = CupertinoTheme.of(context); // Get Cupertino theme

    // Don't show anything if there's nothing to show
    if (!memosState.isLoading &&
        !memosState.isLoadingMore &&
        memosState.error == null) {
      return const SizedBox.shrink();
    }

    // Use Cupertino dynamic colors
    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final Color errorColor = CupertinoColors.systemRed.resolveFrom(context);
    final Color primaryColor = theme.primaryColor;
    // Define a bodySmall style based on Cupertino theme
    final TextStyle bodySmallStyle = theme.textTheme.textStyle.copyWith(
      fontSize: 12,
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: backgroundColor, // Use Cupertino background color
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show error message if there's an error
          if (memosState.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Error: ${memosState.error}',
                style: TextStyle(
                  color: errorColor,
                ), // Use Cupertino error color
              ),
            ),

          // Show loading status
          if (memosState.isLoading || memosState.isLoadingMore)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  // Replace CircularProgressIndicator with CupertinoActivityIndicator
                  child: CupertinoActivityIndicator(
                    radius: 8, // Adjust radius as needed
                    color: primaryColor, // Use Cupertino primary color
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  memosState.isLoading
                      ? 'Loading memos...'
                      : 'Loading more memos...',
                  style: bodySmallStyle, // Use Cupertino text style
                ),
              ],
            ),

          // Show total count when available
          if (memosState.memos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Loaded ${memosState.totalLoaded} memos${memosState.hasReachedEnd ? " (end of list)" : ""}',
                style: bodySmallStyle, // Use Cupertino text style
              ),
            ),
        ],
      ),
    );
  }
}

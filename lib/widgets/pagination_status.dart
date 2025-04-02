import 'package:flutter/material.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaginationStatus extends ConsumerWidget {
  const PaginationStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosState = ref.watch(memosNotifierProvider);
    
    // Don't show anything if there's nothing to show
    if (!memosState.isLoading &&
        !memosState.isLoadingMore &&
        memosState.error == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show error message if there's an error
          if (memosState.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Error: ${memosState.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  memosState.isLoading
                      ? 'Loading memos...'
                      : 'Loading more memos...',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          
          // Show total count when available
          if (memosState.memos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Loaded ${memosState.totalLoaded} memos${memosState.hasReachedEnd ? " (end of list)" : ""}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

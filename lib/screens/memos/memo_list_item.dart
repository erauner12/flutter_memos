import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/utils/memo_utils.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemoListItem extends ConsumerWidget {
  final Memo memo;
  final int index; // Add index for selection tracking

  const MemoListItem({super.key, required this.memo, required this.index});

  void _toggleHideMemo(BuildContext context, WidgetRef ref) {
    final hiddenMemoIds = ref.read(hiddenMemoIdsProvider);
    if (hiddenMemoIds.contains(memo.id)) {
      // Unhide memo
      ref
          .read(hiddenMemoIdsProvider.notifier)
          .update((state) => state..remove(memo.id));
    } else {
      // Hide memo
      ref
          .read(hiddenMemoIdsProvider.notifier)
          .update((state) => state..add(memo.id));

      // Show a confirmation that the memo was hidden
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memo hidden'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Force UI refresh to update visibility
    ref.read(memosNotifierProvider.notifier).refresh();
  }

  void _navigateToMemoDetail(BuildContext context, WidgetRef ref) {
    Navigator.pushNamed(
      context,
      '/memo-detail',
      arguments: {'memoId': memo.id},
    ).then((_) {
      // Refresh memos after returning from detail screen
      ref.read(memosNotifierProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Removed sortMode watch, always using updateTime now.
    final isSelected = ref.watch(selectedMemoIndexProvider) == index;

    if (isSelected && kDebugMode) {
      print('[MemoListItem] Memo at index $index is selected');
    }

    return Dismissible(
      key: ValueKey('dismissible-${memo.id}'),
      background: Container(
        color: Colors.orange,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16.0),
        child: const Row(
          children: [
            SizedBox(width: 16),
            Icon(Icons.visibility_off, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Hide',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Text(
          'Delete',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          // First, immediately add the memo to hidden IDs to remove it from UI
          ref
              .read(hiddenMemoIdsProvider.notifier)
              .update((state) => state..add(memo.id));

          // Then trigger the API delete operation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Create a local reference to the providers we need to call
            // outside the async callback
            final deleteMemo = ref.read(deleteMemoProvider(memo.id));
            final String memoId = memo.id; // Capture memo ID

            // Execute delete operation
            deleteMemo()
                .then((_) {
                  // Use a post-frame callback for UI updates to avoid build phase issues
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // These operations are safe even if the widget is no longer mounted
                    ref.read(memosNotifierProvider.notifier).refresh();
                    ref
                        .read(hiddenMemoIdsProvider.notifier)
                        .update((state) => state..remove(memoId));
                  });
                })
                .catchError((e) {
                  // If delete fails, handle errors and clean up
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(memosNotifierProvider.notifier).refresh();
                    ref
                        .read(hiddenMemoIdsProvider.notifier)
                        .update((state) => state..remove(memoId));
                  });
                });
          });
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Hide memo
          _toggleHideMemo(context, ref);
          return false; // Don't remove from list
        } else if (direction == DismissDirection.endToStart) {
          // Delete memo
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Confirm Delete'),
                content: const Text(
                  'Are you sure you want to delete this memo?',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              );
            },
          );
        }
        return false;
      },
      child: Stack(
        children: [
          MemoCard(
            id: memo.id,
            content: memo.content,
            pinned: memo.pinned,
            // createdAt: memo.createTime, // Removed createTime display
            updatedAt: memo.updateTime,
            showTimeStamps: true,
            isSelected:
                ref.watch(selectedMemoIndexProvider) ==
                index, // Add selected state
            // Always highlight update time now
            highlightTimestamp: MemoUtils.formatTimestamp(memo.updateTime),
            timestampType: 'Updated', // Always 'Updated'
            onTap: () => _navigateToMemoDetail(context, ref),
            onArchive: () => ref.read(archiveMemoProvider(memo.id))(),
            onDelete: () async {
              // Show confirmation dialog first
              final confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: const Text(
                      'Are you sure you want to delete this memo?',
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true && context.mounted) {
                try {
                  if (kDebugMode) {
                    print(
                      '[MemoListItem] Calling deleteMemoProvider for memo ID: ${memo.id}',
                    );
                  }

                  // First, immediately add the memo to hidden IDs to remove it from UI
                  ref
                      .read(hiddenMemoIdsProvider.notifier)
                      .update((state) => state..add(memo.id));

                  // Then perform the actual delete operation
                  await ref.read(deleteMemoProvider(memo.id))();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Memo deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // If deletion fails, show error and remove from hidden IDs
                  ref
                      .read(hiddenMemoIdsProvider.notifier)
                      .update((state) => state..remove(memo.id));

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting memo: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }

                  if (kDebugMode) {
                    print('[MemoListItem] Error deleting memo: $e');
                  }
                }
              }
            },
            onHide: () => _toggleHideMemo(context, ref),
            onTogglePin: () => ref.read(togglePinMemoProvider(memo.id))(),
            onBump: () async {
              // Add onBump callback implementation
              try {
                await ref.read(bumpMemoProvider(memo.id))();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Memo bumped!'),
                      duration: Duration(seconds: 1),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to bump memo: ${e.toString().substring(0, 50)}...',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          // Archive button positioned at top-right corner
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.archive_outlined, size: 20),
              tooltip: 'Archive',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
              color: Colors.grey[600],
              onPressed: () {
                // Use the archive memo provider
                // Store context to use after async operation
                final currentContext = context;
                ref.read(archiveMemoProvider(memo.id))().then((_) {
                  // Use the stored context instead of checking mounted
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Memo archived successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/utils/memo_utils.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemoListItem extends ConsumerWidget {
  final Memo memo;
  
  const MemoListItem({
    super.key,
    required this.memo,
  });

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
    ref.invalidate(memosProvider);
  }

  void _navigateToMemoDetail(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/memo-detail',
      arguments: {'memoId': memo.id},
    ).then((_) {
      // Refresh memos after returning from detail screen
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortMode = ref.watch(memoSortModeProvider);
    
    return Dismissible(
      key: Key(memo.id),
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
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          ref.read(deleteMemoProvider(memo.id))();
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
            createdAt: memo.createTime,
            updatedAt: memo.updateTime,
            showTimeStamps: true,
            // Display relevant timestamp based on sort mode
            highlightTimestamp:
                sortMode == MemoSortMode.byUpdateTime
                    ? MemoUtils.formatTimestamp(memo.updateTime)
                    : MemoUtils.formatTimestamp(memo.createTime),
            timestampType:
                sortMode == MemoSortMode.byUpdateTime
                    ? 'Updated'
                    : 'Created',
            onTap: () => _navigateToMemoDetail(context),
            onArchive: () => ref.read(archiveMemoProvider(memo.id))(),
            onDelete: () async {
              final confirm = await showDialog<bool>(
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

              if (confirm == true) {
                ref.read(deleteMemoProvider(memo.id))();
              }
            },
            onHide: () => _toggleHideMemo(context, ref),
            onTogglePin: () => ref.read(togglePinMemoProvider(memo.id))(),
          ),
          // Archive button positioned at top-right corner
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(
                Icons.archive_outlined,
                size: 20,
              ),
              tooltip: 'Archive',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
              color: Colors.grey[600],
              onPressed: () {
                // Use the archive memo provider
                ref.read(archiveMemoProvider(memo.id))().then((
                  _,
                ) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Memo archived successfully',
                      ),
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

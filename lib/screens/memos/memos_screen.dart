import 'package:flutter/material.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memos_body.dart';
import 'memos_filter_bar.dart';

class MemosScreen extends ConsumerStatefulWidget {
  const MemosScreen({super.key});

  @override
  ConsumerState<MemosScreen> createState() => _MemosScreenState();
}

class _MemosScreenState extends ConsumerState<MemosScreen> {
  @override
  void initState() {
    super.initState();
    // Load saved filter preferences
    ref.read(loadFilterPreferencesProvider);
  }

  void _toggleSortMode() {
    final sortMode = ref.read(memoSortModeProvider);
    ref.read(memoSortModeProvider.notifier).state =
        sortMode == MemoSortMode.byUpdateTime
            ? MemoSortMode.byCreateTime
            : MemoSortMode.byUpdateTime;
    
    // Show a snackbar to indicate the sort mode changed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sorting by ${ref.read(memoSortModeProvider) == MemoSortMode.byUpdateTime ? 'update time' : 'creation time'} (newest first)',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memos'),
        actions: [
          // Sort toggle button with more descriptive text
          Consumer(
            builder: (context, ref, child) {
              final sortMode = ref.watch(memoSortModeProvider);
              return TextButton.icon(
                icon: Icon(
                  sortMode == MemoSortMode.byUpdateTime
                      ? Icons.update
                      : Icons.calendar_today,
                  size: 20,
                ),
                label: Text(
                  sortMode == MemoSortMode.byUpdateTime
                      ? 'Sort by: Updated'
                      : 'Sort by: Created',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Colors.grey[100],
                ),
                onPressed: _toggleSortMode,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const Column(
        children: [
          // Filter area
          MemosFilterBar(),
          // Main content area
          Expanded(child: MemosBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/new-memo').then((_) {
            // Refresh memos after returning from creating a new memo
            ref.invalidate(memosProvider);
          });
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memo_list_item.dart';
import 'memos_empty_state.dart';

class MemosBody extends ConsumerWidget {
  const MemosBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the providers for data changes
    final memosAsync = ref.watch(visibleMemosProvider);
    
    return memosAsync.when(
      data: (memos) {
        // Get hidden memo IDs
        final hiddenIds = ref.watch(hiddenMemoIdsProvider);

        // Filter out hidden memos
        final visibleMemos =
            memos.where((memo) => !hiddenIds.contains(memo.id)).toList();

        if (visibleMemos.isEmpty) {
          return const MemosEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Invalidate the memosProvider to force refresh
            ref.invalidate(memosProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: visibleMemos.length,
            itemBuilder: (context, index) {
              final memo = visibleMemos[index];
              return MemoListItem(memo: memo);
            },
          ),
        );
      },
      loading: () {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Error loading memos: ${error.toString().substring(0, Math.min(error.toString().length, 100))}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}

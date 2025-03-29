import 'package:flutter/material.dart';
import 'package:flutter_memos/providers/memo_detail_provider.dart';
import 'package:flutter_memos/providers/memo_providers.dart' as memo_providers;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_memo_form.dart';
import 'edit_memo_providers.dart';

class EditMemoScreen extends ConsumerWidget {
  final String memoId;

  const EditMemoScreen({
    super.key,
    required this.memoId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoAsync = ref.watch(editMemoProvider(memoId));
    
    return PopScope(
      // When popping the screen, ensure we refresh the memo list
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Ensure the memo list is refreshed when returning
          ref.invalidate(memo_providers.memosProvider);

          // Also ensure any cached memo details are refreshed
          if (ref.exists(memoDetailCacheProvider)) {
            ref.invalidate(memoDetailProvider(memoId));
          }

          // Ensure the memo is not hidden
          ref
              .read(memo_providers.hiddenMemoIdsProvider.notifier)
              .update(
                (state) =>
                    state.contains(memoId) ? (state..remove(memoId)) : state,
              );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Memo')),
        body: memoAsync.when(
          data: (memo) => EditMemoForm(memo: memo, memoId: memoId),
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, _) => Center(
                child: Text(
                  'Error: $error',
                  style: const TextStyle(color: Colors.red),
                ),
          ),
        ),
      ),
    );
  }
}

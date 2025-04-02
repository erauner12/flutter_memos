import 'package:flutter/material.dart';
import 'package:flutter_memos/providers/memo_detail_provider.dart'
    hide memoCommentsProvider; // Hide this to avoid conflict
import 'package:flutter_memos/providers/memo_providers.dart' as memo_providers;
import 'package:flutter_memos/screens/memo_detail/memo_detail_providers.dart'
    show memoCommentsProvider; // Use this one explicitly
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_memo_form.dart';
import 'edit_memo_providers.dart';
// Removed duplicate import 'edit_memo_providers.dart';

class EditMemoScreen extends ConsumerWidget {
  final String entityId; // Renamed from memoId
  final String entityType; // 'memo' or 'comment'

  const EditMemoScreen({
    super.key,
    required this.entityId,
    required this.entityType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the generalized provider, passing parameters as EntityProviderParams
    final entityAsync = ref.watch(
      editEntityProvider(EntityProviderParams(id: entityId, type: entityType)),
    );

    return PopScope(
      // When popping the screen, ensure we refresh the relevant lists
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Always refresh the main memos list (parent memo might have been bumped)
          ref.read(memo_providers.memosNotifierProvider.notifier).refresh();

          if (entityType == 'comment') {
            // If a comment was edited, refresh the comments list for the parent memo
            final parts = entityId.split('/');
            if (parts.isNotEmpty) {
              final parentMemoId = parts[0];
              // Ensure this uses the imported provider
              ref.invalidate(memoCommentsProvider(parentMemoId));
            }
          } else {
            // entityType == 'memo'
            // If a memo was edited, refresh its detail view and cache
            if (ref.exists(memo_providers.memoDetailCacheProvider)) {
              ref.invalidate(memoDetailProvider(entityId));
            }
            // Ensure the memo is not hidden (existing logic)
            ref
                .read(memo_providers.hiddenMemoIdsProvider.notifier)
                .update(
                  (state) =>
                      state.contains(entityId)
                          ? (state..remove(entityId))
                          : state,
                );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            entityType == 'comment' ? 'Edit Comment' : 'Edit Memo',
          ), // Conditional title
        ),
        body: entityAsync.when(
          data:
              (entity) => EditMemoForm(
                entity: entity, // Pass the dynamic entity
                entityId: entityId,
                entityType: entityType,
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, _) => Center(
                child: Text(
                  'Error loading ${entityType == 'comment' ? 'comment' : 'memo'}: $error',
                  style: const TextStyle(color: Colors.red),
                ),
          ),
        ),
      ),
    );
  }
}

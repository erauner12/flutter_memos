import 'package:flutter/material.dart';
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memo_comments.dart';
import 'memo_content.dart';
import 'memo_detail_providers.dart';

class MemoDetailScreen extends ConsumerStatefulWidget {
  final String memoId;

  const MemoDetailScreen({
    super.key,
    required this.memoId,
  });

  @override
  ConsumerState<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends ConsumerState<MemoDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memo Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/edit-memo',
                arguments: {'memoId': widget.memoId},
              ).then((_) {
                // Refresh data when returning from edit screen
                ref.invalidate(memoDetailProvider(widget.memoId));
                ref.invalidate(memoCommentsProvider(widget.memoId));
              });
            },
          ),
        ],
      ),
      // Use a Column for vertical layout - this ensures proper bottom alignment
      body: Column(
        children: [
          // Content area (expandable)
          Expanded(child: _buildBody()),
          // Fixed bottom area for CaptureUtility
          CaptureUtility(
            mode: CaptureMode.addComment,
            memoId: widget.memoId,
            hintText: 'Add a comment...',
            buttonText: 'Add Comment',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final memoAsync = ref.watch(memoDetailProvider(widget.memoId));

    return memoAsync.when(
      data: (memo) {
        return SingleChildScrollView(
          child: Column(
            children: [
              // Memo content section
              MemoContent(memo: memo, memoId: widget.memoId),

              // Divider between content and comments
              const Divider(),

              // Comments section
              MemoComments(memoId: widget.memoId),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: Colors.red),
            ),
      ),
    );
  }
}

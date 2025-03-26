import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_memos/widgets/capture_utility.dart';

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
      body: Stack(
        children: [
          _buildBody(),
          // Position the CaptureUtility at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Center(
                child: CaptureUtility(
                  mode: CaptureMode.addComment,
                  memoId: widget.memoId,
                  hintText: 'Add a comment...',
                  buttonText: 'Add Comment',
                ),
              ),
            ),
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
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 100,
            ), // Increased padding for floating CaptureUtility
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
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'comment_form.dart';
import 'memo_detail_providers.dart';

class MemoComments extends ConsumerWidget {
  final String memoId;

  const MemoComments({
    super.key,
    required this.memoId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(memoCommentsProvider(memoId));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comments header
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Comments',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          
          // Comments list or placeholder
          commentsAsync.when(
            data: (comments) {
              if (comments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'No comments yet.',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                );
              }
              
              return Column(
                children: comments.reversed.map(
                  (comment) => _buildCommentCard(comment),
                ).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Error loading comments: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
          
          // Comment form removed as we're now using CaptureUtility
        ],
      ),
    );
  }
  
  Widget _buildCommentCard(Comment comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment.content),
            const SizedBox(height: 4),
            Text(
              DateTime.fromMillisecondsSinceEpoch(
                comment.createTime,
              ).toString(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

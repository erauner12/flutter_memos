import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memo_detail_providers.dart';

class MemoContent extends ConsumerStatefulWidget {
  final Memo memo;
  final String memoId;

  const MemoContent({
    super.key,
    required this.memo,
    required this.memoId,
  });

  @override
  ConsumerState<MemoContent> createState() => _MemoContentState();
}

class _MemoContentState extends ConsumerState<MemoContent> {
  void _copyToClipboard(Memo memo, List<Comment> comments, BuildContext context) {
    // Build clipboard content
    String clipboardContent = '${memo.content}\n\n';

    // Add comments in chronological order
    if (comments.isNotEmpty) {
      clipboardContent += 'Comments:\n';
      for (int i = 0; i < comments.length; i++) {
        final comment = comments[i];
        final timestamp = DateTime.fromMillisecondsSinceEpoch(
                comment.createTime,
              ).toString();
        clipboardContent += '${i + 1}. ${comment.content} ($timestamp)\n';
      }
    }

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: clipboardContent)).then((_) {
      if (!mounted) return; // Check if widget is still mounted
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memo content and comments copied to clipboard'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(memoCommentsProvider(widget.memoId));
    
    return commentsAsync.when(
      data: (comments) {
        return Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.memo.content,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        () => _copyToClipboard(widget.memo, comments, context),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy All'),
                  ),
                ),
                
                // Memo metadata
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    '${widget.memo.state == MemoState.archived ? "Archived" : "Active"} | Visibility: ${widget.memo.visibility}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                
                if (widget.memo.pinned)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Pinned',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        margin: EdgeInsets.all(16.0),
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Loading comments...',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => Card(
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                    widget.memo.content,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Error loading comments',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

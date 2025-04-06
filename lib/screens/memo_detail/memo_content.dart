import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/utils/url_helper.dart';
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
  
    // Debug logging for memo content
    if (kDebugMode) {
      print('[MemoContent] Rendering memo ${widget.memo.id}');
      print(
        '[MemoContent] Content length: ${widget.memo.content.length} chars',
      );
      if (widget.memo.content.length < 200) {
        print('[MemoContent] Content preview: "${widget.memo.content}"');
      } else {
        print(
          '[MemoContent] Content preview: "${widget.memo.content.substring(0, 197)}..."',
        );
      }

      // Detect URLs in content
      final urlRegex = RegExp(r'(https?://[^\s]+)|([\w-]+://[^\s]+)');
      final matches = urlRegex.allMatches(widget.memo.content);
      if (matches.isNotEmpty) {
        print('[MemoContent] URLs found in content:');
        for (final match in matches) {
          print('[MemoContent]   - ${match.group(0)}');
        }
      }
    }
  
    return commentsAsync.when(
      data: (comments) {
        return Card(
          key: const Key('memo-content'), // Add key for test findability
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(
                  data: widget.memo.content,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 18),
                    a: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    textScaleFactor: 1.0,
                  ),
                  onTapLink: (text, href, title) async {
                    if (kDebugMode) {
                      print(
                        '[MemoContent] Link tapped: text="$text", href="$href", title="$title"',
                      );
                    }
                    if (href != null) {
                      // Pass the ref to UrlHelper.launchUrl
                      final success = await UrlHelper.launchUrl(
                        href,
                        ref: ref, // Pass the ref
                        context: context,
                      );
                      // Keep existing success/failure logging/handling if desired,
                      // though UrlHelper now also shows a snackbar on failure
                      if (!success && context.mounted) {
                        // TODO: Handle failure case
                        // If launch failed, show a more detailed message with copy option
                        // This part is now handled by UrlHelper, but kept here for reference
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(
                        //     content: Text('Could not open link: $href'),
                        //     action: SnackBarAction(
                        //       label: 'Copy URL',
                        //       onPressed: () {
                        //         Clipboard.setData(ClipboardData(text: href));
                        //         if (context.mounted) {
                        //           ScaffoldMessenger.of(context).showSnackBar(
                        //             const SnackBar(
                        //               content: Text(
                        //                 'URL copied to clipboard',
                        //               ),
                        //             ),
                        //           );
                        //         }
                        //       },
                        //     ),
                        //   ),
                        // );
                      }
                    }
                  },
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
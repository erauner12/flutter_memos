import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip; // Keep for Tooltip
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/comment_providers.dart'
    as comment_providers;
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CommentCard extends ConsumerWidget {
  final Comment comment;
  final String memoId; // Keep as memoId for consistency within card
  final String serverId; // Add serverId
  final bool isSelected; // Add isSelected

  const CommentCard({
    super.key,
    required this.comment,
    required this.memoId,
    required this.serverId,
    required this.isSelected,
  });

  void _showActions(BuildContext context, WidgetRef ref) {
    final isHidden = ref.read(
      comment_providers.isCommentHiddenProvider('$memoId/${comment.id}'),
    );
    final isFixingGrammar = ref.read(note_providers.isFixingGrammarProvider);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext popupContext) {
        return CupertinoActionSheet(
          title: const Text('Comment Actions'),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              child: const Text('Edit'),
              onPressed: () {
                Navigator.pop(popupContext);
                Navigator.of(context, rootNavigator: true).pushNamed(
                  '/edit-entity',
                  arguments: {
                    'entityType': 'comment',
                    'entityId': '$memoId/${comment.id}', // Pass combined ID
                    'serverId': serverId, // Pass serverId
                  },
                );
              },
            ),
            CupertinoActionSheetAction(
              child: Text(comment.pinned ? 'Unpin' : 'Pin'),
              onPressed: () {
                Navigator.pop(popupContext);
                // Use family provider with serverId, memoId, and commentId
                ref.read(
                  comment_providers.togglePinCommentProviderFamily((
                    serverId: serverId,
                    memoId: memoId,
                    commentId: comment.id,
                  )),
                )();
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Convert to Note'),
              onPressed: () async {
                Navigator.pop(popupContext);
                try {
                  // Use family provider
                  final newNote =
                      await ref.read(
                        comment_providers.convertCommentToNoteProviderFamily((
                          serverId: serverId,
                          memoId: memoId,
                          commentId: comment.id,
                        )),
                      )();
                  if (context.mounted) {
                    // Navigate to the new note's detail screen
                    Navigator.of(context, rootNavigator: true).pushNamed(
                      '/item-detail',
                      arguments: {'itemId': newNote.id, 'serverId': serverId}, // Pass serverId
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('Conversion Failed'),
                        content: Text(e.toString()),
                            actions: [
                              CupertinoDialogAction(
                                isDefaultAction: true,
                                child: const Text('OK'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                    );
                  }
                }
              },
            ),
            CupertinoActionSheetAction(
              isDefaultAction: !isFixingGrammar,
              onPressed: () {
                if (!isFixingGrammar) {
                  Navigator.pop(popupContext);
                  _fixGrammar(context, ref);
                }
              },
              child: isFixingGrammar
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoActivityIndicator(radius: 10),
                        SizedBox(width: 10),
                        Text('Fixing Grammar...'),
                      ],
                    )
                  : const Text('Fix Grammar (AI)'),
            ),
            CupertinoActionSheetAction(
              child: Text(isHidden ? 'Unhide' : 'Hide'),
              onPressed: () {
                Navigator.pop(popupContext);
                ref.read(
                  comment_providers.toggleHideCommentProvider(
                    '$memoId/${comment.id}',
                  ),
                )();
              },
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.pop(popupContext);
                final confirmed = await showCupertinoDialog<bool>(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('Delete Comment?'),
                    content: const Text('Are you sure? This cannot be undone.'),
                    actions: [
                          CupertinoDialogAction(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: const Text('Delete'),
                            onPressed: () => Navigator.pop(context, true),
                          ),
                    ],
                      ),
                );
                if (confirmed == true) {
                  // Use family provider
                  ref.read(
                    comment_providers.deleteCommentProviderFamily((
                      serverId: serverId,
                      memoId: memoId,
                      commentId: comment.id,
                    )),
                  )();
                }
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(popupContext),
          ),
        );
      },
    );
  }

  Future<void> _fixGrammar(BuildContext context, WidgetRef ref) async {
    ref.read(note_providers.isFixingGrammarProvider.notifier).state = true;
    HapticFeedback.mediumImpact();
    // Consider showing a loading indicator specific to this comment card if needed

    try {
      await ref.read(
        comment_providers.fixCommentGrammarProviderFamily((
          serverId: serverId,
          memoId: memoId,
          commentId: comment.id,
        )).future,
      );
      // Optionally show success feedback
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Grammar Fix Failed'),
                content: Text(e.toString()),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
      }
    } finally {
      if (context.mounted) {
        ref.read(note_providers.isFixingGrammarProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final commentContent = comment.content ?? '';
    final formattedDate = DateFormat.yMd().add_jm().format(comment.createdTs);
    final bool hasResources = comment.resources.isNotEmpty ?? false;

    final Color cardColor =
        isSelected
            ? CupertinoColors.systemGrey5.resolveFrom(context)
            : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
              context,
            );
    final Color borderColor =
        isSelected
            ? CupertinoTheme.of(context).primaryColor
            : CupertinoColors.separator.resolveFrom(context);
    final double borderWidth = isSelected ? 1.5 : 0.5;

    return GestureDetector(
      onLongPress: () => _showActions(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comment Content (Markdown)
            if (commentContent.isNotEmpty)
              MarkdownBody(
                data: commentContent,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromCupertinoTheme(
                  CupertinoTheme.of(context),
                ).copyWith(
                  p: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    fontSize: 15, // Slightly smaller for comments
                    height: 1.4,
                  ),
                  a: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    color: CupertinoTheme.of(context).primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
                onTapLink: (text, href, title) async {
                  if (href != null) {
                    UrlHelper.launchUrl(href, context: context, ref: ref);
                  }
                },
              ),
            // Separator if both content and resources exist
            if (commentContent.isNotEmpty && hasResources)
              const SizedBox(height: 8),
            // Resources Grid (Simplified)
            if (hasResources)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children:
                    comment.resources.map((resource) {
                      // Basic representation, enhance as needed
                      final filename =
                          resource['filename'] as String? ?? 'file';
                      return Tooltip(
                        message: filename,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                      ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey4.resolveFrom(
                              context,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.paperclip,
                                size: 12,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(
                              context,
                            ),
                          ),
                              const SizedBox(width: 4),
                              Text(
                                filename.length > 15
                                    ? '${filename.substring(0, 12)}...'
                                    : filename,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            // Separator if content or resources exist before footer
            if (commentContent.isNotEmpty || hasResources)
              const SizedBox(height: 8),
            // Footer Row (Date, Pinned Icon)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (comment.pinned)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(
                      CupertinoIcons.pin_fill,
                      size: 16,
                      color: CupertinoColors.systemBlue.resolveFrom(context),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

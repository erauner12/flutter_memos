import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip; // Keep for Tooltip
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/comment_providers.dart'
    as comment_providers;
import 'package:flutter_memos/providers/note_providers.dart' as note_p;
import 'package:flutter_memos/providers/ui_providers.dart'; // Replace workbench_providers.dart with ui_providers.dart
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CommentCard extends ConsumerWidget {
  final Comment comment;
  final String memoId;
  final String
  serverId; // Keep serverId as it might be needed for navigation/context
  // Remove isSelected property
  // final bool isSelected;

  const CommentCard({
    super.key,
    required this.comment,
    required this.memoId,
    required this.serverId, // Keep serverId
    // Remove isSelected from constructor
    // required this.isSelected,
  });

  void _showActions(BuildContext context, WidgetRef ref) {
    final combinedId =
        '$memoId/${comment.id}'; // Use combined ID for grammar state
    final isHidden = ref.read(
      comment_providers.isCommentHiddenProvider(combinedId),
    );
    // Use the family provider with the combined ID
    final isFixingGrammar = ref.watch(
      note_p.isFixingGrammarProvider(combinedId),
    );

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
                    'entityId': combinedId, // Pass combined ID
                    // serverId is no longer needed for edit screen
                  },
                );
              },
            ),
            CupertinoActionSheetAction(
              child: Text(comment.pinned ? 'Unpin' : 'Pin'),
              onPressed: () {
                Navigator.pop(popupContext);
                // Use non-family provider with params record
                ref.read(
                  comment_providers.togglePinCommentProvider((
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
                  // Use non-family provider with params record
                  final newNote =
                      await ref.read(
                        comment_providers.convertCommentToNoteProvider((
                          memoId: memoId,
                          commentId: comment.id,
                        )),
                      )();
                  if (context.mounted) {
                    // Navigate to the new note's detail screen
                    Navigator.of(context, rootNavigator: true).pushNamed(
                      '/item-detail',
                      arguments: {
                        'itemId': newNote.id,
                      }, // serverId no longer needed
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
                    combinedId,
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
                  // Use non-family provider with params record
                  ref.read(
                    comment_providers.deleteCommentProvider((
                      memoId: memoId,
                      commentId: comment.id,
                    )),
                  )();
                  // Clear selection if the deleted comment was selected
                  if (ref.read(selectedWorkbenchCommentIdProvider) ==
                      comment.id) {
                    ref
                        .read(selectedWorkbenchCommentIdProvider.notifier)
                        .state = null;
                  }
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
    final combinedId =
        '$memoId/${comment.id}'; // Use combined ID for grammar state
    // Use the family provider with the combined ID
    // State is set within the fixCommentGrammarProvider now
    HapticFeedback.mediumImpact();
    // Consider showing a loading indicator specific to this comment card if needed

    try {
      // Use the callable function returned by the provider
      await ref.read(
        comment_providers.fixCommentGrammarProvider((
          memoId: memoId,
          commentId: comment.id,
        )),
      )();
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
    }
    // Loading state is reset within fixCommentGrammarProvider's finally block
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentContent = comment.content ?? '';
    final formattedDate = DateFormat.yMd().add_jm().format(comment.createdTs);
    final bool hasResources = comment.resources.isNotEmpty;

    // Watch selection provider
    final selectedCommentId = ref.watch(selectedWorkbenchCommentIdProvider);
    final isSelected = selectedCommentId == comment.id;

    // Determine card color and border based on selection
    final Color cardColor =
        isSelected
            ? CupertinoColors.systemGrey5.resolveFrom(
              context,
            ) // Highlight background
            : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
              context,
            ); // Default background
    final Color borderColor =
        isSelected
            ? CupertinoColors.activeBlue.resolveFrom(
              context,
            ) // Highlight border
            : CupertinoColors.separator.resolveFrom(context); // Default border
    final double borderWidth =
        isSelected ? 1.5 : 0.5; // Thicker border when selected

    // Remove the outer GestureDetector for long press, add it for selection tap
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      // Padding is now inside the GestureDetector's child Container
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Row(
        // Use Row to place content and button side-by-side
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            // Wrap content in GestureDetector for SELECTION
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Update comment selection state
                final notifier = ref.read(
                  selectedWorkbenchCommentIdProvider.notifier,
                );
                if (isSelected) {
                  notifier.state = null; // Toggle off
                } else {
                  notifier.state = comment.id; // Select this comment
                  // Optionally clear item selection
                  ref.read(selectedWorkbenchItemIdProvider.notifier).state =
                      null;
                }
              },
              child: Padding(
                // Add padding inside the tappable area
                padding: const EdgeInsets.only(
                  left: 16.0,
                  top: 16.0,
                  bottom: 16.0,
                  right: 8.0, // Keep right padding smaller for button space
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Comment Content (Markdown) - remains the same
                    if (commentContent.isNotEmpty)
                      MarkdownBody(
                        data: commentContent,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet.fromCupertinoTheme(
                          CupertinoTheme.of(context),
                        ).copyWith(
                          p: CupertinoTheme.of(context).textTheme.textStyle
                              .copyWith(fontSize: 15, height: 1.4),
                          a: CupertinoTheme.of(
                            context,
                          ).textTheme.textStyle.copyWith(
                            color: CupertinoTheme.of(context).primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        onTapLink: (text, href, title) async {
                          if (href != null) {
                            UrlHelper.launchUrl(
                              href,
                              context: context,
                              ref: ref,
                            );
                          }
                        },
                      ),
                    // Spacer if content exists and resources or footer will follow
                    if (commentContent.isNotEmpty && (hasResources || true))
                      const SizedBox(height: 8.0),

                    // Resources Grid (Simplified) - remains the same
                    if (hasResources)
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children:
                            comment.resources.map((resource) {
                              // ... resource rendering logic ...
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
                                    color: CupertinoColors.systemGrey4
                                        .resolveFrom(context),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.paperclip,
                                        size: 12,
                                        color: CupertinoColors.secondaryLabel
                                            .resolveFrom(context),
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
                    // Spacer if resources exist before footer
                    if (hasResources) const SizedBox(height: 8.0),

                    // Footer Row (Date, Pinned Icon) - remains the same
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (comment.pinned)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(
                              CupertinoIcons.pin_fill,
                              size: 16,
                              color: CupertinoColors.systemBlue.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Ellipsis Button (outside the selection GestureDetector)
          CupertinoButton(
            padding: const EdgeInsets.only(
              left: 0.0,
              right: 8.0, // Add some right padding for visual spacing
              top: 8.0, // Add top padding to align better
            ),
            minSize: 30, // Ensure tappable area
            onPressed: () => _showActions(context, ref),
            child: const Icon(
              CupertinoIcons.ellipsis_vertical,
              size: 22,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}

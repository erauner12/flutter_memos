import 'package:flutter/material.dart' show Tooltip; // Keep for Tooltip
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Tooltip; // Keep for Tooltip
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
// Import note_providers and use families
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:intl/intl.dart';

  final Comment comment;
  final String memoId; // Keep as memoId for consistency within card
class CommentCard extends ConsumerWidget {

  final String memoId; // Keep as memoId for consistency within card
  final String serverId; // Add serverId
    super.key,
    required this.serverId, // Make serverId required
    required this.serverId, // Make serverId required

  void _showActions(BuildContext context, WidgetRef ref) {
  void _showActions(BuildContext context, WidgetRef ref) {
    final isHidden = ref.read(isCommentHiddenProvider('$memoId/${comment.id}'));
    final isFixingGrammar = ref.read(note_providers.isFixingGrammarProvider);
    showCupertinoModalPopup<void>(
    showCupertinoModalPopup<void>(
                Navigator.of(context, rootNavigator: true).pushNamed(
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
                ref.read(togglePinCommentProviderFamily((serverId: serverId, memoId: memoId, commentId: comment.id)))();
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Convert to Note'),
              onPressed: () async {
                Navigator.pop(popupContext);
                try {
                  // Use family provider
                  final newNote = await ref.read(convertCommentToNoteProviderFamily((serverId: serverId, memoId: memoId, commentId: comment.id)))();
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
                        actions: [CupertinoDialogAction(isDefaultAction: true, child: const Text('OK'), onPressed: () => Navigator.pop(context))],
  @override
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
                ref.read(toggleHideCommentProvider('$memoId/${comment.id}'))();
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
                      CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
                      CupertinoDialogAction(isDestructiveAction: true, child: const Text('Delete'), onPressed: () => Navigator.pop(context, true)),
                    ],
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
                );
                if (confirmed == true) {
                  // Use family provider
                  ref.read(deleteCommentProviderFamily((serverId: serverId, memoId: memoId, commentId: comment.id)))();
                }
              },

          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
              if (commentContent.isNotEmpty) // Check non-null content
              Navigator.pop(popupContext);
                      color: textColor,
                      fontWeight:
        );
      },
                                          alignment: Alignment.center,
                                          color: CupertinoColors.systemGrey5
                                              .resolveFrom(context),
                                          child:
                                              const CupertinoActivityIndicator(
                                                radius: 10,
                                              ),
                                        );
                                      },
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          color: CupertinoColors.systemGrey5
                                              .resolveFrom(context),
                                          child: const Icon(
                                            CupertinoIcons
                                                .exclamationmark_circle,
                                            color: CupertinoColors.systemGrey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            })
                            .toList(),
                  ),
                ),
              if (commentContent.isNotEmpty &&
                  widget.comment.resources.isNotEmpty)
                const SizedBox(height: 8),
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
                  // Combine internal actions (pin) with external actions (Todoist)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.comment.pinned)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            CupertinoIcons.pin_fill,
                            size: 16,
                            color: CupertinoColors.systemBlue.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      // Add the Todoist button logic here
                      if (_isSendingToTodoist)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: CupertinoActivityIndicator(
                            radius: 9,
                          ),
                        )
                      else
                        CupertinoButton(
                          padding: const EdgeInsets.all(4),
                          minSize: 0,
                          child: Icon(
                            CupertinoIcons.paperplane,
                            size: 18,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                          onPressed:
                              () => _sendCommentToTodoist(widget.comment),
                        ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (isMultiSelectMode) {
      // Wrap with Row for checkbox in multi-select mode
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12.0, right: 8.0),
              child: CupertinoCheckbox(
                value: isMultiSelected,
                onChanged: (value) => _toggleMultiSelection(),
                activeColor: CupertinoTheme.of(context).primaryColor,
              ),
            ),
            Expanded(child: commentCardWidget),
          ],
        ),
      );
    } else {
      // Wrap with Slidable for normal mode
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Slidable(
          key: Key('slidable-comment-${widget.comment.id}'),
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (_) => _onTogglePin(context),
                backgroundColor: CupertinoColors.systemBlue,
                foregroundColor: CupertinoColors.white,
                icon:
                    widget.comment.pinned
                        ? CupertinoIcons.pin_slash_fill
                        : CupertinoIcons.pin_fill,
                label: widget.comment.pinned ? 'Unpin' : 'Pin',
                autoClose: true,
              ),
              SlidableAction(
                onPressed: (_) => _onConvertToMemo(context),
                backgroundColor: CupertinoColors.systemTeal,
                foregroundColor: CupertinoColors.white,
                icon: CupertinoIcons.doc_text_fill,
                label: 'To Memo',
                autoClose: true,
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (_) => _onDelete(context),
                backgroundColor: CupertinoColors.destructiveRed,
                foregroundColor: CupertinoColors.white,
                icon: CupertinoIcons.delete,
                label: 'Delete',
                autoClose: true,
              ),
              SlidableAction(
                onPressed: (_) => _onArchive(context),
                backgroundColor: CupertinoColors.systemPurple,
                foregroundColor: CupertinoColors.white,
                icon: CupertinoIcons.archivebox_fill,
                label: 'Archive',
                autoClose: true,
              ),
            ],
          ),
          child: commentCardWidget,
        ),
      );
    }
  }
}
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
// Import the NoteItem model
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/utils/text_normalizer.dart'; // Import the normalizer
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class NoteContent extends ConsumerWidget { // Renamed class
  // Change the type of the note field
  final NoteItem note; // Renamed from memo
  final String noteId; // Renamed from memoId

  // Update the constructor parameter type
  const NoteContent({
    super.key,
    required this.note,
    required this.noteId,
    required String serverId,
  }); // Renamed constructor and parameters

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CupertinoTheme.of(context);

    final Color textColor = CupertinoColors.label.resolveFrom(context);
    final Color secondaryTextColor = CupertinoColors.secondaryLabel.resolveFrom(
      context,
    );

    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final DateTime createDate = note.createTime; // Use note
    final DateTime updateDate = note.updateTime; // Use note
    final String formattedCreateDate = dateFormat.format(createDate);
    final String formattedUpdateDate = dateFormat.format(updateDate);

    // Iteratively normalize the note content before using it
    final normalizedContent = TextNormalizer.iterativeNormalize(note.content);

    if (kDebugMode) {
      print('[NoteContent] Rendering note $noteId'); // Updated log identifier
      final originalLength = note.content.length;
      final normalizedLength = normalizedContent.length;
      print('[NoteContent] Original content length: $originalLength chars');
      print('[NoteContent] Normalized content length: $normalizedLength chars');
      if (normalizedLength < 200) {
        print(
          '[NoteContent] Normalized Content preview: "$normalizedContent"',
        ); // Updated log identifier
      } else {
        print(
          '[NoteContent] Normalized Content preview: "${normalizedContent.substring(0, 197)}..."', // Updated log identifier
        );
      }
      if (note.content != normalizedContent) {
        print('[NoteContent] Content was normalized using iterative method.');
        // Optionally log the original content if debugging is needed
        // print('[NoteContent] Original Content: "${note.content}"');
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note Content using MarkdownBody with normalized content
          MarkdownBody(
            data: normalizedContent, // Use iteratively normalized content
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromCupertinoTheme(theme).copyWith(
              p: theme.textTheme.textStyle.copyWith(
                fontSize: 17,
                height: 1.4,
                color: textColor,
              ),
              a: theme.textTheme.textStyle.copyWith(
                color: theme.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
            onTapLink: (text, href, title) {
              if (kDebugMode) {
                print('[NoteContent] Link tapped: text="$text", href="$href"'); // Updated log identifier
              }
              if (href != null) {
                UrlHelper.launchUrl(href, ref: ref, context: context);
              }
            },
          ),
          const SizedBox(height: 16),

          // Pinned Status
          if (note.pinned) // Access pinned from NoteItem
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.pin_fill,
                    size: 14,
                    color: CupertinoColors.systemGreen.resolveFrom(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pinned',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.systemGreen.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),

          // Timestamps
          Row(
            children: [
              Icon(
                CupertinoIcons.calendar,
                size: 14,
                color: secondaryTextColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Created: $formattedCreateDate',
                style: TextStyle(fontSize: 13, color: secondaryTextColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (!updateDate.isAtSameMomentAs(createDate))
            Row(
              children: [
                Icon(
                  CupertinoIcons.refresh_thin,
                  size: 14,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Updated: $formattedUpdateDate',
                  style: TextStyle(fontSize: 13, color: secondaryTextColor),
                ),
              ],
            ),

          // Visibility (Optional - uncomment if needed, adjust for NoteVisibility enum)
          // const SizedBox(height: 4),
          // Row(
          //   children: [
          //     Icon(
          //       note.visibility == NoteVisibility.private ? CupertinoIcons.lock_fill : CupertinoIcons.globe, // Use enum
          //       size: 14,
          //       color: secondaryTextColor,
          //     ),
          //     const SizedBox(width: 6),
          //     Text(
          //       'Visibility: ${note.visibility.name}', // Use enum name
          //       style: TextStyle(fontSize: 13, color: secondaryTextColor),
          //     ),
          //   ],
          // ),

          // Tags (if available in NoteItem model)
          if (note.tags.isNotEmpty) ...[ // Access tags from NoteItem
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children:
                  note.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey5.resolveFrom(
                              context,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            // Normalize tag display using iterative method
                            TextNormalizer.iterativeNormalize(tag),
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

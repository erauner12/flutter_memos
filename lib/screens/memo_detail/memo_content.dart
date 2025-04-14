import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
// Remove the old Memo import
// import 'package:flutter_memos/models/memo.dart';
// Import the new NoteItem model
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MemoContent extends ConsumerWidget {
  // Change the type of the memo field
  final NoteItem memo;
  final String memoId;

  // Update the constructor parameter type
  const MemoContent({super.key, required this.memo, required this.memoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use CupertinoTheme for styling
    final theme = CupertinoTheme.of(context);

    // Determine text color based on theme
    final Color textColor = CupertinoColors.label.resolveFrom(context);
    final Color secondaryTextColor = CupertinoColors.secondaryLabel.resolveFrom(
      context,
    );

    // Format dates directly from DateTime objects
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final DateTime createDate = memo.createTime; // Directly use DateTime
    final DateTime updateDate = memo.updateTime; // Directly use DateTime
    final String formattedCreateDate = dateFormat.format(createDate);
    final String formattedUpdateDate = dateFormat.format(updateDate);

    // Remove the complex date parsing try-catch block as it's no longer needed

    // Log content details in debug mode
    if (kDebugMode) {
      print('[MemoContent] Rendering memo $memoId');
      final contentLength = memo.content.length;
      print('[MemoContent] Content length: $contentLength chars');
      if (contentLength < 200) {
        print('[MemoContent] Content preview: "${memo.content}"');
      } else {
        print(
          '[MemoContent] Content preview: "${memo.content.substring(0, 197)}..."',
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Memo Content using MarkdownBody
          MarkdownBody(
            data: memo.content, // Access content from NoteItem
            selectable: true,
            // Use MarkdownStyleSheet.fromCupertinoTheme for base styling
            styleSheet: MarkdownStyleSheet.fromCupertinoTheme(theme).copyWith(
              // Customize specific styles if needed
              p: theme.textTheme.textStyle.copyWith(
                fontSize: 17, // Example customization
                height: 1.4,
                color: textColor, // Ensure text color respects theme
              ),
              a: theme.textTheme.textStyle.copyWith(
                color: theme.primaryColor, // Use theme primary for links
                decoration: TextDecoration.underline,
              ),
              // Add other style customizations here (e.g., h1, code)
            ),
            onTapLink: (text, href, title) {
              if (kDebugMode) {
                print('[MemoContent] Link tapped: text="$text", href="$href"');
              }
              if (href != null) {
                UrlHelper.launchUrl(href, ref: ref, context: context);
              }
            },
          ),
          const SizedBox(height: 16),

          // Pinned Status
          if (memo.pinned) // Access pinned from NoteItem
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
                'Created: $formattedCreateDate', // Use formatted DateTime
                style: TextStyle(fontSize: 13, color: secondaryTextColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Use the DateTime objects for comparison
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
                  'Updated: $formattedUpdateDate', // Use formatted DateTime
                  style: TextStyle(fontSize: 13, color: secondaryTextColor),
                ),
              ],
            ),

          // Visibility (Optional - uncomment if needed, adjust for NoteVisibility enum)
          // const SizedBox(height: 4),
          // Row(
          //   children: [
          //     Icon(
          //       memo.visibility == NoteVisibility.private ? CupertinoIcons.lock_fill : CupertinoIcons.globe, // Use enum
          //       size: 14,
          //       color: secondaryTextColor,
          //     ),
          //     const SizedBox(width: 6),
          //     Text(
          //       'Visibility: ${memo.visibility.name}', // Use enum name
          //       style: TextStyle(fontSize: 13, color: secondaryTextColor),
          //     ),
          //   ],
          // ),

          // Tags (if available in NoteItem model)
          if (memo.tags.isNotEmpty) ...[
            // Access tags from NoteItem
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              // Use CupertinoChip or similar if desired
              children:
                  memo.tags
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
                            tag,
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

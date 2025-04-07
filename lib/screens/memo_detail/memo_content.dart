import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MemoContent extends ConsumerWidget {
  final Memo memo;
  final String memoId;

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

    // Format dates safely
    DateTime? createDate;
    DateTime? updateDate;
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    String formattedCreateDate = 'N/A';
    String formattedUpdateDate = 'N/A';

    try {
      if (memo.createTime != null) {
        // Try parsing as ISO 8601 string first
        createDate = DateTime.tryParse(memo.createTime!);
        if (createDate == null) {
          // Fallback: Try parsing as milliseconds since epoch (integer string)
          final ms = int.tryParse(memo.createTime!);
          if (ms != null) {
            createDate = DateTime.fromMillisecondsSinceEpoch(ms);
          }
        }
      }
      // Default to epoch if parsing fails or createTime is null
      createDate ??= DateTime.fromMillisecondsSinceEpoch(0);
      formattedCreateDate = dateFormat.format(createDate);

      if (memo.updateTime != null) {
        // Try parsing as ISO 8601 string first
        updateDate = DateTime.tryParse(memo.updateTime!);
        if (updateDate == null) {
          // Fallback: Try parsing as milliseconds since epoch (integer string)
          final ms = int.tryParse(memo.updateTime!);
          if (ms != null) {
            updateDate = DateTime.fromMillisecondsSinceEpoch(ms);
          }
        }
      }
      // Default to createDate if updateTime is null or parsing fails
      updateDate ??= createDate;
      formattedUpdateDate = dateFormat.format(updateDate);
    } catch (e) {
      if (kDebugMode) {
        print('[MemoContent] Error parsing dates: $e');
        print('[MemoContent] createTime string: ${memo.createTime}');
        print('[MemoContent] updateTime string: ${memo.updateTime}');
      }
      // Leave dates as 'N/A' or epoch if error occurs
      createDate ??= DateTime.fromMillisecondsSinceEpoch(0);
      updateDate ??= createDate;
      formattedCreateDate = dateFormat.format(
        createDate,
      ); // Show epoch date on error
      formattedUpdateDate = dateFormat.format(updateDate);
    }

    // final dateFormat = DateFormat('MMM d, yyyy h:mm a'); // Moved up
    // final formattedCreateDate = dateFormat.format(createDate); // Moved up
    // final formattedUpdateDate = dateFormat.format(updateDate); // Removed duplicate declaration

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
            data: memo.content,
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
          if (memo.pinned)
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
          // Use the parsed dates for comparison and display
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

          // Visibility (Optional - uncomment if needed)
          // const SizedBox(height: 4),
          // Row(
          //   children: [
          //     Icon(
          //       memo.visibility == 'PRIVATE' ? CupertinoIcons.lock_fill : CupertinoIcons.globe,
          //       size: 14,
          //       color: secondaryTextColor,
          //     ),
          //     const SizedBox(width: 6),
          //     Text(
          //       'Visibility: ${memo.visibility}',
          //       style: TextStyle(fontSize: 13, color: secondaryTextColor),
          //     ),
          //   ],
          // ),

          // Tags (if available in Memo model) - Placeholder
          // if (memo.tags != null && memo.tags!.isNotEmpty) ...[
          //   const SizedBox(height: 12),
          //   Wrap(
          //     spacing: 8.0,
          //     runSpacing: 4.0,
          //     children: memo.tags!.map((tag) => Chip(label: Text(tag))).toList(),
          //   ),
          // ],
        ],
      ),
    );
  }
}

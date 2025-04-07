import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
// TextDecoration is in dart:ui, usually implicitly imported
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment model
import 'package:flutter_memos/models/memo.dart'; // Import Memo model
import 'package:flutter_memos/utils/keyboard_navigation.dart'; // Import the mixin
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_memo_providers.dart';

class EditMemoForm extends ConsumerStatefulWidget {
  final dynamic entity; // Can be Memo or Comment
  final String entityId; // memoId or "memoId/commentId"
  final String entityType; // 'memo' or 'comment'

  const EditMemoForm({
    super.key,
    required this.entity,
    required this.entityId,
    required this.entityType,
  });

  @override
  ConsumerState<EditMemoForm> createState() => _EditMemoFormState();
}

class _EditMemoFormState extends ConsumerState<EditMemoForm>
    with KeyboardNavigationMixin<EditMemoForm> {
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  final FocusNode _formFocusNode = FocusNode(debugLabel: 'EditMemoFormFocus');

  bool _saving = false;
  bool _pinned = false;
  bool _archived = false;
  bool _showMarkdownHelp = false;
  bool _previewMode = false;

  @override
  void initState() {
    super.initState();
    // Initialize form with entity data based on type
    if (widget.entityType == 'comment') {
      final comment = widget.entity as Comment;
      _contentController.text = comment.content;
      _pinned = comment.pinned;
      _archived = comment.state == CommentState.archived;
      if (kDebugMode) {
        print('[EditMemoForm] Initialized for Comment ID: ${widget.entityId}');
      }
    } else {
      // 'memo'
      final memo = widget.entity as Memo;
      _contentController.text = memo.content;
      _pinned = memo.pinned;
      _archived = memo.state == MemoState.archived;
      if (kDebugMode) {
        print('[EditMemoForm] Initialized for Memo ID: ${widget.entityId}');
      }
    }

    if (kDebugMode) {
      print(
        '[EditMemoForm] Content length: ${_contentController.text.length} chars',
      );
      if (_contentController.text.length < 200) {
        print('[EditMemoForm] Content: "${_contentController.text}"');
      } else {
        print(
          '[EditMemoForm] Content preview: "${_contentController.text.substring(0, 197)}..."',
        );
      }
    }
    // Request focus for the form area after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Initially focus the text field
        FocusScope.of(context).requestFocus(_contentFocusNode);
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
    _formFocusNode.dispose(); // Dispose the form focus node
    super.dispose();
  }

  Widget _buildMarkdownHelpItem(String syntax, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              // Replace SelectableText with Text
              syntax,
              style: TextStyle(
                fontFamily: 'monospace',
                backgroundColor: CupertinoColors.secondarySystemFill
                    .resolveFrom(context), // Use Cupertino color
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: MarkdownBody(data: description, shrinkWrap: true),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_contentController.text.trim().isEmpty) {
      // Replace SnackBar with CupertinoAlertDialog
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Empty Content'),
              content: const Text('Content cannot be empty.'),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    if (kDebugMode) {
      print(
        '[EditMemoForm] Saving ${widget.entityType} ${widget.entityId} via _handleSave',
      );
      print(
        '[EditMemoForm] Content length: ${_contentController.text.trim().length} characters',
      );
      print('[EditMemoForm] Settings: pinned=$_pinned, archived=$_archived');
    }

    try {
      // Create the correct entity type (Memo or Comment) to save
      dynamic entityToSave;
      if (widget.entityType == 'comment') {
        final originalComment = widget.entity as Comment;
        entityToSave = originalComment.copyWith(
          content: _contentController.text.trim(),
          pinned: _pinned,
          state: _archived ? CommentState.archived : CommentState.normal,
          // updateTime will be handled by the API/provider logic if needed
        );
        if (kDebugMode) {
          print('[EditMemoForm] Saving Comment: ${entityToSave.toJson()}');
        }
      } else {
        // 'memo'
        final originalMemo = widget.entity as Memo;
        entityToSave = originalMemo.copyWith(
          content: _contentController.text.trim(),
          pinned: _pinned,
          state: _archived ? MemoState.archived : MemoState.normal,
          // Don't explicitly set createTime or updateTime - let the API/provider handle updateTime
        );
        if (kDebugMode) {
          print('[EditMemoForm] Saving Memo: ${entityToSave.toJson()}');
        }
      }

      // Use the generalized provider to save the entity
      await ref.read(
        saveEntityProvider(
          EntityProviderParams(id: widget.entityId, type: widget.entityType),
        ),
      )(entityToSave);

      if (kDebugMode) {
        print(
          '[EditMemoForm] ${widget.entityType} saved successfully: ${widget.entityId}',
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e, s) {
      if (kDebugMode) {
        print('[EditMemoForm] Error saving ${widget.entityType}: $e\n$s');
      }
      if (mounted) {
        // Replace SnackBar with CupertinoAlertDialog
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Save Error'),
                content: Text(
                  'Failed to save ${widget.entityType}: ${e.toString()}',
                ),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _formFocusNode,
      onKeyEvent: (node, event) {
        if (kDebugMode) {
          print(
            '[EditMemoForm] Received key event: ${event.logicalKey.keyLabel}',
          );
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            final metaPressed =
                HardwareKeyboard.instance.isLogicalKeyPressed(
                  LogicalKeyboardKey.meta,
                ) ||
                HardwareKeyboard.instance.isLogicalKeyPressed(
                  LogicalKeyboardKey.metaLeft,
                ) ||
                HardwareKeyboard.instance.isLogicalKeyPressed(
                  LogicalKeyboardKey.metaRight,
                );
            print(
              '[EditMemoForm] Enter key pressed. Meta key pressed: $metaPressed',
            );
          }
        }

        // First, explicitly check for Command+Enter
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            (HardwareKeyboard.instance.isLogicalKeyPressed(
                  LogicalKeyboardKey.meta,
                ) ||
                HardwareKeyboard.instance.isLogicalKeyPressed(
                  LogicalKeyboardKey.metaLeft,
                ) ||
                HardwareKeyboard.instance.isLogicalKeyPressed(
                  LogicalKeyboardKey.metaRight,
                ))) {
          if (!_saving) {
            // Prevent double submission
            if (kDebugMode) {
              print(
                '[EditMemoForm] Command+Enter detected, calling _handleSave',
              );
            }
            _handleSave();
          } else {
            if (kDebugMode) {
              print(
                '[EditMemoForm] Command+Enter detected, but already saving',
              );
            }
          }
          return KeyEventResult.handled;
        }

        // Handle other keys (like Escape) using the mixin
        final result = handleKeyEvent(
          event,
          ref,
          onEscape: () {
            if (_contentFocusNode.hasFocus) {
              _contentFocusNode.unfocus();
              _formFocusNode.requestFocus();
            } else {
              // If form has focus (not text field), pop screen on Escape
              Navigator.of(context).pop();
            }
          },
        );

        // Return handled if the mixin handled it, otherwise ignore
        return result;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CONTENT',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(
                      context,
                    ), // Use Cupertino color
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                // Replace TextButton.icon with CupertinoButton
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () {
                    setState(() {
                      _showMarkdownHelp = !_showMarkdownHelp;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showMarkdownHelp
                            ? CupertinoIcons.question_circle_fill
                            : CupertinoIcons.question_circle,
                        size: 18,
                        color: CupertinoTheme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showMarkdownHelp ? 'Hide Help' : 'Markdown Help',
                        style: TextStyle(
                          color: CupertinoTheme.of(context).primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_showMarkdownHelp)
              // Replace Card with styled Container
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemGroupedBackground
                      .resolveFrom(context),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Markdown Syntax Guide',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMarkdownHelpItem('# Heading 1', 'Heading 1'),
                    _buildMarkdownHelpItem('## Heading 2', 'Heading 2'),
                    _buildMarkdownHelpItem('**Bold text**', 'Bold text'),
                    _buildMarkdownHelpItem('*Italic text*', 'Italic text'),
                    _buildMarkdownHelpItem(
                      '[Link](https://example.com)',
                      'Link',
                    ),
                    _buildMarkdownHelpItem('- Bullet point', 'Bullet point'),
                    _buildMarkdownHelpItem('1. Numbered item', 'Numbered item'),
                    _buildMarkdownHelpItem('`Code`', 'Code'),
                    _buildMarkdownHelpItem('> Blockquote', 'Blockquote'),
                  ],
                ),
              ),

            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Replace TextButton.icon with CupertinoButton
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () {
                    setState(() {
                      _previewMode = !_previewMode;
                      if (kDebugMode) {
                        print(
                          '[EditMemoForm] Switched to ${_previewMode ? "preview" : "edit"} mode',
                        );

                        if (_previewMode) {
                          final content = _contentController.text;
                          print(
                            '[EditMemoForm] Previewing content with ${content.length} chars',
                          );
                          final urlRegex = RegExp(
                            r'(https?://[^\s]+)|([\w-]+://[^\s]+)',
                          );
                          final matches = urlRegex.allMatches(content);
                          if (matches.isNotEmpty) {
                            print('[EditMemoForm] URLs in preview content:');
                            for (final match in matches) {
                              print('[EditMemoForm]   - ${match.group(0)}');
                            }
                          }
                        }
                      }
                      // Ensure correct focus when switching modes
                      if (!_previewMode) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _contentFocusNode.requestFocus();
                        });
                      } else {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _formFocusNode.requestFocus();
                        });
                      }
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _previewMode
                            ? CupertinoIcons.pencil
                            : CupertinoIcons.eye,
                        size: 18,
                        color: CupertinoTheme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _previewMode ? 'Edit' : 'Preview',
                        style: TextStyle(
                          color: CupertinoTheme.of(context).primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            _previewMode
                ? Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: CupertinoColors.separator.resolveFrom(context),
                    ), // Use Cupertino color
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 200),
                  child: SingleChildScrollView(
                    child: MarkdownBody(
                      data: _contentController.text,
                      selectable: true,
                      // Apply Cupertino-based styling consistent with MemoContent
                      styleSheet: MarkdownStyleSheet.fromCupertinoTheme(
                        CupertinoTheme.of(context),
                      ).copyWith(
                        p: CupertinoTheme.of(
                          context,
                        ).textTheme.textStyle.copyWith(
                          fontSize: 17,
                          height: 1.4,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                        a: CupertinoTheme.of(
                          context,
                        ).textTheme.textStyle.copyWith(
                          color: CupertinoTheme.of(context).primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onTapLink: (text, href, title) async {
                        if (kDebugMode) {
                          print(
                            '[EditMemoForm] Link tapped in preview: text="$text", href="$href"',
                          );
                        }
                        if (href != null) {
                          // Pass the ref to UrlHelper.launchUrl
                          final success = await UrlHelper.launchUrl(
                            href,
                            ref: ref, // Pass the ref
                            context: context,
                          );
                          if (kDebugMode) {
                            print('[EditMemoForm] URL launch result: $success');
                          }
                        }
                      },
                    ),
                  ),
                )
                // Replace TextField with CupertinoTextField
                : CupertinoTextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  placeholder: 'Enter memo content...',
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemFill.resolveFrom(context),
                    border: Border.all(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  maxLines: 10,
                  minLines: 5,
                  autofocus: true,
                  keyboardType: TextInputType.multiline,
                ),

            const SizedBox(height: 20),

            // Use CupertinoListSection for grouping toggles
            CupertinoListSection.insetGrouped(
              margin: EdgeInsets.zero, // Remove default margin if needed
              children: [
                // Replace ListTile/Switch with CupertinoListTile/CupertinoSwitch
                CupertinoListTile(
                  title: const Text('Pinned'),
                  trailing: CupertinoSwitch(
                    value: _pinned,
                    onChanged: (value) {
                      setState(() {
                        _pinned = value;
                      });
                    },
                    activeTrackColor: CupertinoTheme.of(context).primaryColor,
                  ),
                ),
                CupertinoListTile(
                  title: const Text('Archived'),
                  trailing: CupertinoSwitch(
                    value: _archived,
                    onChanged: (value) {
                      setState(() {
                        _archived = value;
                      });
                    },
                    activeTrackColor: CupertinoTheme.of(context).primaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              // Replace ElevatedButton with CupertinoButton.filled
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _saving ? null : _handleSave,
                child:
                    _saving
                        // Replace CircularProgressIndicator with CupertinoActivityIndicator
                        ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white, // Ensure contrast
                          radius: 10, // Adjust size
                        )
                        : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    ); // Correctly close SingleChildScrollView
  } // Correctly close build method
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment model
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem model
import 'package:flutter_memos/utils/keyboard_navigation.dart'; // Import the mixin
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_entity_providers.dart'; // Updated import

class EditEntityForm extends ConsumerStatefulWidget { // Renamed class
  final dynamic entity; // Can be NoteItem or Comment
  final String entityId; // noteId or "noteId/commentId"
  final String entityType; // 'note' or 'comment'

  const EditEntityForm({ // Renamed constructor
    super.key,
    required this.entity,
    required this.entityId,
    required this.entityType,
  });

  @override
  ConsumerState<EditEntityForm> createState() => _EditEntityFormState(); // Renamed class
}

class _EditEntityFormState extends ConsumerState<EditEntityForm> // Renamed class
    with KeyboardNavigationMixin<EditEntityForm> { // Renamed class
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  final FocusNode _formFocusNode = FocusNode(debugLabel: 'EditEntityFormFocus'); // Renamed debug label

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
      _contentController.text = comment.content ?? '';
      _pinned = comment.pinned;
      _archived = comment.state == CommentState.archived;
      if (kDebugMode) {
        print('[EditEntityForm] Initialized for Comment ID: ${widget.entityId}'); // Updated log identifier
      }
    } else {
      // 'note'
      final note = widget.entity as NoteItem; // Use NoteItem
      _contentController.text = note.content;
      _pinned = note.pinned;
      _archived = note.state == NoteState.archived; // Use NoteState
      if (kDebugMode) {
        print('[EditEntityForm] Initialized for Note ID: ${widget.entityId}'); // Updated log identifier
      }
    }

    if (kDebugMode) {
      print(
        '[EditEntityForm] Content length: ${_contentController.text.length} chars', // Updated log identifier
      );
      if (_contentController.text.length < 200) {
        print('[EditEntityForm] Content: "${_contentController.text}"'); // Updated log identifier
      } else {
        print(
          '[EditEntityForm] Content preview: "${_contentController.text.substring(0, 197)}..."', // Updated log identifier
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
              syntax,
              style: TextStyle(
                fontFamily: 'monospace',
                backgroundColor: CupertinoColors.secondarySystemFill
                    .resolveFrom(context),
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
        '[EditEntityForm] Saving ${widget.entityType} ${widget.entityId} via _handleSave', // Updated log identifier
      );
      print(
        '[EditEntityForm] Content length: ${_contentController.text.trim().length} characters', // Updated log identifier
      );
      print('[EditEntityForm] Settings: pinned=$_pinned, archived=$_archived'); // Updated log identifier
    }

    try {
      // Create the correct entity type (NoteItem or Comment) to save
      dynamic entityToSave;
      if (widget.entityType == 'comment') {
        final originalComment = widget.entity as Comment;
        entityToSave = originalComment.copyWith(
          content: _contentController.text.trim(),
          pinned: _pinned,
          state: _archived ? CommentState.archived : CommentState.normal,
        );
        if (kDebugMode) {
          print('[EditEntityForm] Saving Comment: ${entityToSave.toJson()}'); // Updated log identifier
        }
      } else {
        // 'note'
        final originalNote = widget.entity as NoteItem; // Use NoteItem
        entityToSave = originalNote.copyWith(
          content: _contentController.text.trim(),
          pinned: _pinned,
          state:
              _archived
                  ? NoteState.archived
                  : NoteState.normal, // Use NoteState
        );
        if (kDebugMode) {
          // Correctly convert NoteState enum to string for logging
          final stateString = entityToSave.state.toString().split('.').last;
          print(
            '[EditEntityForm] Saving Note: id=${entityToSave.id}, content="${entityToSave.content.substring(0, (entityToSave.content.length > 50 ? 50 : entityToSave.content.length))}...", pinned=${entityToSave.pinned}, state=$stateString', // Updated log identifier
          );
        }
      }

      await ref.read(
        saveEntityProvider(
          EntityProviderParams(id: widget.entityId, type: widget.entityType),
        ),
      )(entityToSave);

      if (kDebugMode) {
        print(
          '[EditEntityForm] ${widget.entityType} saved successfully: ${widget.entityId}', // Updated log identifier
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e, s) {
      if (kDebugMode) {
        print('[EditEntityForm] Error saving ${widget.entityType}: $e\n$s'); // Updated log identifier
      }
      if (mounted) {
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
            '[EditEntityForm] Received key event: ${event.logicalKey.keyLabel}', // Updated log identifier
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
              '[EditEntityForm] Enter key pressed. Meta key pressed: $metaPressed', // Updated log identifier
            );
          }
        }

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
            if (kDebugMode) {
              print(
                '[EditEntityForm] Command+Enter detected, calling _handleSave', // Updated log identifier
              );
            }
            _handleSave();
          } else {
            if (kDebugMode) {
              print(
                '[EditEntityForm] Command+Enter detected, but already saving', // Updated log identifier
              );
            }
          }
          return KeyEventResult.handled;
        }

        final result = handleKeyEvent(
          event,
          ref,
          onEscape: () {
            if (_contentFocusNode.hasFocus) {
              _contentFocusNode.unfocus();
              _formFocusNode.requestFocus();
            } else {
              Navigator.of(context).pop();
            }
          },
        );

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
                    ),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
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
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () {
                    setState(() {
                      _previewMode = !_previewMode;
                      if (kDebugMode) {
                        print(
                          '[EditEntityForm] Switched to ${_previewMode ? "preview" : "edit"} mode', // Updated log identifier
                        );
                        if (_previewMode) {
                          final content = _contentController.text;
                          print(
                            '[EditEntityForm] Previewing content with ${content.length} chars', // Updated log identifier
                          );
                          final urlRegex = RegExp(
                            r'(https?://[^\s]+)|([\w-]+://[^\s]+)',
                          );
                          final matches = urlRegex.allMatches(content);
                          if (matches.isNotEmpty) {
                            print('[EditEntityForm] URLs in preview content:'); // Updated log identifier
                            for (final match in matches) {
                              print('[EditEntityForm]   - ${match.group(0)}'); // Updated log identifier
                            }
                          }
                        }
                      }
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
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 200),
                  child: SingleChildScrollView(
                    child: MarkdownBody(
                      data: _contentController.text,
                      selectable: true,
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
                            '[EditEntityForm] Link tapped in preview: text="$text", href="$href"', // Updated log identifier
                          );
                        }
                        if (href != null) {
                          final success = await UrlHelper.launchUrl(
                            href,
                            ref: ref,
                            context: context,
                          );
                          if (kDebugMode) {
                            print('[EditEntityForm] URL launch result: $success'); // Updated log identifier
                          }
                        }
                      },
                    ),
                  ),
                )
                : CupertinoTextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  placeholder: 'Enter content...', // Updated placeholder
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
            CupertinoListSection.insetGrouped(
              margin: EdgeInsets.zero,
              children: [
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
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _saving ? null : _handleSave,
                child:
                    _saving
                        ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                          radius: 10,
                        )
                        : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
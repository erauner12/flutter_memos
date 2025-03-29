import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/utils/keyboard_navigation.dart'; // Import the mixin
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_memo_providers.dart';

class EditMemoForm extends ConsumerStatefulWidget {
  final Memo memo;
  final String memoId;

  const EditMemoForm({
    super.key,
    required this.memo,
    required this.memoId,
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
    // Initialize form with memo data
    _contentController.text = widget.memo.content;
    _pinned = widget.memo.pinned;
    _archived = widget.memo.state == MemoState.archived;

    if (kDebugMode) {
      print('[EditMemoForm] Initialized with memo ID: ${widget.memoId}');
      print(
        '[EditMemoForm] Content length: ${widget.memo.content.length} chars',
      );
      if (widget.memo.content.length < 200) {
        print('[EditMemoForm] Content: "${widget.memo.content}"');
      } else {
        print(
          '[EditMemoForm] Content preview: "${widget.memo.content.substring(0, 197)}..."',
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
            child: SelectableText(
              syntax,
              style: const TextStyle(
                fontFamily: 'monospace',
                backgroundColor: Color(0xFFF5F5F5),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content cannot be empty')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    if (kDebugMode) {
      print('[EditMemoForm] Saving memo ${widget.memoId} via _handleSave');
      print(
        '[EditMemoForm] Content length: ${_contentController.text.trim().length} characters',
      );
      print('[EditMemoForm] Settings: pinned=$_pinned, archived=$_archived');
    }

    try {
      final updatedMemo = widget.memo.copyWith(
        content: _contentController.text.trim(),
        pinned: _pinned,
        state: _archived ? MemoState.archived : MemoState.normal,
      );

      // Use the provider to save the memo
      await ref.read(saveMemoProvider(widget.memoId))(updatedMemo);
      if (kDebugMode) {
        print('[EditMemoForm] Memo saved successfully: ${widget.memoId}');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (kDebugMode) {
        print('[EditMemoForm] Error saving memo: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
        // Explicitly check for Command+Enter first using event properties
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            event.isMetaPressed) {
          // Use event.isMetaPressed
          if (!_saving) {
            // Prevent double submission
            if (kDebugMode) {
              // Ensure this debug print exists
              print(
                '[EditMemoForm] Command+Enter detected (using event.isMetaPressed), calling _handleSave',
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
          // Other navigation keys (Up/Down/Back/Forward) are ignored if text input focused
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
                const Text(
                  'CONTENT',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                TextButton.icon(
                  icon: Icon(
                    _showMarkdownHelp ? Icons.help_outline : Icons.help,
                  ),
                  label: Text(
                    _showMarkdownHelp ? 'Hide Help' : 'Markdown Help',
                  ),
                  onPressed: () {
                    setState(() {
                      _showMarkdownHelp = !_showMarkdownHelp;
                    });
                  },
                ),
              ],
            ),

            if (_showMarkdownHelp)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
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
                      _buildMarkdownHelpItem(
                        '1. Numbered item',
                        'Numbered item',
                      ),
                      _buildMarkdownHelpItem('`Code`', 'Code'),
                      _buildMarkdownHelpItem('> Blockquote', 'Blockquote'),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(_previewMode ? Icons.edit : Icons.visibility),
                  label: Text(_previewMode ? 'Edit' : 'Preview'),
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
                ),
              ],
            ),

            _previewMode
                ? Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 200),
                  child: SingleChildScrollView(
                    child: MarkdownBody(
                      data: _contentController.text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        a: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
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
                          final success = await UrlHelper.launchUrl(
                            href,
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
                : TextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Enter memo content...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  maxLines: 10,
                  minLines: 5,
                  autofocus: true,
                ),

            const SizedBox(height: 20),

            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                title: const Text('Pinned'),
                trailing: Switch(
                  value: _pinned,
                  onChanged: (value) {
                    setState(() {
                      _pinned = value;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                title: const Text('Archived'),
                trailing: Switch(
                  value: _archived,
                  onChanged: (value) {
                    setState(() {
                      _archived = value;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _saving ? null : _handleSave,
                child:
                    _saving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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

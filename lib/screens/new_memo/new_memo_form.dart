import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/utils/keyboard_navigation.dart'; // Import the mixin
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'new_memo_providers.dart';

class NewMemoForm extends ConsumerStatefulWidget {
  const NewMemoForm({super.key});

  @override
  ConsumerState<NewMemoForm> createState() => _NewMemoFormState();
}

class _NewMemoFormState extends ConsumerState<NewMemoForm>
    with KeyboardNavigationMixin<NewMemoForm> {
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  final FocusNode _formFocusNode = FocusNode(debugLabel: 'NewMemoFormFocus');

  bool _loading = false;
  String? _error;
  bool _showMarkdownHelp = false;
  bool _previewMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_contentFocusNode);
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
    _formFocusNode.dispose();
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

  Future<void> _handleCreateMemo() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter some memo content')),
        );
      }
      return;
    }

    if (kDebugMode) {
      print('[NewMemoForm] Creating new memo via _handleCreateMemo');
      print('[NewMemoForm] Content length: ${content.length} characters');
      if (content.length < 200) {
        print('[NewMemoForm] Content: "$content"');
      } else {
        print(
          '[NewMemoForm] Content preview: "${content.substring(0, 197)}..."',
        );
      }

      final urlRegex = RegExp(r'(https?://[^\s]+)|([\w-]+://[^\s]+)');
      final matches = urlRegex.allMatches(content);
      if (matches.isNotEmpty) {
        print('[NewMemoForm] URLs in content:');
        for (final match in matches) {
          print('[NewMemoForm]   - ${match.group(0)}');
        }
      }
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final newMemo = Memo(
        id: 'temp',
        content: content,
        visibility: 'PUBLIC',
      );

      await ref.read(createMemoProvider)(newMemo);

      if (kDebugMode) {
        print('[NewMemoForm] Memo created successfully');
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NewMemoForm] Error creating memo: $e');
      }

      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating memo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
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
            HardwareKeyboard.instance.isMetaPressed) {
          // Use HardwareKeyboard.instance.isMetaPressed
          if (!_loading) {
            // Prevent double submission
            if (kDebugMode) {
              // Ensure this debug print exists
              print(
                '[NewMemoForm] Command+Enter detected (using HardwareKeyboard.instance.isMetaPressed), calling _handleCreateMemo',
              );
            }
            _handleCreateMemo();
          } else {
            if (kDebugMode) {
              print(
                '[NewMemoForm] Command+Enter detected, but already loading',
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                          '[NewMemoForm] Switched to ${_previewMode ? "preview" : "edit"} mode',
                        );

                        if (_previewMode) {
                          final content = _contentController.text;
                          print(
                            '[NewMemoForm] Previewing content with ${content.length} chars',
                          );
                          final urlRegex = RegExp(
                            r'(https?://[^\s]+)|([\w-]+://[^\s]+)',
                          );
                          final matches = urlRegex.allMatches(content);
                          if (matches.isNotEmpty) {
                            print('[NewMemoForm] URLs in preview content:');
                            for (final match in matches) {
                              print('[NewMemoForm]   - ${match.group(0)}');
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
                            '[NewMemoForm] Link tapped in preview: text="$text", href="$href"',
                          );
                        }
                        if (href != null) {
                          final success = await UrlHelper.launchUrl(
                            href,
                            context: context,
                          );
                          if (kDebugMode) {
                            print('[NewMemoForm] URL launch result: $success');
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
                    hintText: 'Enter your memo content...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  maxLines: 10,
                  minLines: 5,
                  autofocus: true,
                ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _loading ? null : _handleCreateMemo,
                child:
                    _loading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('Create Memo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

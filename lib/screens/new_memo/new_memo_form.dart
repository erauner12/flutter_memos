import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'new_memo_providers.dart';

class NewMemoForm extends ConsumerStatefulWidget {
  const NewMemoForm({super.key});

  @override
  ConsumerState<NewMemoForm> createState() => _NewMemoFormState();
}

class _NewMemoFormState extends ConsumerState<NewMemoForm> {
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  
  bool _loading = false;
  String? _error;
  bool _showMarkdownHelp = false;
  bool _previewMode = false;

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
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
    // Extract content early to avoid any race conditions
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter some memo content')),
        );
      }
      return;
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
      
      // Use the provider to create the memo
      await ref.read(createMemoProvider)(newMemo);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
        
        // Show error in snackbar for better visibility
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating memo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Add mainAxisSize.min to prevent unbounded height problem
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
                icon: Icon(_showMarkdownHelp ? Icons.help_outline : Icons.help),
                label: Text(_showMarkdownHelp ? 'Hide Help' : 'Markdown Help'),
                onPressed: () {
                  setState(() {
                    _showMarkdownHelp = !_showMarkdownHelp;
                  });
                },
              ),
            ],
          ),

          // Show markdown help if toggled
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
                    _buildMarkdownHelpItem('1. Numbered item', 'Numbered item'),
                    _buildMarkdownHelpItem('`Code`', 'Code'),
                    _buildMarkdownHelpItem('> Blockquote', 'Blockquote'),
                  ],
                ),
              ),
            ),

          // Toggle between preview and edit mode
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: Icon(_previewMode ? Icons.edit : Icons.visibility),
                label: Text(_previewMode ? 'Edit' : 'Preview'),
                onPressed: () {
                  setState(() {
                    _previewMode = !_previewMode;
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
                      if (href != null) {
                        final Uri url = Uri.parse(href);
                        if (!await launchUrl(url)) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not launch $href')),
                            );
                          }
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
                onSubmitted: (_) {
                  // Clear focus on submission
                  _contentFocusNode.unfocus();
                },
              ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          // Replace Spacer with fixed height SizedBox to avoid layout issues
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
              child: _loading
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
    );
  }
}

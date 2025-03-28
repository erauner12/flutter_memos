import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _EditMemoFormState extends ConsumerState<EditMemoForm> {
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  
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
  }

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

    try {
      final updatedMemo = widget.memo.copyWith(
        content: _contentController.text.trim(),
        pinned: _pinned,
        state: _archived ? MemoState.archived : MemoState.normal,
      );
      
      // Use the provider to save the memo
      await ref.read(saveMemoProvider(widget.memoId))(updatedMemo);
      if (mounted) Navigator.pop(context);
    } catch (e) {
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
    return SingleChildScrollView(
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
            
          const SizedBox(height: 4),
          
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
                  hintText: 'Enter memo content...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 10,
                minLines: 5,
                onSubmitted: (_) {
                  // Clear focus on submission
                  _contentFocusNode.unfocus();
                },
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
              child: _saving
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
    );
  }
}

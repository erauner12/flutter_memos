import 'package:flutter/material.dart';
import 'package:flutter_memos/models/memo.dart';
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

class _EditMemoFormState extends ConsumerState<EditMemoForm> {
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  
  bool _saving = false;
  bool _pinned = false;
  bool _archived = false;

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
          const Text(
            'CONTENT',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
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

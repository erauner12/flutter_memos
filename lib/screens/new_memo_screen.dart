import 'package:flutter/material.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for creating a new memo
final createMemoProvider = Provider<Future<void> Function(Memo)>((ref) {
  return (Memo memo) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.createMemo(memo);
    ref.invalidate(memosProvider); // Refresh the memos list
  };
});

class NewMemoScreen extends ConsumerStatefulWidget {
  const NewMemoScreen({super.key});

  @override
  ConsumerState<NewMemoScreen> createState() => _NewMemoScreenState();
}

class _NewMemoScreenState extends ConsumerState<NewMemoScreen> {
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a New Memo'),
        actions: [
          TextButton(
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
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
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
            const Spacer(),
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
      ),
    );
  }
}

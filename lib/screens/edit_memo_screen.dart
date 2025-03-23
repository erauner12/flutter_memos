import 'package:flutter/material.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the current memo being edited
final editMemoProvider = FutureProvider.family<Memo, String>((ref, id) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getMemo(id);
});

// Provider for saving memo changes
final saveMemoProvider = Provider.family<Future<void> Function(Memo), String>((
  ref,
  id,
) {
  return (Memo updatedMemo) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.updateMemo(id, updatedMemo);
    ref.invalidate(memosProvider); // Refresh the memos list
  };
});

class EditMemoScreen extends ConsumerStatefulWidget {
  final String memoId;

  const EditMemoScreen({
    super.key,
    required this.memoId,
  });

  @override
  ConsumerState<EditMemoScreen> createState() => _EditMemoScreenState();
}

class _EditMemoScreenState extends ConsumerState<EditMemoScreen> {
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  
  bool _saving = false;
  bool _pinned = false;
  bool _archived = false;
  Memo? _memo;

  @override
  void initState() {
    super.initState();
    // Initialization is now handled in the build method
  }

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  // The initialization is now handled directly in the build method

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
      if (_memo != null) {
        final updatedMemo = _memo!.copyWith(
          content: _contentController.text.trim(),
          pinned: _pinned,
          state: _archived ? MemoState.archived : MemoState.normal,
        );
        
        // Use the provider to save the memo
        await ref.read(saveMemoProvider(widget.memoId))(updatedMemo);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Memo'),
        actions: [
          TextButton(
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
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Use the provider to get the memo data
    final memoAsync = ref.watch(editMemoProvider(widget.memoId));
    
    return memoAsync.when(
      data: (memo) {
        // Initialize the form with the memo data
        if (_memo == null || _memo!.id != memo.id) {
          // We need to update state with the new memo data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _memo = memo;
                _contentController.text = memo.content;
                _pinned = memo.pinned;
                _archived = memo.state == MemoState.archived;
              });
            }
          });
        }
        
        // Now show the form with current state
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
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
    );
  }
}
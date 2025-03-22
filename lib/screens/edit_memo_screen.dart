import 'package:flutter/material.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';

class EditMemoScreen extends StatefulWidget {
  final String memoId;

  const EditMemoScreen({
    super.key,
    required this.memoId,
  });

  @override
  State<EditMemoScreen> createState() => _EditMemoScreenState();
}

class _EditMemoScreenState extends State<EditMemoScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _contentController = TextEditingController();
  
  bool _loading = false;
  bool _saving = false;
  bool _pinned = false;
  bool _archived = false;
  String? _error;
  Memo? _memo;

  @override
  void initState() {
    super.initState();
    _fetchMemo();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _fetchMemo() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final memo = await _apiService.getMemo(widget.memoId);
      setState(() {
        _memo = memo;
        _contentController.text = memo.content;
        _pinned = memo.pinned;
        _archived = memo.state == MemoState.archived;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load memo: ${e.toString()}';
        _loading = false;
      });
    }
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
      if (_memo != null) {
        final updatedMemo = _memo!.copyWith(
          content: _contentController.text.trim(),
          pinned: _pinned,
          state: _archived ? MemoState.archived : MemoState.normal,
        );
        
        await _apiService.updateMemo(widget.memoId, updatedMemo);
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _saving = false;
      });
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
    if (_loading && _memo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

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
            decoration: const InputDecoration(
              hintText: 'Enter memo content...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            maxLines: 10,
            minLines: 5,
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
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/widgets/filter_menu.dart';
import 'package:flutter_memos/widgets/memo_card.dart';

class FilterItem {
  final String label;
  final String key;
  FilterItem({required this.label, required this.key});
}

class MemosScreen extends StatefulWidget {
  const MemosScreen({super.key});

  @override
  State<MemosScreen> createState() => _MemosScreenState();
}

class _MemosScreenState extends State<MemosScreen> {
  final ApiService _apiService = ApiService();
  List<Memo> _memos = [];
  bool _loading = false;
  String? _error;
  String _filterKey = 'inbox';

  final List<FilterItem> _filters = [
    FilterItem(label: 'Inbox', key: 'inbox'),
    FilterItem(label: 'Archive', key: 'archive'),
    FilterItem(label: 'All', key: 'all'),
    FilterItem(label: 'Prompts', key: 'prompts'),
    FilterItem(label: 'Ideas', key: 'ideas'),
    FilterItem(label: 'Work ideas', key: 'work'),
    FilterItem(label: 'Side Project Ideas', key: 'side'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchMemos();
  }

  Future<void> _fetchMemos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String? filter;
      String state = '';

      // Apply filter logic
      if (_filterKey == 'inbox') {
        state = 'NORMAL';
      } else if (_filterKey == 'archive') {
        state = 'ARCHIVED';
      } else if (_filterKey != 'all') {
        filter = 'tags=="$_filterKey"';
      }

      final memos = await _apiService.listMemos(
        filter: filter,
        state: state,
      );
      
      setState(() {
        _memos = memos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _handleArchiveMemo(String id) async {
    try {
      final memo = await _apiService.getMemo(id);
      final updatedMemo = memo.copyWith(
        pinned: false,
        state: MemoState.archived,
      );
      
      await _apiService.updateMemo(id, updatedMemo);
      _fetchMemos(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleDeleteMemo(String id) async {
    try {
      await _apiService.deleteMemo(id);
      _fetchMemos(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _navigateToMemoDetail(String id) {
    Navigator.pushNamed(
      context,
      '/memo-detail',
      arguments: {'memoId': id},
    ).then((_) => _fetchMemos());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memos'),
        actions: [
          FilterMenu(
            currentFilterKey: _filterKey,
            filters: _filters,
            onFilterSelected: (filter) {
              setState(() {
                _filterKey = filter.key;
              });
              _fetchMemos();
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/new-memo')
              .then((_) => _fetchMemos());
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_memos.isEmpty) {
      return const Center(
        child: Text(
          'No memos found.',
          style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMemos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _memos.length,
        itemBuilder: (context, index) {
          final memo = _memos[index];
          return Dismissible(
            key: Key(memo.id),
            background: Container(
              color: Colors.amber,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Text(
                'Archive',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onDismissed: (direction) {
              if (direction == DismissDirection.startToEnd) {
                _handleArchiveMemo(memo.id);
              } else {
                _handleDeleteMemo(memo.id);
              }
            },
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: const Text('Are you sure you want to delete this memo?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
              }
              return true;
            },
            child: MemoCard(
              content: memo.content,
              pinned: memo.pinned,
              onTap: () => _navigateToMemoDetail(memo.id),
            ),
          );
        },
      ),
    );
  }
}

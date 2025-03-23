import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_memos/utils/filter_presets.dart';
import 'package:flutter_memos/utils/memo_utils.dart';
import 'package:flutter_memos/widgets/filter_menu.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemosScreen extends StatefulWidget {
  const MemosScreen({super.key});

  @override
  State<MemosScreen> createState() => _MemosScreenState();
}

enum MemoSortMode { byUpdateTime, byCreateTime }

class _MemosScreenState extends State<MemosScreen> {
  final ApiService _apiService = ApiService();
  List<Memo> _memos = [];
  bool _loading = false;
  String? _error;
  String _filterKey = 'inbox';
  MemoSortMode _sortMode = MemoSortMode.byUpdateTime;
  String _currentFilterOption = 'all';
  final Set<String> _hiddenMemoIds = {};

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
    _loadLastFilterOption();
    _fetchMemos();
  }

  Future<void> _loadLastFilterOption() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastOption = prefs.getString('last_filter_option') ?? 'all';
      setState(() {
        _currentFilterOption = lastOption;
      });
    } catch (e) {
      // If there's an error, fall back to 'all'
      setState(() {
        _currentFilterOption = 'all';
      });
    }
  }

  Future<void> _saveLastFilterOption() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('last_filter_option', _currentFilterOption);
    } catch (e) {
      // Silently fail if we can't save the preference
    }
  }

  void _toggleHideMemo(String memoId) {
    setState(() {
      if (_hiddenMemoIds.contains(memoId)) {
        _hiddenMemoIds.remove(memoId);
      } else {
        _hiddenMemoIds.add(memoId);
      }
    });
  }

  void _showAllMemos() {
    setState(() {
      _hiddenMemoIds.clear();
    });
  }

  void _applyFilter(String filterOption) {
    setState(() {
      _currentFilterOption = filterOption;
      _hiddenMemoIds.clear(); // Reset hidden memos when changing filters
    });

    _saveLastFilterOption();
    _fetchMemos(); // This will apply both filter and the current sort mode
  }

  Future<void> _fetchMemos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String? filter;
      String state = '';
      
      // Determine sort field based on current sort mode
      // Using exact field names from API documentation
      final String sortField =
          _sortMode == MemoSortMode.byUpdateTime ? 'updateTime' : 'createTime';

      // Apply filter logic for category/visibility
      if (_filterKey == 'inbox') {
        state = 'NORMAL';
      } else if (_filterKey == 'archive') {
        state = 'ARCHIVED';
      } else if (_filterKey != 'all') {
        filter = 'tags=="$_filterKey"';
      }

      // Apply additional predefined filter
      String? predefinedFilter;
      switch (_currentFilterOption) {
        case 'today':
          predefinedFilter = FilterPresets.todayFilter();
          break;
        case 'created_today':
          predefinedFilter = FilterPresets.createdTodayFilter();
          break;
        case 'updated_today':
          predefinedFilter = FilterPresets.updatedTodayFilter();
          break;
        case 'this_week':
          predefinedFilter = FilterPresets.thisWeekFilter();
          break;
        case 'important':
          predefinedFilter = FilterPresets.importantFilter();
          break;
        case 'all':
        default:
          predefinedFilter = null; // No additional filter
      }

      // Combine filters if both are present
      if (filter != null && predefinedFilter != null) {
        filter = FilterBuilder.and([filter, predefinedFilter]);
      } else if (predefinedFilter != null) {
        filter = predefinedFilter;
      }

      print('Fetching memos with sort field: $sortField and filter: $filter');
      
      // Note: The API service now applies client-side sorting internally
      // since server-side sorting doesn't work reliably
      final memos = await _apiService.listMemos(
        parent: 'users/1', // Specify the current user
        filter: filter,
        state: state,
        sort: sortField,
        direction: 'DESC', // Always newest first
      );
      // Debug: Print info about the first few memos to see if sorting is working
      if (memos.isNotEmpty) {
        print('--- Memos after client-side sorting by $sortField ---');
        for (int i = 0; i < min(3, memos.length); i++) {
          print('[${i + 1}] ID: ${memos[i].id}');
          print(
            '    Content: ${memos[i].content.substring(0, min(20, memos[i].content.length))}...',
          );
          print('    createTime: ${memos[i].createTime}');
          print('    updateTime: ${memos[i].updateTime}');
          print('    displayTime: ${memos[i].displayTime}');
        }
      }
      
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _handleDeleteMemo(String id) async {
    try {
      await _apiService.deleteMemo(id);
      _fetchMemos(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _navigateToMemoDetail(String id) {
    Navigator.pushNamed(
      context,
      '/memo-detail',
      arguments: {'memoId': id},
    ).then((_) => _fetchMemos());
  }

  // Sorting is now entirely handled in the API service since server-side sorting is unreliable

  void _toggleSortMode() {
    setState(() {
      _sortMode =
          _sortMode == MemoSortMode.byUpdateTime
              ? MemoSortMode.byCreateTime
              : MemoSortMode.byUpdateTime;
    });
    
    // Refresh the memo list with new sort parameter
    _fetchMemos();
    
    // Show a snackbar to indicate the sort mode changed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sorting by ${_sortMode == MemoSortMode.byUpdateTime ? 'update time' : 'creation time'} (newest first)',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _currentFilterOption == 'all',
              onSelected: (_) => _applyFilter('all'),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Today'),
              selected: _currentFilterOption == 'today',
              onSelected: (_) => _applyFilter('today'),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Created Today'),
              selected: _currentFilterOption == 'created_today',
              onSelected: (_) => _applyFilter('created_today'),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Updated Today'),
              selected: _currentFilterOption == 'updated_today',
              onSelected: (_) => _applyFilter('updated_today'),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('This Week'),
              selected: _currentFilterOption == 'this_week',
              onSelected: (_) => _applyFilter('this_week'),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Important'),
              selected: _currentFilterOption == 'important',
              onSelected: (_) => _applyFilter('important'),
            ),

            // Show All button for hidden memos
            if (_hiddenMemoIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: ActionChip(
                  label: Text('Show All (${_hiddenMemoIds.length} hidden)'),
                  onPressed: _showAllMemos,
                  avatar: const Icon(Icons.visibility, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memos'),
        actions: [
          // Sort toggle button with more descriptive text
          TextButton.icon(
            icon: Icon(
              _sortMode == MemoSortMode.byUpdateTime
                  ? Icons.update
                  : Icons.calendar_today,
              size: 20,
            ),
            label: Text(
              _sortMode == MemoSortMode.byUpdateTime
                  ? 'Sort by: Updated'
                  : 'Sort by: Created',
              style: const TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              foregroundColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Colors.grey[100],
            ),
            onPressed: () {
              _toggleSortMode();
            },
          ),
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
          Navigator.pushNamed(context, '/new-memo').then((_) => _fetchMemos());
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

    // Filter out hidden memos
    final visibleMemos =
        _memos.where((memo) => !_hiddenMemoIds.contains(memo.id)).toList();

    if (visibleMemos.isEmpty) {
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

    return Column(
      children: [
        // Filter chips for predefined filters
        _buildFilterChips(),
        
        // Improved sort indicator with clearer messaging
        Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sorting by ${_sortMode == MemoSortMode.byUpdateTime ? 'last updated' : 'creation date'} (newest first)',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 12,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Client-side sorting is used (server has limited sort support)',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  _sortMode == MemoSortMode.byUpdateTime
                      ? Icons.update
                      : Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchMemos,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: visibleMemos.length,
              itemBuilder: (context, index) {
                final memo = visibleMemos[index];
                return Dismissible(
                  key: Key(memo.id),
                  background: Container(
                    color: Colors.orange,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 16.0),
                    child: const Icon(
                      Icons.visibility_off,
                      color: Colors.white,
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
                    if (direction == DismissDirection.endToStart) {
                      _handleDeleteMemo(memo.id);
                    }
                  },
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      // Hide memo
                      _toggleHideMemo(memo.id);
                      return false; // Don't remove from list
                    } else if (direction == DismissDirection.endToStart) {
                      // Delete memo
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: const Text(
                              'Are you sure you want to delete this memo?',
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                    return false;
                  },
                  child: MemoCard(
                    content: memo.content,
                    pinned: memo.pinned,
                    createdAt: memo.createTime,
                    updatedAt: memo.updateTime,
                    showTimeStamps: true,
                    // Display relevant timestamp based on sort mode
                    highlightTimestamp:
                        _sortMode == MemoSortMode.byUpdateTime
                            ? MemoUtils.formatTimestamp(memo.updateTime)
                            : MemoUtils.formatTimestamp(memo.createTime),
                    timestampType:
                        _sortMode == MemoSortMode.byUpdateTime
                            ? 'Updated'
                            : 'Created',
                    onTap: () => _navigateToMemoDetail(memo.id),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

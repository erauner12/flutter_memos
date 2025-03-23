import 'package:flutter/material.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_memos/widgets/memo_card.dart';

class FilterDemoScreen extends StatefulWidget {
  const FilterDemoScreen({super.key});

  @override
  State<FilterDemoScreen> createState() => _FilterDemoScreenState();
}

class _FilterDemoScreenState extends State<FilterDemoScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _contentSearchController = TextEditingController();
  final TextEditingController _customFilterController = TextEditingController();
  
  List<Memo> _memos = [];
  bool _loading = false;
  String? _error;
  
  String _selectedVisibility = 'PUBLIC';
  String _selectedTimeframe = 'today';
  final List<String> _selectedTags = [];
  
  // Sample tags - in a real app, you'd fetch these from the server
  final List<String> _availableTags = [
    'work', 'personal', 'important', 'idea', 'todo', 'test'
  ];
  
  @override
  void initState() {
    super.initState();
    _fetchMemos();
  }
  
  @override
  void dispose() {
    _contentSearchController.dispose();
    _customFilterController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchMemos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      // Build filter
      String? filter;
      
      // If the user entered a custom filter, use that
      if (_customFilterController.text.isNotEmpty) {
        filter = _customFilterController.text;
      } else {
        // Otherwise, use the FilterBuilder to construct a filter
        final List<String> filterParts = [];
        
        // Add visibility filter
        filterParts.add(FilterBuilder.byVisibility(_selectedVisibility));
        
        // Add tags filter if any are selected
        if (_selectedTags.isNotEmpty) {
          filterParts.add(FilterBuilder.byTags(_selectedTags));
        }
        
        // Add content search if provided
        if (_contentSearchController.text.isNotEmpty) {
          filterParts.add(FilterBuilder.byContent(_contentSearchController.text));
        }
        
        // Combine filters with AND
        filter = FilterBuilder.and(filterParts);
      }
      
      // Fetch memos with the constructed filter
      final memos = await _apiService.listMemos(
        parent: 'users/1',
        // We can either pass the constructed filter directly
        filter: filter,
        // Or we can use the convenience parameters for time filtering
        timeExpression: _selectedTimeframe,
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterControls(),
          Expanded(
            child: _buildResultsList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterControls() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Visibility filter
            Row(
              children: [
                const Text('Visibility: ', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedVisibility,
                  onChanged: (value) {
                    setState(() {
                      _selectedVisibility = value!;
                    });
                  },
                  items: ['PUBLIC', 'PROTECTED', 'PRIVATE'].map((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            
            // Tags filter
            const SizedBox(height: 8),
            const Text('Tags:', style: TextStyle(fontWeight: FontWeight.w500)),
            Wrap(
              spacing: 8,
              children: _availableTags.map((tag) {
                final selected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            
            // Content search
            const SizedBox(height: 8),
            TextField(
              controller: _contentSearchController,
              decoration: const InputDecoration(
                labelText: 'Content Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            
            // Timeframe filter
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Timeframe: ', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedTimeframe,
                  onChanged: (value) {
                    setState(() {
                      _selectedTimeframe = value!;
                    });
                  },
                  items: [
                    'today', 'yesterday', 'this week', 'last week',
                    'this month', 'last month', 'all time'
                  ].map((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            
            // Advanced filter input
            const SizedBox(height: 16),
            const Text('Advanced: Custom Filter', style: TextStyle(fontWeight: FontWeight.w500)),
            TextField(
              controller: _customFilterController,
              decoration: const InputDecoration(
                labelText: 'Custom CEL Filter Expression',
                hintText: 'e.g., tag in ["work"] && visibility == "PUBLIC"',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'If provided, this will override the filters above',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            
            // Filter button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _fetchMemos,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultsList() {
    if (_loading && _memos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    if (_memos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No memos found matching the filters',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _memos.length,
      itemBuilder: (context, index) {
        final memo = _memos[index];
        return MemoCard(
          content: memo.content,
          pinned: memo.pinned,
          createdAt: memo.createTime,
          updatedAt: memo.updateTime,
          showTimeStamps: true,
          onTap: () {
            // Navigate to memo detail or show in dialog
            _showMemoDetailDialog(memo);
          },
        );
      },
    );
  }
  
  void _showMemoDetailDialog(Memo memo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Memo Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${memo.id}'),
              const SizedBox(height: 8),
              Text('Visibility: ${memo.visibility}'),
              const SizedBox(height: 8),
              Text('Created: ${memo.createTime}'),
              const SizedBox(height: 8),
              Text('Updated: ${memo.updateTime}'),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Content:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(memo.content),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Filters'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter Syntax',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('Filter memos using CEL expressions:'),
              const SizedBox(height: 4),
              Text('• tag in ["tag1", "tag2"]', style: TextStyle(fontFamily: 'monospace')),
              Text('• visibility == "PUBLIC"', style: TextStyle(fontFamily: 'monospace')),
              Text('• content.contains("search")', style: TextStyle(fontFamily: 'monospace')),
              Text('• create_time > "2023-01-01T00:00:00Z"', style: TextStyle(fontFamily: 'monospace')),
              const SizedBox(height: 8),
              const Text('Use logical operators to combine filters:'),
              const SizedBox(height: 4),
              Text('• AND: condition1 && condition2', style: TextStyle(fontFamily: 'monospace')),
              Text('• OR: condition1 || condition2', style: TextStyle(fontFamily: 'monospace')),
              Text('• NOT: !condition', style: TextStyle(fontFamily: 'monospace')),
              const SizedBox(height: 16),
              const Text(
                'Examples',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text('tag in ["work"] && visibility == "PUBLIC"'),
              const SizedBox(height: 4),
              Text('content.contains("meeting") || tag in ["important"]'),
              const SizedBox(height: 4),
              Text('create_time > "2023-01-01T00:00:00Z" && !content.contains("obsolete")'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

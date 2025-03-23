import 'package:flutter/material.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers for filter demo state
final filterDemoVisibilityProvider = StateProvider<String>((ref) => 'PUBLIC');
final filterDemoTagsProvider = StateProvider<List<String>>((ref) => []);
final filterDemoTimeframeProvider = StateProvider<String>((ref) => 'today');
final filterDemoSearchProvider = StateProvider<String>((ref) => '');
final filterDemoCustomFilterProvider = StateProvider<String>((ref) => '');

// Provider for filtered memos
final filteredMemosProvider = FutureProvider<List<Memo>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final visibility = ref.watch(filterDemoVisibilityProvider);
  final tags = ref.watch(filterDemoTagsProvider);
  final timeframe = ref.watch(filterDemoTimeframeProvider);
  final search = ref.watch(filterDemoSearchProvider);
  final customFilter = ref.watch(filterDemoCustomFilterProvider);

  // Build filter
  String? filter;

  // If custom filter is provided, use that
  if (customFilter.isNotEmpty) {
    filter = customFilter;
  } else {
    // Otherwise, use FilterBuilder to construct a filter
    final List<String> filterParts = [];

    // Add visibility filter
    filterParts.add(FilterBuilder.byVisibility(visibility));

    // Add tags filter if any are selected
    if (tags.isNotEmpty) {
      filterParts.add(FilterBuilder.byTags(tags));
    }

    // Add content search if provided
    if (search.isNotEmpty) {
      filterParts.add(FilterBuilder.byContent(search));
    }

    // Combine filters with AND
    filter = FilterBuilder.and(filterParts);
  }

  // Fetch memos with the constructed filter
  return apiService.listMemos(
    parent: 'users/1',
    filter: filter,
    timeExpression: timeframe,
  );
});

class FilterDemoScreen extends ConsumerStatefulWidget {
  const FilterDemoScreen({super.key});

  @override
  ConsumerState<FilterDemoScreen> createState() => _FilterDemoScreenState();
}

class _FilterDemoScreenState extends ConsumerState<FilterDemoScreen> {
  final TextEditingController _contentSearchController = TextEditingController();
  final TextEditingController _customFilterController = TextEditingController();
  
  // Sample tags - in a real app, you'd fetch these from the server
  final List<String> _availableTags = [
    'work',
    'personal',
    'important',
    'idea',
    'todo',
    'test',
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with values from providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Delay controller initialization until after the first frame
      // to avoid any potential race conditions with providers
      if (mounted) {
        final searchContent = ref.read(filterDemoSearchProvider);
        final customFilter = ref.read(filterDemoCustomFilterProvider);

        // Only set text if different to avoid unnecessary text change events
        if (searchContent.isNotEmpty &&
            _contentSearchController.text != searchContent) {
          _contentSearchController.text = searchContent;
        }

        if (customFilter.isNotEmpty &&
            _customFilterController.text != customFilter) {
          _customFilterController.text = customFilter;
        }

        // Listen for changes to update the providers
        _contentSearchController.addListener(_updateSearchProvider);
        _customFilterController.addListener(_updateCustomFilterProvider);
      }
    });
  }
  
  @override
  void dispose() {
    _contentSearchController.removeListener(_updateSearchProvider);
    _customFilterController.removeListener(_updateCustomFilterProvider);
    _contentSearchController.dispose();
    _customFilterController.dispose();
    super.dispose();
  }
  
  void _updateSearchProvider() {
    // Protect against updating provider during build phase
    if (!mounted) return;

    final newValue = _contentSearchController.text;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(filterDemoSearchProvider) != newValue) {
        ref.read(filterDemoSearchProvider.notifier).state = newValue;
      }
    });
  }
  
  void _updateCustomFilterProvider() {
    // Protect against updating provider during build phase
    if (!mounted) return;

    final newValue = _customFilterController.text;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(filterDemoCustomFilterProvider) != newValue) {
        ref.read(filterDemoCustomFilterProvider.notifier).state = newValue;
      }
    });
  }
  
  void _applyFilters() {
    // This will cause the provider to rebuild and fetch new data
    ref.invalidate(filteredMemosProvider);
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
    final selectedVisibility = ref.watch(filterDemoVisibilityProvider);
    final selectedTags = ref.watch(filterDemoTagsProvider);
    final selectedTimeframe = ref.watch(filterDemoTimeframeProvider);
    
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
                  value: selectedVisibility,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(filterDemoVisibilityProvider.notifier).state =
                          value;
                    }
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
                    final selected = selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (value) {
                        final newTags = List<String>.from(selectedTags);
                        if (value) {
                          newTags.add(tag);
                        } else {
                          newTags.remove(tag);
                        }
                        ref.read(filterDemoTagsProvider.notifier).state =
                            newTags;
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
                  value: selectedTimeframe,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(filterDemoTimeframeProvider.notifier).state =
                          value;
                    }
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
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultsList() {
    final memosAsync = ref.watch(filteredMemosProvider);
    
    return memosAsync.when(
      data: (memos) {
        if (memos.isEmpty) {
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
          itemCount: memos.length,
          itemBuilder: (context, index) {
            final memo = memos[index];
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
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ),
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
            content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
                  Text(
                'Filter Syntax',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
                  SizedBox(height: 8),
                  Text('Filter memos using CEL expressions:'),
                  SizedBox(height: 4),
              Text('• tag in ["tag1", "tag2"]', style: TextStyle(fontFamily: 'monospace')),
              Text('• visibility == "PUBLIC"', style: TextStyle(fontFamily: 'monospace')),
              Text('• content.contains("search")', style: TextStyle(fontFamily: 'monospace')),
              Text('• create_time > "2023-01-01T00:00:00Z"', style: TextStyle(fontFamily: 'monospace')),
                  SizedBox(height: 8),
                  Text('Use logical operators to combine filters:'),
                  SizedBox(height: 4),
              Text('• AND: condition1 && condition2', style: TextStyle(fontFamily: 'monospace')),
              Text('• OR: condition1 || condition2', style: TextStyle(fontFamily: 'monospace')),
              Text('• NOT: !condition', style: TextStyle(fontFamily: 'monospace')),
                  SizedBox(height: 16),
                  Text(
                'Examples',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
                  SizedBox(height: 8),
              Text('tag in ["work"] && visibility == "PUBLIC"'),
                  SizedBox(height: 4),
              Text('content.contains("meeting") || tag in ["important"]'),
                  SizedBox(height: 4),
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

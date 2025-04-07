import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_memos/widgets/memo_card.dart'; // Assuming MemoCard is migrated
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
  // final timeframe = ref.watch(filterDemoTimeframeProvider); // Timeframe not used in API call?
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
  // Note: timeExpression (timeframe) seems missing from the API call here
  final response = await apiService.listMemos(
    parent: 'users/1',
    filter: filter,
    // timeExpression: timeframe, // Add this back if needed by API
  );
  return response.memos;
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
      if (mounted) {
        final searchContent = ref.read(filterDemoSearchProvider);
        final customFilter = ref.read(filterDemoCustomFilterProvider);

        if (searchContent.isNotEmpty &&
            _contentSearchController.text != searchContent) {
          _contentSearchController.text = searchContent;
        }
        if (customFilter.isNotEmpty &&
            _customFilterController.text != customFilter) {
          _customFilterController.text = customFilter;
        }

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
    if (!mounted) return;
    final newValue = _contentSearchController.text;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(filterDemoSearchProvider) != newValue) {
        ref.read(filterDemoSearchProvider.notifier).state = newValue;
      }
    });
  }

  void _updateCustomFilterProvider() {
    if (!mounted) return;
    final newValue = _customFilterController.text;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(filterDemoCustomFilterProvider) != newValue) {
        ref.read(filterDemoCustomFilterProvider.notifier).state = newValue;
      }
    });
  }

  void _applyFilters() {
    ref.invalidate(filteredMemosProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Use CupertinoPageScaffold and CupertinoNavigationBar
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Filter Demo'),
        transitionBetweenRoutes: false,
        trailing: CupertinoButton(
          // Use CupertinoButton for info
          padding: EdgeInsets.zero,
          onPressed: _showInfoDialog,
          child: const Icon(CupertinoIcons.info),
        ),
      ),
      child: SafeArea(
        // Add SafeArea
        child: Column(
          children: [
            _buildFilterControls(),
            Expanded(child: _buildResultsList()),
          ],
        ),
      ),
    );
  }

  // Replace Card with CupertinoListSection
  Widget _buildFilterControls() {
    final selectedVisibility = ref.watch(filterDemoVisibilityProvider);
    final selectedTags = ref.watch(filterDemoTagsProvider);
    // final selectedTimeframe = ref.watch(filterDemoTimeframeProvider); // Timeframe not used?

    return CupertinoListSection.insetGrouped(
      header: const Text('FILTER OPTIONS'),
      children: [
        // Visibility filter - Use CupertinoPicker or SegmentedControl
        _buildPickerRow(
          context: context,
          label: 'Visibility',
          options: ['PUBLIC', 'PROTECTED', 'PRIVATE'],
          currentValue: selectedVisibility,
          onChanged: (value) {
            if (value != null) {
              ref.read(filterDemoVisibilityProvider.notifier).state = value;
            }
          },
        ),

        // Tags filter - Use Wrap with styled CupertinoButtons
        CupertinoListTile(
          title: const Text('Tags'),
          subtitle: Wrap(
            spacing: 8,
            runSpacing: 4,
            children:
                _availableTags.map((tag) {
                  final selected = selectedTags.contains(tag);
                  // Replace FilterChip with styled CupertinoButton
                  return CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minSize: 0,
                    color:
                        selected
                            ? CupertinoTheme.of(context).primaryColor
                            : CupertinoColors.secondarySystemFill.resolveFrom(
                              context,
                            ),
                    onPressed: () {
                      final newTags = List<String>.from(selectedTags);
                      if (!selected) {
                        newTags.add(tag);
                      } else {
                        newTags.remove(tag);
                      }
                      ref.read(filterDemoTagsProvider.notifier).state = newTags;
                    },
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            selected
                                ? CupertinoColors.white
                                : CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),

        // Content search - Use CupertinoSearchTextField
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
          child: CupertinoSearchTextField(
            controller: _contentSearchController,
            placeholder: 'Content Search',
          ),
        ),

        // Timeframe filter - Use CupertinoPicker or SegmentedControl
        // _buildPickerRow(
        //   context: context,
        //   label: 'Timeframe',
        //   options: ['today', 'yesterday', 'this week', 'last week', 'this month', 'last month', 'all time'],
        //   currentValue: selectedTimeframe,
        //   onChanged: (value) {
        //     if (value != null) {
        //       ref.read(filterDemoTimeframeProvider.notifier).state = value;
        //     }
        //   },
        // ),

        // Advanced filter input - Use CupertinoTextField
        CupertinoListTile(
          title: const Text('Advanced: Custom Filter'),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: CupertinoTextField(
              controller: _customFilterController,
              placeholder: 'Custom CEL Filter Expression',
              minLines: 1,
              maxLines: 3,
              keyboardType: TextInputType.text,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CupertinoColors.systemFill.resolveFrom(context),
                border: Border.all(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(15.0, 4.0, 15.0, 8.0),
          child: Text(
            'If provided, this will override the filters above',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),

        // Filter button - Use CupertinoButton.filled
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _applyFilters,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Text('Apply Filters'),
            ),
          ),
        ),
      ],
    );
  }

  // Helper for Picker Rows (replaces Dropdown)
  Widget _buildPickerRow({
    required BuildContext context,
    required String label,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String?> onChanged,
  }) {
    return CupertinoListTile(
      title: Text(label),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: Text(currentValue),
        onPressed: () {
          _showPicker(context, options, currentValue, onChanged);
        },
      ),
    );
  }

  // Function to show CupertinoPicker
  void _showPicker(
    BuildContext context,
    List<String> options,
    String currentValue,
    ValueChanged<String?> onChanged,
  ) {
    final FixedExtentScrollController scrollController =
        FixedExtentScrollController(initialItem: options.indexOf(currentValue));

    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => Container(
            height: 216,
            padding: const EdgeInsets.only(top: 6.0),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: CupertinoPicker(
                scrollController: scrollController,
                magnification: 1.22,
                squeeze: 1.2,
                useMagnifier: true,
                itemExtent: 32.0,
                onSelectedItemChanged: (int selectedIndex) {
                  onChanged(options[selectedIndex]);
                },
                children: List<Widget>.generate(options.length, (int index) {
                  return Center(child: Text(options[index]));
                }),
              ),
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
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0), // Add padding around the list
          itemCount: memos.length,
          itemBuilder: (context, index) {
            final memo = memos[index];
            // Assuming MemoCard is migrated
            return Padding(
              // Add padding below each item
              padding: const EdgeInsets.only(bottom: 12.0),
              child: MemoCard(
                id: memo.id,
                content: memo.content,
                pinned: memo.pinned,
                updatedAt: memo.updateTime,
                showTimeStamps: true,
                onTap: () {
                  _showMemoDetailDialog(memo);
                },
              ),
            );
          },
        );
      },
      loading:
          () => const Center(
            child: CupertinoActivityIndicator(),
          ), // Use CupertinoActivityIndicator
      error:
          (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: $error',
                style: const TextStyle(color: CupertinoColors.systemRed),
                textAlign: TextAlign.center,
              ),
            ),
          ),
    );
  }

  // Use CupertinoAlertDialog
  void _showMemoDetailDialog(Memo memo) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
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
                  Container(
                    height: 0.5,
                    color: CupertinoColors.separator,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ), // Use Container as a divider for Cupertino
              const SizedBox(height: 8),
              const Text('Content:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(memo.content),
            ],
          ),
        ),
        actions: [
              CupertinoDialogAction(
                // Use CupertinoDialogAction
                isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Use CupertinoAlertDialog
  void _showInfoDialog() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
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
              CupertinoDialogAction(
                // Use CupertinoDialogAction
                isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

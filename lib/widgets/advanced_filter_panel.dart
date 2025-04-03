import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_memos/utils/filter_presets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Advanced filter panel that allows users to create complex filters
/// through both a visual interface and raw CEL expressions
class AdvancedFilterPanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  
  const AdvancedFilterPanel({
    super.key,
    required this.onClose,
  });
  
  @override
  ConsumerState<AdvancedFilterPanel> createState() => _AdvancedFilterPanelState();
}

class _AdvancedFilterPanelState extends ConsumerState<AdvancedFilterPanel> {
  // Controllers for filter inputs
  late TextEditingController _rawFilterController;
  
  // Local state for filter builder
  bool _useVisibilityFilter = false;
  String _selectedVisibility = 'PUBLIC';
  bool _useTagFilter = false;
  String _tagInput = '';
  List<String> _selectedTags = [];
  bool _useContentFilter = false;
  String _contentFilter = '';
  bool _useTimeFilter = false;
  String _selectedTimeRange = 'today';
  
  // State for syntax validation
  String _syntaxError = '';
  bool _isValid = true;
  
  // Currently selected filter preset
  String? _selectedPreset;
  
  @override
  void initState() {
    super.initState();
    _rawFilterController = TextEditingController(
      text: ref.read(rawCelFilterProvider)
    );
    _rawFilterController.addListener(_validateFilter);
    
    // Initialize filter settings from current filter if possible
    _initializeFromCurrentFilter();
  }
  
  void _initializeFromCurrentFilter() {
    final currentFilter = ref.read(rawCelFilterProvider);
    if (currentFilter.isEmpty) return;
    
    // This is a simplified parsing approach
    // In a real app, you'd want a more robust CEL parser
    try {
      // Check for visibility filter
      if (currentFilter.contains('visibility ==') ||
          currentFilter.contains('visibility in')) {
        _useVisibilityFilter = true;
        
        // Try to extract value
        if (currentFilter.contains('"PUBLIC"')) {
          _selectedVisibility = 'PUBLIC';
        } else if (currentFilter.contains('"PROTECTED"')) {
          _selectedVisibility = 'PROTECTED';
        } else if (currentFilter.contains('"PRIVATE"')) {
          _selectedVisibility = 'PRIVATE';
        }
      }
      
      // Check for tag filter
      if (currentFilter.contains('tag in')) {
        _useTagFilter = true;
        
        // Try to extract tags - simplistic approach
        final tagMatch = RegExp(r'tag in \[(.*?)\]').firstMatch(currentFilter);
        if (tagMatch != null && tagMatch.group(1) != null) {
          final tagString = tagMatch.group(1)!;
          _selectedTags = tagString
              .split(',')
              .map((tag) => tag.trim().replaceAll('"', ''))
              .where((tag) => tag.isNotEmpty)
              .toList();
        }
      }
      
      // Check for content filter
      if (currentFilter.contains('content.contains')) {
        _useContentFilter = true;
        
        // Try to extract content
        final contentMatch = RegExp(r'content.contains\("(.*?)"\)').firstMatch(currentFilter);
        if (contentMatch != null && contentMatch.group(1) != null) {
          _contentFilter = contentMatch.group(1)!;
        }
      }
      
      // Check for time filter - this is a simplistic approach
      if (currentFilter.contains('create_time') || currentFilter.contains('update_time')) {
        _useTimeFilter = true;
        
        // Try to determine time range based on common patterns
        if (currentFilter.contains('today')) {
          _selectedTimeRange = 'today';
        } else if (currentFilter.contains('this week')) {
          _selectedTimeRange = 'this_week';
        } else if (currentFilter.contains('this month')) {
          _selectedTimeRange = 'this_month';
        }
      }
    } catch (e) {
      // If parsing fails, we just keep the default values
      if (kDebugMode) {
        print('[AdvancedFilterPanel] Error parsing filter: $e');
      }
    }
  }
  
  @override
  void dispose() {
    _rawFilterController.dispose();
    super.dispose();
  }
  
  void _validateFilter() {
    final filter = _rawFilterController.text;
    if (filter.isEmpty) {
      setState(() {
        _syntaxError = '';
        _isValid = true;
      });
      return;
    }
    
    // Use the filter builder's validation
    final error = FilterBuilder.validateCelExpression(filter);
    setState(() {
      _syntaxError = error;
      _isValid = error.isEmpty;
    });
  }
  
  void _buildAndApplyFilter() {
    // Reset any selected preset when building a custom filter
    _selectedPreset = null;
    
    List<String> filterParts = [];
    
    // Add visibility filter if enabled
    if (_useVisibilityFilter) {
      filterParts.add(FilterBuilder.byVisibility(_selectedVisibility));
    }
    
    // Add tags filter if enabled
    if (_useTagFilter && _selectedTags.isNotEmpty) {
      filterParts.add(FilterBuilder.byTags(_selectedTags));
    }
    
    // Add content filter if enabled
    if (_useContentFilter && _contentFilter.isNotEmpty) {
      filterParts.add(FilterBuilder.byContent(_contentFilter));
    }
    
    // Add time filter if enabled
    if (_useTimeFilter) {
      switch (_selectedTimeRange) {
        case 'today':
          filterParts.add(FilterPresets.todayFilter());
          break;
        case 'this_week':
          filterParts.add(FilterPresets.thisWeekFilter());
          break;
        case 'this_month':
          // Add a this month filter
          final now = DateTime.now();
          final startOfMonth = DateTime(now.year, now.month, 1);
          final endOfMonth = (now.month < 12)
              ? DateTime(now.year, now.month + 1, 0)
              : DateTime(now.year + 1, 1, 0);
          filterParts.add(FilterBuilder.byCreateTimeRange(startOfMonth, endOfMonth));
          break;
        default:
          // Use today as fallback
          filterParts.add(FilterPresets.todayFilter());
      }
    }
    
    // Build the combined filter
    String finalFilter = '';
    if (filterParts.isNotEmpty) {
      finalFilter = FilterBuilder.and(filterParts);
    }
    
    // Update the raw filter display
    _rawFilterController.text = finalFilter;
    
    // Apply the filter
    _applyFilter(finalFilter);
  }
  
  void _applyFilter(String filter) {
    // Update the raw filter provider
    ref.read(rawCelFilterProvider.notifier).state = filter;
    
    // Refresh memos to apply the filter
    ref.read(memosNotifierProvider.notifier).refresh();
    
    // Show a confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Filter applied: ${filter.isEmpty ? 'All Memos' : 'Custom Filter'}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _applyPreset(String presetKey) {
    String filter = '';
    
    setState(() {
      _selectedPreset = presetKey;
    });
    
    // Apply the selected preset
    switch (presetKey) {
      case 'today':
        filter = FilterPresets.todayFilter();
        break;
      case 'created_today':
        filter = FilterPresets.createdTodayFilter();
        break;
      case 'updated_today':
        filter = FilterPresets.updatedTodayFilter();
        break;
      case 'this_week':
        filter = FilterPresets.thisWeekFilter();
        break;
      case 'important':
        filter = FilterPresets.importantFilter();
        break;
      case 'untagged':
        filter = FilterPresets.untaggedFilter();
        break;
      case 'tagged':
        filter = FilterPresets.taggedFilter();
        break;
      case 'public':
        filter = 'visibility == "PUBLIC"';
        break;
      case 'private':
        filter = 'visibility == "PRIVATE"';
        break;
    }
    
    // Update the raw filter text
    _rawFilterController.text = filter;
    
    // Apply the filter
    _applyFilter(filter);
  }
  
  void _resetFilters() {
    setState(() {
      _useVisibilityFilter = false;
      _selectedVisibility = 'PUBLIC';
      _useTagFilter = false;
      _tagInput = '';
      _selectedTags = [];
      _useContentFilter = false;
      _contentFilter = '';
      _useTimeFilter = false;
      _selectedTimeRange = 'today';
      _selectedPreset = null;
    });
    
    // Clear the raw filter
    _rawFilterController.text = '';
    
    // Apply empty filter
    _applyFilter('');
  }
  
  void _addTag() {
    if (_tagInput.isEmpty) return;
    
    setState(() {
      if (!_selectedTags.contains(_tagInput)) {
        _selectedTags.add(_tagInput);
      }
      _tagInput = '';
    });
  }
  
  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.all(0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Advanced Filter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                  tooltip: 'Close',
                ),
              ],
            ),
            
            const Divider(),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Filter presets section
                    const Text(
                      'Filter Presets',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPresetChip('today', 'Today'),
                        _buildPresetChip('created_today', 'Created Today'),
                        _buildPresetChip('updated_today', 'Updated Today'),
                        _buildPresetChip('this_week', 'This Week'),
                        _buildPresetChip('important', 'Important'),
                        _buildPresetChip('untagged', 'Untagged'),
                        _buildPresetChip('tagged', 'Tagged'),
                        _buildPresetChip('public', 'Public'),
                        _buildPresetChip('private', 'Private'),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Visual filter builder
                    const Text(
                      'Build a Filter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    // Visibility filter
                    SwitchListTile(
                      title: const Text('Filter by Visibility'),
                      subtitle: _useVisibilityFilter
                          ? Text('Visibility: $_selectedVisibility')
                          : const Text('Off'),
                      value: _useVisibilityFilter,
                      onChanged: (value) {
                        setState(() {
                          _useVisibilityFilter = value;
                        });
                      },
                    ),
                    
                    if (_useVisibilityFilter)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'PUBLIC',
                              label: Text('Public'),
                              icon: Icon(Icons.public),
                            ),
                            ButtonSegment(
                              value: 'PROTECTED',
                              label: Text('Protected'),
                              icon: Icon(Icons.shield),
                            ),
                            ButtonSegment(
                              value: 'PRIVATE',
                              label: Text('Private'),
                              icon: Icon(Icons.lock),
                            ),
                          ],
                          selected: {_selectedVisibility},
                          onSelectionChanged: (values) {
                            if (values.isNotEmpty) {
                              setState(() {
                                _selectedVisibility = values.first;
                              });
                            }
                          },
                        ),
                      ),
                      
                    const SizedBox(height: 8),
                    
                    // Tag filter
                    SwitchListTile(
                      title: const Text('Filter by Tags'),
                      subtitle: _useTagFilter
                          ? Text('${_selectedTags.isEmpty ? "No" : _selectedTags.length} tags selected')
                          : const Text('Off'),
                      value: _useTagFilter,
                      onChanged: (value) {
                        setState(() {
                          _useTagFilter = value;
                        });
                      },
                    ),
                    
                    if (_useTagFilter)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      hintText: 'Enter a tag',
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _tagInput = value;
                                      });
                                    },
                                    onSubmitted: (_) => _addTag(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _addTag,
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 0,
                              children: _selectedTags.map((tag) => Chip(
                                label: Text(tag),
                                onDeleted: () => _removeTag(tag),
                                backgroundColor: isDarkMode
                                    ? Colors.blueGrey.shade700
                                    : Colors.blueGrey.shade100,
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Content filter
                    SwitchListTile(
                      title: const Text('Filter by Content'),
                      subtitle: _useContentFilter
                          ? (_contentFilter.isEmpty
                              ? const Text('No content filter specified')
                              : Text('Content contains: $_contentFilter'))
                          : const Text('Off'),
                      value: _useContentFilter,
                      onChanged: (value) {
                        setState(() {
                          _useContentFilter = value;
                        });
                      },
                    ),
                    
                    if (_useContentFilter)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Content contains...',
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _contentFilter = value;
                            });
                          },
                        ),
                      ),
                      
                    const SizedBox(height: 8),
                    
                    // Time filter
                    SwitchListTile(
                      title: const Text('Filter by Time'),
                      subtitle: _useTimeFilter
                          ? Text('Time range: ${_selectedTimeRange.replaceAll('_', ' ').capitalizeFirstLetter()}')
                          : const Text('Off'),
                      value: _useTimeFilter,
                      onChanged: (value) {
                        setState(() {
                          _useTimeFilter = value;
                        });
                      },
                    ),
                    
                    if (_useTimeFilter)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            isDense: true,
                          ),
                          value: _selectedTimeRange,
                          items: const [
                            DropdownMenuItem(
                              value: 'today',
                              child: Text('Today'),
                            ),
                            DropdownMenuItem(
                              value: 'this_week',
                              child: Text('This Week'),
                            ),
                            DropdownMenuItem(
                              value: 'this_month',
                              child: Text('This Month'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedTimeRange = value;
                              });
                            }
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Apply and Reset buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _buildAndApplyFilter,
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Apply Filter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: _resetFilters,
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Reset'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Raw CEL filter editor
                    const Text(
                      'Raw CEL Filter Expression',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isValid
                              ? (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400)
                              : Colors.red,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _rawFilterController,
                            decoration: const InputDecoration(
                              hintText: 'Enter a CEL filter expression...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: isDarkMode ? Colors.amber.shade200 : Colors.amber.shade800,
                            ),
                            maxLines: 4,
                          ),
                          if (_syntaxError.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _syntaxError,
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _applyFilter(_rawFilterController.text),
                        icon: const Icon(Icons.code),
                        label: const Text('Apply Raw Filter'),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Help section
                    ExpansionTile(
                      title: const Text('Filter Syntax Help'),
                      initiallyExpanded: false,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Common Filter Patterns:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              _buildCodeExample('tag in ["work", "important"]'),
                              _buildCodeExample('visibility == "PUBLIC"'),
                              _buildCodeExample('content.contains("meeting")'),
                              _buildCodeExample('create_time > "2023-01-01T00:00:00Z"'),
                              
                              const SizedBox(height: 16),
                              const Text(
                                'Combine with && (AND) or || (OR):',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              _buildCodeExample('tag in ["work"] && visibility == "PUBLIC"'),
                              _buildCodeExample('content.contains("urgent") || content.contains("important")'),
                              
                              const SizedBox(height: 16),
                              const Text(
                                'Negate with ! (NOT):',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              _buildCodeExample('!content.contains("draft")'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPresetChip(String key, String label) {
    final isSelected = _selectedPreset == key;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _applyPreset(key);
        } else if (isSelected) {
          // Deselect this preset
          setState(() {
            _selectedPreset = null;
          });
        }
      },
      backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
      selectedColor: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade100,
    );
  }
  
  Widget _buildCodeExample(String code) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          _rawFilterController.text = code;
          _applyFilter(code);
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            code,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

// Extension method to capitalize first letter
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
// No Material import needed anymore
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
    super.key, required this.onClose});

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
      text: ref.read(rawCelFilterProvider),
    );
    _rawFilterController.addListener(_validateFilter);

    // Initialize filter settings from current filter if possible
    _initializeFromCurrentFilter();
  }

  void _initializeFromCurrentFilter() {
    final currentFilter = ref.read(rawCelFilterProvider);
    if (currentFilter.isEmpty) return;

    try {
      if (currentFilter.contains('visibility ==') ||
          currentFilter.contains('visibility in')) {
        _useVisibilityFilter = true;

        if (currentFilter.contains('"PUBLIC"')) {
          _selectedVisibility = 'PUBLIC';
        } else if (currentFilter.contains('"PROTECTED"')) {
          _selectedVisibility = 'PROTECTED';
        } else if (currentFilter.contains('"PRIVATE"')) {
          _selectedVisibility = 'PRIVATE';
        }
      }

      if (currentFilter.contains('tag in')) {
        _useTagFilter = true;

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

      if (currentFilter.contains('content.contains')) {
        _useContentFilter = true;

        final contentMatch = RegExp(r'content.contains\("(.*?)"\)').firstMatch(currentFilter);
        if (contentMatch != null && contentMatch.group(1) != null) {
          _contentFilter = contentMatch.group(1)!;
        }
      }

      if (currentFilter.contains('create_time') || currentFilter.contains('update_time')) {
        _useTimeFilter = true;

        if (currentFilter.contains('today')) {
          _selectedTimeRange = 'today';
        } else if (currentFilter.contains('this week')) {
          _selectedTimeRange = 'this_week';
        } else if (currentFilter.contains('this month')) {
          _selectedTimeRange = 'this_month';
        }
      }
    } catch (e) {
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

    final error = FilterBuilder.validateCelExpressionDetailed(filter);
    setState(() {
      _syntaxError = error;
      _isValid = error.isEmpty;
    });
  }

  void _buildAndApplyFilter() {
    _selectedPreset = null;

    List<String> filterParts = [];

    if (_useVisibilityFilter) {
      filterParts.add(FilterBuilder.byVisibility(_selectedVisibility));
    }

    if (_useTagFilter && _selectedTags.isNotEmpty) {
      filterParts.add(FilterBuilder.byTags(_selectedTags));
    }

    if (_useContentFilter && _contentFilter.isNotEmpty) {
      filterParts.add(FilterBuilder.byContent(_contentFilter));
    }

    if (_useTimeFilter) {
      switch (_selectedTimeRange) {
        case 'today':
          filterParts.add(FilterPresets.todayFilter());
          break;
        case 'this_week':
          filterParts.add(FilterPresets.thisWeekFilter());
          break;
        case 'this_month':
          final now = DateTime.now();
          final startOfMonth = DateTime(now.year, now.month, 1);
          final endOfMonth = (now.month < 12)
              ? DateTime(now.year, now.month + 1, 0)
                  : DateTime(now.year + 1, 1, 0);
          filterParts.add(FilterBuilder.byCreateTimeRange(startOfMonth, endOfMonth));
          break;
        default:
          filterParts.add(FilterPresets.todayFilter());
      }
    }

    String finalFilter = '';
    if (filterParts.isNotEmpty) {
      finalFilter = FilterBuilder.and(filterParts);
    }

    _rawFilterController.text = finalFilter;

    _applyFilter(finalFilter);
  }

  void _applyFilter(String filter) {
    ref.read(rawCelFilterProvider.notifier).state = filter;

    ref.read(memosNotifierProvider.notifier).refresh();

    if (mounted) {
      // Replace SnackBar with CupertinoAlertDialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Filter Applied'),
          content: Text(filter.isEmpty ? 'Showing all memos.' : 'Custom filter is active.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  void _applyPreset(String presetKey) {
    String filter = '';

    setState(() {
      _selectedPreset = presetKey;
    });

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

    _rawFilterController.text = filter;

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

    _rawFilterController.text = '';

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
    // Use CupertinoTheme for styling
    final theme = CupertinoTheme.of(context);
    // final isDarkMode = theme.brightness == Brightness.dark; // Unused

    // Use Cupertino dynamic colors
    final Color panelBackgroundColor = theme.scaffoldBackgroundColor;
    final Color handleColor = CupertinoColors.systemGrey4.resolveFrom(context);
    final Color separatorColor = CupertinoColors.separator.resolveFrom(context);
    final TextStyle titleStyle = theme.textTheme.navTitleTextStyle.copyWith(fontSize: 18);
    final TextStyle sectionHeaderStyle = theme.textTheme.textStyle.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
    );
    final Color textFieldBackgroundColor = CupertinoColors.secondarySystemFill.resolveFrom(context);
    final Color errorColor = CupertinoColors.systemRed.resolveFrom(context);
    final Color validBorderColor = separatorColor;
    final Color invalidBorderColor = errorColor;

    return Container(
      decoration: BoxDecoration(
        color: panelBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        // Use system materials for background blur if desired (more advanced)
        // Or keep simple shadow
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withAlpha(38),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Advanced Filter', style: titleStyle),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: widget.onClose,
                  child: const Icon(CupertinoIcons.clear_thick_circled),
                ),
              ],
            ),
          ),
          // Separator
          Container(
            height: 0.5,
            color: separatorColor,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
          ),
          // Scrollable Content Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Filter Presets Section
                    Text('Filter Presets', style: sectionHeaderStyle),
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

                    // Build a Filter Section
                    Text('Build a Filter', style: sectionHeaderStyle),
                    // Visibility Filter
                    CupertinoListTile(
                      title: const Text('Filter by Visibility'),
                      trailing: CupertinoSwitch(
                        value: _useVisibilityFilter,
                        onChanged: (value) => setState(() => _useVisibilityFilter = value),
                      ),
                    ),
                    if (_useVisibilityFilter)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: CupertinoSegmentedControl<String>(
                          children: const {
                            'PUBLIC': Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Public')),
                            'PROTECTED': Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Protected')),
                            'PRIVATE': Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Private')),
                          },
                          groupValue: _selectedVisibility,
                          onValueChanged: (value) => setState(() => _selectedVisibility = value),
                        ),
                      ),
                    // Tag Filter
                    CupertinoListTile(
                      title: const Text('Filter by Tags'),
                      trailing: CupertinoSwitch(
                        value: _useTagFilter,
                        onChanged: (value) => setState(() => _useTagFilter = value),
                      ),
                    ),
                    if (_useTagFilter)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: CupertinoTextField(
                                    controller: TextEditingController(text: _tagInput) // Control input field
                                      ..selection = TextSelection.collapsed(offset: _tagInput.length),
                                    placeholder: 'Enter a tag',
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    clearButtonMode: OverlayVisibilityMode.editing,
                                    onChanged: (value) => setState(() => _tagInput = value),
                                    onSubmitted: (_) => _addTag(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CupertinoButton.filled(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  minSize: 0,
                                  onPressed: _addTag,
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _selectedTags.map((tag) => _buildTagChip(tag)).toList(),
                            ),
                          ],
                        ),
                      ),
                    // Content Filter
                    CupertinoListTile(
                      title: const Text('Filter by Content'),
                      trailing: CupertinoSwitch(
                        value: _useContentFilter,
                        onChanged: (value) => setState(() => _useContentFilter = value),
                      ),
                    ),
                    if (_useContentFilter)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: CupertinoTextField(
                          placeholder: 'Content contains...',
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          clearButtonMode: OverlayVisibilityMode.editing,
                          controller: TextEditingController(text: _contentFilter)
                            ..selection = TextSelection.collapsed(offset: _contentFilter.length),
                          onChanged: (value) => setState(() => _contentFilter = value),
                        ),
                      ),
                    // Time Filter
                    CupertinoListTile(
                      title: const Text('Filter by Time'),
                      trailing: CupertinoSwitch(
                        value: _useTimeFilter,
                        onChanged: (value) => setState(() => _useTimeFilter = value),
                      ),
                    ),
                    if (_useTimeFilter)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: CupertinoButton(
                          color: textFieldBackgroundColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          onPressed: () => _showTimeRangePicker(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedTimeRange.replaceAll('_', ' ').capitalizeFirstLetter(),
                                style: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
                              ),
                              const Icon(
                                CupertinoIcons.chevron_down,
                                size: 16,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Apply/Reset Builder Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoButton.filled(
                          onPressed: _buildAndApplyFilter,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.checkmark_alt),
                              SizedBox(width: 4),
                              Text('Apply Builder'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        CupertinoButton(
                          onPressed: _resetFilters,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.clear),
                              SizedBox(width: 4),
                              Text('Reset All'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Raw CEL Filter Section
                    Text('Raw CEL Filter Expression', style: sectionHeaderStyle),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: textFieldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isValid ? validBorderColor : invalidBorderColor,
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Use CupertinoTextField directly for raw input for now
                          // SyntaxHighlightTextField needs deeper refactoring
                          CupertinoTextField(
                            controller: _rawFilterController,
                            placeholder: 'Enter a CEL filter expression...',
                            keyboardType: TextInputType.multiline,
                            maxLines: 4,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                            decoration: BoxDecoration( // Remove default border
                              border: Border.all(color: CupertinoColors.transparent, width: 0),
                            ),
                            padding: EdgeInsets.zero, // Adjust padding as needed
                          ),
                          // SyntaxHighlightTextField( // Keep commented out until refactored
                          //   controller: _rawFilterController,
                          //   decoration: InputDecoration(
                          //     hintText: 'Enter a CEL filter expression...',
                          //     border: InputBorder.none,
                          //     isDense: true,
                          //     hintStyle: TextStyle(color: CupertinoColors.placeholderText.resolveFrom(context)),
                          //   ),
                          //   style: TextStyle(
                          //     fontFamily: 'monospace',
                          //     fontSize: 14,
                          //     color: CupertinoColors.label.resolveFrom(context),
                          //   ),
                          //   maxLines: 4,
                          // ),
                          if (_syntaxError.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _syntaxError,
                                style: TextStyle(color: errorColor),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Apply Raw Filter Button
                    Center(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onPressed: () => _applyFilter(_rawFilterController.text),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.chevron_left_slash_chevron_right),
                            SizedBox(width: 4),
                            Text('Apply Raw Filter'),
                          ],
                        ),
                      ),
                    ),
                    // Help Section
                    _buildHelpSection(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Updated _buildTagChip to remove isDarkMode parameter and use context for theme
  Widget _buildTagChip(String tag) {
    final theme = CupertinoTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemFill.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: theme.textTheme.textStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(width: 4),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () => _removeTag(tag),
            child: Icon(
              CupertinoIcons.clear_circled_solid,
              size: 16,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimeRangePicker(BuildContext context) {
    final Map<String, String> timeRanges = {
      'today': 'Today',
      'this_week': 'This Week',
      'this_month': 'This Month',
    };
    final initialIndex = timeRanges.keys.toList().indexOf(_selectedTimeRange);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        String tempSelection = _selectedTimeRange;
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                color: CupertinoColors.secondarySystemBackground.resolveFrom(
                  context,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text(
                        'Done',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        setState(() => _selectedTimeRange = tempSelection);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  scrollController: FixedExtentScrollController(initialItem: initialIndex),
                  onSelectedItemChanged: (int index) {
                    tempSelection = timeRanges.keys.elementAt(index);
                  },
                  children: timeRanges.values.map((String value) {
                    return Center(child: Text(value));
                      }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Updated _buildPresetChip for better Cupertino styling
  Widget _buildPresetChip(String key, String label) {
    final isSelected = _selectedPreset == key;
    final theme = CupertinoTheme.of(context);
    final Color backgroundColor = isSelected
        ? theme.primaryColor
        : CupertinoColors.secondarySystemFill.resolveFrom(context);
    final Color textColor = isSelected
        ? CupertinoColors.white // Or theme.primaryContrastingColor if defined
        : CupertinoColors.label.resolveFrom(context);

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minSize: 0,
      borderRadius: BorderRadius.circular(16),
      color: backgroundColor,
      onPressed: () {
        if (!isSelected) {
          _applyPreset(key);
        }
      },
      child: Text(
        label,
        style: theme.textTheme.textStyle.copyWith(
          fontSize: 14,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildCodeExample(String code) {
    // Use CupertinoTheme to determine dark mode
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark; // Keep for logic below
    final Color codeBackgroundColor = isDarkMode
        ? CupertinoColors.darkBackgroundGray
        : CupertinoColors.extraLightBackgroundGray;
    // Use Cupertino dynamic colors for text if possible, or define specific ones
    final Color codeTextColor = isDarkMode
        ? CupertinoColors.systemGreen.color
        : CupertinoColors.systemGreen.darkColor;


    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          _rawFilterController.text = code;
          _applyFilter(code);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: codeBackgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            code,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: codeTextColor,
            ),
          ),
        ),
      ),
    );
  }

  bool _showHelp = false;

  // Updated _buildHelpSection to remove isDarkMode parameter
  Widget _buildHelpSection(BuildContext context) {
    // final theme = CupertinoTheme.of(context); // Unused
    return Container(
      margin: const EdgeInsets.only(top: 16.0, bottom: 16.0),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          CupertinoListTile(
            title: const Text('Filter Syntax Help'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: () => setState(() => _showHelp = !_showHelp),
              child: Icon(
                _showHelp ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                size: 20,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            onTap: () => setState(() => _showHelp = !_showHelp),
          ),
          if (_showHelp)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
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
                  _buildCodeExample(
                    'tag in ["work"] && visibility == "PUBLIC"',
                  ),
                  _buildCodeExample(
                    'content.contains("urgent") || content.contains("important")',
                  ),
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
    );
  }
}

// TODO: Refactor SyntaxHighlightTextField to fully use Cupertino styles and avoid Material dependencies.
// This is a placeholder refactor, focusing on replacing the TextField.
// Proper syntax highlighting color mapping to Cupertino dynamic colors is needed.
class SyntaxHighlightTextField extends StatefulWidget {
  final TextEditingController controller;
  // final InputDecoration decoration; // Removed Material InputDecoration
  final Function(String)? onChanged;
  final int? maxLines;
  final TextStyle? style; // Keep style for font family etc.
  final String? placeholder; // Add placeholder

  const SyntaxHighlightTextField({
    super.key,
    required this.controller,
    // this.decoration = const InputDecoration(),
    this.onChanged,
    this.maxLines,
    this.style,
    this.placeholder,
  });

  @override
  State<SyntaxHighlightTextField> createState() =>
      _SyntaxHighlightTextFieldState();
}

class _SyntaxHighlightTextFieldState extends State<SyntaxHighlightTextField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    // Trigger rebuild to update RichText, but avoid calling setState if not needed
    // setState(() {}); // This might be too aggressive, consider alternatives if performance issues arise
  }

  // Placeholder: Needs proper mapping to Cupertino dynamic colors
  List<TextSpan> _buildHighlightedSpans(String text, BuildContext context) {
     final theme = CupertinoTheme.of(context);
    // No need for isDarkMode as colors automatically adapt with resolveFrom(context)
     
     // Define colors based on Cupertino theme (example mapping)
     final Color operatorColor = CupertinoColors.systemOrange.resolveFrom(context);
     final Color keywordColor = CupertinoColors.systemBlue.resolveFrom(context);
     final Color stringColor = CupertinoColors.systemGreen.resolveFrom(context);
     final Color normalColor = CupertinoColors.label.resolveFrom(context);
     final Color functionColor = CupertinoColors.systemPurple.resolveFrom(context);
     final Color commentColor = CupertinoColors.secondaryLabel.resolveFrom(context); // Example for comments

    // Regex remains the same
    final operatorRegex = RegExp(r'&&|\|\||!|==|!=|<=|>=|<|>|\bin\b'); // Added word boundary for 'in'
    final keywordRegex = RegExp(
      r'\b(tag|visibility|create_time|update_time|state|content|true|false|null)\b',
    );
    // Define string patterns separately for better readability
    final doubleQuoteStringRegex = RegExp(
      r'"(?:[^"\\]|\\.)*"',
    ); // Double-quoted strings
    final singleQuoteStringRegex = RegExp(
      r"'(?:[^'\\]|\\.)*'",
    ); // Single-quoted strings

    // Function call pattern with explicit lookahead
    final functionRegex = RegExp(
      r'\b(contains|size|startsWith|endsWith)\b(?=\()',
    );

    // Simple comment pattern
    final commentRegex = RegExp(r'//.*');

    // Combine string patterns when processing
    List<TextSpan> spans = [];
    int currentPosition = 0;

    void addSpan(int start, int end, Color color) {
      if (start < end) {
        // Ensure a base style exists, even if theme.textTheme.textStyle is null
        final baseStyle =
            widget.style ?? theme.textTheme.textStyle;
        spans.add(
          TextSpan(
            text: text.substring(start, end),
            // Use base style and override color
            style: baseStyle.copyWith(color: color),
          ),
        );
      }
    }

    // Combine all regex matches and sort by start position
    List<_HighlightMatch> matches = [];
    operatorRegex
        .allMatches(text)
        .forEach((m) => matches.add(_HighlightMatch(m, operatorColor)));
    keywordRegex
        .allMatches(text)
        .forEach((m) => matches.add(_HighlightMatch(m, keywordColor)));
    doubleQuoteStringRegex
        .allMatches(text)
        .forEach((m) => matches.add(_HighlightMatch(m, stringColor)));
    singleQuoteStringRegex
        .allMatches(text)
        .forEach((m) => matches.add(_HighlightMatch(m, stringColor)));
    functionRegex
        .allMatches(text)
        .forEach((m) => matches.add(_HighlightMatch(m, functionColor)));
    commentRegex
        .allMatches(text)
        .forEach((m) => matches.add(_HighlightMatch(m, commentColor)));

    matches.sort((a, b) => a.match.start.compareTo(b.match.start));

    // Process matches and add spans
    for (var highlight in matches) {
      // Add normal text before the current match
      if (highlight.match.start > currentPosition) {
        addSpan(currentPosition, highlight.match.start, normalColor);
      }
      // Add the highlighted match itself
      addSpan(highlight.match.start, highlight.match.end, highlight.color);
      currentPosition = highlight.match.end;
    }

    // Add any remaining normal text after the last match
    if (currentPosition < text.length) {
      addSpan(currentPosition, text.length, normalColor);
    }

    // If no spans were added (empty text), add an empty span to avoid errors
    if (spans.isEmpty && text.isEmpty) {
       // Ensure a base style exists
      final baseStyle = widget.style ?? theme.textTheme.textStyle;
       spans.add(TextSpan(text: '', style: baseStyle));
    }


    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final defaultTextStyle = widget.style ?? theme.textTheme.textStyle.copyWith(
      fontFamily: 'monospace',
      fontSize: 14,
    );

    // Build highlighted spans based on current text
    final spans = _buildHighlightedSpans(widget.controller.text, context);

    return Stack(
      children: [
        // Background RichText for syntax highlighting
        // Use Padding to align with CupertinoTextField's internal padding
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0), // Approximate default padding
          child: RichText(
            text: TextSpan(
              children: spans,
              style: defaultTextStyle, // Base style for the TextSpan
            ),
            maxLines: widget.maxLines,
            overflow: TextOverflow.clip, // Or handle overflow as needed
          ),
        ),
        // Transparent CupertinoTextField for input
        CupertinoTextField(
          controller: widget.controller,
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0), // Match RichText padding
          placeholder: widget.placeholder,
          maxLines: widget.maxLines,
          onChanged: widget.onChanged,
          // Make the text transparent to see the RichText underneath
          style: defaultTextStyle.copyWith(color: CupertinoColors.transparent),
          // Remove default CupertinoTextField border/background
          decoration: const BoxDecoration(
            color: CupertinoColors.transparent,
          ),
          // Ensure keyboard type allows multiple lines if needed
          keyboardType: widget.maxLines != 1 ? TextInputType.multiline : TextInputType.text,
        ),
      ],
    );
  }
}

// Helper class for sorting matches
class _HighlightMatch {
  final RegExpMatch match;
  final Color color;
  _HighlightMatch(this.match, this.color);
}

// Removed unused _Token class

extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

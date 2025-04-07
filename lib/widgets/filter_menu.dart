import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';

class FilterItem {
  final String label;
  final String key;
  final IconData? icon; // Optional icon

  FilterItem({required this.label, required this.key, this.icon});
}

class FilterMenu extends StatelessWidget {
  final String currentFilterKey;
  final List<FilterItem> filters;
  final Function(FilterItem) onFilterSelected;

  const FilterMenu({
    super.key,
    required this.currentFilterKey,
    required this.filters,
    required this.onFilterSelected,
  });

  void _showFilterActionSheet(BuildContext context) {
    showCupertinoModalPopup<String>(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: const Text('Select Filter'),
            actions:
                filters.map((filter) {
                  final bool isSelected = filter.key == currentFilterKey;
                  return CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        filter.key,
                      ); // Return the selected key
                    },
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Center content
                      children: [
                        if (filter.icon != null) ...[
                          Icon(
                            filter.icon,
                            size: 20,
                            color:
                                isSelected
                                    ? CupertinoTheme.of(context).primaryColor
                                    : CupertinoColors.label.resolveFrom(
                                      context,
                                    ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          filter.label,
                          style: TextStyle(
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                isSelected
                                    ? CupertinoTheme.of(context).primaryColor
                                    : CupertinoColors.label.resolveFrom(
                                      context,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context); // Just close without selection
              },
              child: const Text('Cancel'),
            ),
          ),
    ).then((selectedValue) {
      if (selectedValue != null) {
        final selectedFilter = filters.firstWhere(
          (filter) => filter.key == selectedValue,
          orElse: () {
            // Fallback to the first filter if something goes wrong
            if (kDebugMode) {
              print(
                '[FilterMenu] Error: Could not find selected filter key "$selectedValue", falling back.',
              );
            }
            return filters.first;
          },
        );
        onFilterSelected(selectedFilter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Find currently selected filter
    final selectedFilter = filters.firstWhere(
      (filter) => filter.key == currentFilterKey,
      orElse: () {
        // Fallback to the first filter if current key not found
        if (kDebugMode) {
          print(
            '[FilterMenu] Warning: Current filter key "$currentFilterKey" not found in filters list, falling back.',
          );
        }
        return filters.isNotEmpty
            ? filters.first
            : FilterItem(label: 'Error', key: 'error');
      },
    );

    // Use CupertinoButton to trigger the action sheet
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      onPressed: () => _showFilterActionSheet(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedFilter.icon != null) ...[
            Icon(
              selectedFilter.icon,
              size: 18, // Slightly smaller icon in the button
              color: CupertinoTheme.of(context).primaryColor,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            selectedFilter.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600, // Make it slightly bolder
              color: CupertinoTheme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            CupertinoIcons.chevron_down, // Use Cupertino chevron
            size: 16,
            color: CupertinoTheme.of(context).primaryColor.withOpacity(0.8),
          ),
        ],
      ),
    );
  }
}
